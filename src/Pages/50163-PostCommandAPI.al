page 50163 "GJW Post Command API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'postCommand';
    EntitySetName = 'postCommands';

    SourceTable = "GJW Post Command";
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
                field(commandId; Rec."Command ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(commandData; Rec."Command Data")
                {
                    ApplicationArea = All;
                }
                field(linesPosted; Rec."Lines Posted")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(successMessage; Rec."Success Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(postingStatus; Rec."Posting Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(errorDetails; Rec."Error Details")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(processingStarted; Rec."Processing Started")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(processingCompleted; Rec."Processing Completed")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(durationMs; Rec."Duration (ms)")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        LineCount: Integer;
        BatchName: Code[20];
        TemplateName: Code[10];
        ErrorText: Text;
        StartTime: DateTime;
        EndTime: DateTime;
    begin
        // 📊 Iniciar medición de tiempo
        StartTime := CurrentDateTime();
        Rec."Processing Started" := StartTime;
        Rec."Posting Status" := Rec."Posting Status"::Processing;

        // Validar que se recibió un batch name
        if Rec."Command Data" = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: El nombre del batch es requerido. Command Data está vacío.';
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := 'Command Data vacío';
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := CurrentDateTime() - StartTime;
            exit(true);
        end;

        // El Command Data contiene el BatchName directamente
        BatchName := CopyStr(Rec."Command Data", 1, 20);
        TemplateName := 'TRANSFEREN';

        // Obtener líneas del batch
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if not ItemJnlLine.FindSet() then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR: No se encontraron líneas en Template: %1, Batch: %2', TemplateName, BatchName);
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := StrSubstNo('Batch no encontrado: %1/%2', TemplateName, BatchName);
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := CurrentDateTime() - StartTime;
            exit(true);
        end;

        // Contar líneas ANTES del posting
        LineCount := ItemJnlLine.Count();

        // 🛡️ VALIDAR QUE TODAS LAS LÍNEAS TIENEN CANTIDAD
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);
        if ItemJnlLine.FindSet() then
            repeat
                if ItemJnlLine.Quantity = 0 then begin
                    Rec."Lines Posted" := 0;
                    Rec."Success Message" := StrSubstNo('ERROR: La línea %1 no tiene cantidad. Ítem: %2', ItemJnlLine."Line No.", ItemJnlLine."Item No.");
                    Rec."Posting Status" := Rec."Posting Status"::Failed;
                    Rec."Error Details" := StrSubstNo('Línea %1 sin cantidad (Ítem %2)', ItemJnlLine."Line No.", ItemJnlLine."Item No.");
                    Rec."Processing Completed" := CurrentDateTime();
                    Rec."Duration (ms)" := CurrentDateTime() - StartTime;
                    exit(true);
                end;
                if ItemJnlLine."Item No." = '' then begin
                    Rec."Lines Posted" := 0;
                    Rec."Success Message" := StrSubstNo('ERROR: La línea %1 no tiene número de ítem', ItemJnlLine."Line No.");
                    Rec."Posting Status" := Rec."Posting Status"::Failed;
                    Rec."Error Details" := StrSubstNo('Línea %1 sin Item No.', ItemJnlLine."Line No.");
                    Rec."Processing Completed" := CurrentDateTime();
                    Rec."Duration (ms)" := CurrentDateTime() - StartTime;
                    exit(true);
                end;
            until ItemJnlLine.Next() = 0;

        // 🛡️ VALIDACIÓN DE LÍMITE (evitar timeouts)
        if LineCount > 200 then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR: Demasiadas líneas (%1). Máximo permitido: 200. Divida en batches más pequeños.', LineCount);
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := StrSubstNo('Límite excedido: %1 líneas (máx 200)', LineCount);
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := CurrentDateTime() - StartTime;
            exit(true);
        end;

        // ✅ EJECUTAR POSTING CON MANEJO DE ERRORES
        Clear(ItemJnlPostBatch);

        // Resetear el recordset antes de postear
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if not ItemJnlLine.FindFirst() then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: No se pudieron cargar las líneas para registrar';
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := 'FindFirst falló antes del posting';
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := CurrentDateTime() - StartTime;
            exit(true);
        end;

        // Usar Codeunit.Run para mejor manejo en API
        if not Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJnlLine) then begin
            // Capturar error del posting
            ErrorText := GetLastErrorText();
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR AL REGISTRAR: %1', ErrorText);
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := CopyStr(ErrorText, 1, 2048);
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := CurrentDateTime() - StartTime;
            ClearLastError();
            exit(true);
        end;

        // Verificar que el posting fue exitoso
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if ItemJnlLine.FindFirst() then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR: El posting falló. Quedan %1 líneas sin procesar.', ItemJnlLine.Count());
            Rec."Posting Status" := Rec."Posting Status"::PartialSuccess;
            Rec."Error Details" := StrSubstNo('Quedan %1 líneas sin registrar de %2 totales', ItemJnlLine.Count(), LineCount);
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := CurrentDateTime() - StartTime;
            exit(true);
        end;

        // ✅ Establecer resultado exitoso
        EndTime := CurrentDateTime();
        Rec."Lines Posted" := LineCount;
        Rec."Success Message" := StrSubstNo('✅ %1 líneas registradas exitosamente en Almacén de Obra', LineCount);
        Rec."Posting Status" := Rec."Posting Status"::Success;
        Rec."Error Details" := '';
        Rec."Processing Completed" := EndTime;
        Rec."Duration (ms)" := EndTime - StartTime;

        exit(true);
    end;
}
