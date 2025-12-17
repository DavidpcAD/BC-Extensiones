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
                field(batchName; Rec."Batch Name") { }
                field(templateName; Rec."Template Name") { }
                field(linesPosted; Rec."Lines Posted") { Editable = false; }
                field(successMessage; Rec."Success Message") { Editable = false; }
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
        if Rec."Batch Name" = '' then
            Error('Batch Name es requerido');

        if Rec."Template Name" = '' then
            Rec."Template Name" := 'TRANSFEREN'; // Default

        // Obtener líneas del batch
        ItemJnlLine.SetRange("Journal Template Name", Rec."Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", Rec."Batch Name");

        if not ItemJnlLine.FindSet() then
            Error('No se encontraron líneas en el batch: %1', Rec."Batch Name");

        LineCount := ItemJnlLine.Count();

        // ✅ EJECUTAR POSTING (igual que botón Registrar de BC)
        ItemJnlPostBatch.Run(ItemJnlLine);

        // Establecer resultado
        Rec."Lines Posted" := LineCount;
        Rec."Success Message" := StrSubstNo('✅ %1 líneas registradas en Almacén de Obra', LineCount);

        exit(true);
    end;
}
