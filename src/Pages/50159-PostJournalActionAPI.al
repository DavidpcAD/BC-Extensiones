page 50159 "GJW Post Journal Action API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'postJournalCommand';
    EntitySetName = 'postJournalCommands';

    SourceTable = "GJW Post Journal Command";
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
                field(entryNo; Rec."Entry No.") { Caption = 'Entry No.'; }
                field(templateName; Rec."Template Name") { Caption = 'Template Name'; }
                field(batchName; Rec."Batch Name") { Caption = 'Batch Name'; }
                field(resultMessage; Rec."Result Message") { Caption = 'Result Message'; Editable = false; }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        LineCount: Integer;
    begin
        // Validar datos
        if (Rec."Template Name" = '') or (Rec."Batch Name" = '') then
            Error('Template Name y Batch Name son requeridos');

        // Filtrar líneas del batch
        ItemJnlLine.SetRange("Journal Template Name", Rec."Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", Rec."Batch Name");

        if not ItemJnlLine.FindSet() then
            Error('No se encontraron líneas en el batch: %1/%2', Rec."Template Name", Rec."Batch Name");

        LineCount := ItemJnlLine.Count;

        // Registrar todas las líneas del batch
        ItemJnlPostBatch.Run(ItemJnlLine);

        // Establecer mensaje de resultado
        Rec."Result Message" := StrSubstNo('✅ Registrado: %1 (%2 líneas)', Rec."Batch Name", LineCount);

        exit(true);
    end;
}
