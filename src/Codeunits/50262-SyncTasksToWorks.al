// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50262 "GJW Sync Tasks To Works"
// Propósito: Rellenar la Obra (GomJob Works Line) con las Job Task de tipo Registro
//            (Posting) que existen en el proyecto pero no tienen línea en la Obra.
//            Las nuevas líneas copian el Version Code y el Line Type de una línea ya
//            existente, con Task Type = Posting, Cantidad = 1 y UM = 'UND'.
//
// Lo usan dos consumidores con el MISMO comportamiento:
//   - Page 50205 "GJW Sync Tasks API"  (syncTasksToWorks, desde Power Apps).
//   - El botón "Sincronizar tareas" de la ficha de la Obra (GomJob Works).
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50262 "GJW Sync Tasks To Works"
{
    Access = Public;

    /// <summary>
    /// Crea en la Obra las Job Task de tipo Registro que aún no tienen línea.
    /// </summary>
    /// <param name="WorksNo">Obra / proyecto a sincronizar.</param>
    /// <param name="JobTaskNoFilter">Si viene, solo esa tarea; si está vacío, todas las de Registro.</param>
    /// <returns>true si se pudo procesar; false si falta el Works No. (ErrorMessage explica).</returns>
    procedure SyncTasks(WorksNo: Code[20]; JobTaskNoFilter: Code[20]; var TasksCreated: Integer; var TasksSkipped: Integer; var ResultMessage: Text; var ErrorMessage: Text): Boolean
    var
        JobTask: Record "Job Task";
        GomJobWorksLine: Record "GomJob Works Line";
        RefLine: Record "GomJob Works Line";
        LineTypeEnum: Enum "GomJob Works Line Type";
        VersionCode: Code[20];
        LastLineNo: Integer;
    begin
        TasksCreated := 0;
        TasksSkipped := 0;
        ResultMessage := '';
        ErrorMessage := '';

        if WorksNo = '' then begin
            ErrorMessage := 'Works No. es requerido.';
            exit(false);
        end;

        // Tomar lineType y versionCode de una línea existente con taskNo válido
        // para que la nueva línea tenga el mismo formato que las demás.
        RefLine.SetRange("Works No.", WorksNo);
        RefLine.SetFilter("Task No.", '<>%1', '');
        if RefLine.FindFirst() then begin
            VersionCode := RefLine."Version Code";
            LineTypeEnum := RefLine."Line Type";
        end else begin
            VersionCode := '';
            LineTypeEnum := LineTypeEnum::Null;
        end;

        // Último Line No. para esta combinación works + version
        GomJobWorksLine.SetRange("Works No.", WorksNo);
        GomJobWorksLine.SetRange("Version Code", VersionCode);
        if GomJobWorksLine.FindLast() then
            LastLineNo := GomJobWorksLine."Line No."
        else
            LastLineNo := 0;

        // Filtrar tareas: si viene jobTaskNo específico, solo esa; si no, todas las de tipo Registro
        JobTask.SetRange("Job No.", WorksNo);
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if JobTaskNoFilter <> '' then
            JobTask.SetRange("Job Task No.", JobTaskNoFilter);

        if not JobTask.FindSet() then begin
            ResultMessage := 'No se encontraron tareas de registro para sincronizar.';
            exit(true);
        end;

        repeat
            // Verificar si ya existe en GomJob Works Lines
            GomJobWorksLine.Reset();
            GomJobWorksLine.SetRange("Works No.", WorksNo);
            GomJobWorksLine.SetRange("Version Code", VersionCode);
            GomJobWorksLine.SetRange("Task No.", JobTask."Job Task No.");

            if GomJobWorksLine.FindFirst() then begin
                TasksSkipped += 1;
            end else begin
                LastLineNo += 10000;
                Clear(GomJobWorksLine);
                GomJobWorksLine.Init();
                GomJobWorksLine."Works No." := WorksNo;
                GomJobWorksLine."Version Code" := VersionCode;
                GomJobWorksLine."Line No." := LastLineNo;
                GomJobWorksLine."Line Type" := LineTypeEnum;
                GomJobWorksLine."Task Type" := GomJobWorksLine."Task Type"::Posting;
                GomJobWorksLine."Job No." := JobTask."Job No.";
                GomJobWorksLine."Task No." := JobTask."Job Task No.";
                GomJobWorksLine.Description := JobTask.Description;
                GomJobWorksLine.Quantity := 1;
                GomJobWorksLine."Unit of Measure" := 'UND';

                if GomJobWorksLine.Insert(true) then begin
                    Commit();
                    TasksCreated += 1;
                end;
            end;
        until JobTask.Next() = 0;

        ResultMessage := StrSubstNo(
            '%1 tarea(s) creada(s) en GomJob. %2 ya existían.',
            TasksCreated, TasksSkipped);
        exit(true);
    end;
}
