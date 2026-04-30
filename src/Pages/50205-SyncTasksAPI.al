page 50205 "GJW Sync Tasks API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'syncTaskToWorks';
    EntitySetName = 'syncTasksToWorks';

    SourceTable = "GJW Sync Tasks Buffer";
    SourceTableTemporary = true;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(worksNo; Rec."Works No.")
                {
                    Caption = 'Works No.';
                    ApplicationArea = All;
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                    ApplicationArea = All;
                }
                field(tasksCreated; Rec."Tasks Created")
                {
                    Caption = 'Tasks Created';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(tasksSkipped; Rec."Tasks Skipped")
                {
                    Caption = 'Tasks Skipped';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(resultMessage; Rec."Result Message")
                {
                    Caption = 'Result Message';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'Error Message';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        JobTask: Record "Job Task";
        GomJobWorksLine: Record "GomJob Works Line";
        RefLine: Record "GomJob Works Line";
        LineTypeEnum: Enum "GomJob Works Line Type";
        VersionCode: Code[20];
        LastLineNo: Integer;
        TasksCreated: Integer;
        TasksSkipped: Integer;
    begin
        if Rec."Works No." = '' then begin
            Rec."Error Message" := 'Works No. es requerido.';
            exit(true);
        end;

        // Obtener lineType y versionCode de una línea existente con taskNo válido
        // para que la nueva línea tenga el mismo formato que las demás casas
        RefLine.SetRange("Works No.", Rec."Works No.");
        RefLine.SetFilter("Task No.", '<>%1', '');
        if RefLine.FindFirst() then begin
            VersionCode := RefLine."Version Code";
            LineTypeEnum := RefLine."Line Type";
        end else begin
            VersionCode := '';
            LineTypeEnum := LineTypeEnum::Null;
        end;

        // Último Line No. para esta combinación works + version
        GomJobWorksLine.SetRange("Works No.", Rec."Works No.");
        GomJobWorksLine.SetRange("Version Code", VersionCode);
        if GomJobWorksLine.FindLast() then
            LastLineNo := GomJobWorksLine."Line No."
        else
            LastLineNo := 0;

        // Filtrar tareas: si viene jobTaskNo específico, solo esa; si no, todas las de tipo Posting
        JobTask.SetRange("Job No.", Rec."Works No.");
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if Rec."Job Task No." <> '' then
            JobTask.SetRange("Job Task No.", Rec."Job Task No.");

        if not JobTask.FindSet() then begin
            Rec."Result Message" := 'No se encontraron tareas de registro para sincronizar.';
            exit(true);
        end;

        TasksCreated := 0;
        TasksSkipped := 0;

        repeat
            // Verificar si ya existe en GomJob Works Lines
            GomJobWorksLine.Reset();
            GomJobWorksLine.SetRange("Works No.", Rec."Works No.");
            GomJobWorksLine.SetRange("Version Code", VersionCode);
            GomJobWorksLine.SetRange("Task No.", JobTask."Job Task No.");

            if GomJobWorksLine.FindFirst() then begin
                TasksSkipped += 1;
            end else begin
                LastLineNo += 10000;
                Clear(GomJobWorksLine);
                GomJobWorksLine.Init();
                GomJobWorksLine."Works No." := Rec."Works No.";
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

        Rec."Tasks Created" := TasksCreated;
        Rec."Tasks Skipped" := TasksSkipped;
        Rec."Result Message" := StrSubstNo(
            '%1 tarea(s) creada(s) en GomJob. %2 ya existían.',
            TasksCreated, TasksSkipped);
        exit(true);
    end;
}
