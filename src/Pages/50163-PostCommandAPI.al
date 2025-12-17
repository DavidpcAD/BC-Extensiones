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
    begin
        // Validar que se recibió un batch name
        if Rec."Command Data" = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: El nombre del batch es requerido. Command Data está vacío.';
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
            exit(true);
        end;

        // Contar líneas ANTES del posting
        LineCount := ItemJnlLine.Count();

        // ✅ EJECUTAR POSTING (igual que botón Registrar de BC)
        // El ItemJnlPostBatch procesa y elimina las líneas del batch
        Commit(); // Asegurar que no hay transacciones pendientes
        ItemJnlPostBatch.Run(ItemJnlLine);

        // Verificar que el posting fue exitoso
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if ItemJnlLine.FindFirst() then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR: El posting falló. Quedan %1 líneas sin procesar.', ItemJnlLine.Count());
            exit(true);
        end;

        // Establecer resultado exitoso
        Rec."Lines Posted" := LineCount;
        Rec."Success Message" := StrSubstNo('✅ %1 líneas registradas exitosamente en Almacén de Obra', LineCount);

        exit(true);
    end;
}
