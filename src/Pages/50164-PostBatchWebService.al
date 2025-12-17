page 50164 "GJW Post Batch Web Service"
{
    PageType = List;
    SourceTable = "Item Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId) { }
                field(journalTemplateName; Rec."Journal Template Name") { }
                field(name; Rec.Name) { }
            }
        }
    }

    // Procedimiento que Power Automate puede llamar
    procedure PostBatchByName(TemplateName: Code[10]; BatchName: Code[20]): Text
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        LineCount: Integer;
    begin
        // Obtener líneas del batch
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if not ItemJnlLine.FindSet() then
            Error('No se encontraron líneas en el batch: %1', BatchName);

        LineCount := ItemJnlLine.Count();

        // ✅ REGISTRAR (igual que botón BC)
        ItemJnlPostBatch.Run(ItemJnlLine);

        exit(StrSubstNo('SUCCESS: %1 líneas registradas', LineCount));
    end;
}
