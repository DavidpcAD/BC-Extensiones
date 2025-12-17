codeunit 50158 "GJW Post Item Journal API"
{
    // Codeunit para registrar líneas específicas del diario desde Power Apps

    procedure PostSingleLine(SystemId: Guid): Text
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        if not ItemJnlLine.GetBySystemId(SystemId) then
            Error('No se encontró la línea con SystemId: %1', SystemId);

        // Validaciones previas
        ItemJnlLine.TestField("Item No.");
        ItemJnlLine.TestField(Quantity);
        ItemJnlLine.TestField("Posting Date");

        // Registrar la línea
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        exit(StrSubstNo('✅ Línea registrada: %1 - Cantidad: %2', ItemJnlLine."Item No.", ItemJnlLine.Quantity));
    end;

    procedure PostBatch(TemplateName: Code[10]; BatchName: Code[20]): Text
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        LineCount: Integer;
    begin
        // Filtrar líneas del batch
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if not ItemJnlLine.FindSet() then
            Error('No se encontraron líneas en el batch: %1/%2', TemplateName, BatchName);

        LineCount := ItemJnlLine.Count;

        // Registrar todas las líneas del batch
        ItemJnlPostBatch.Run(ItemJnlLine);

        exit(StrSubstNo('✅ Batch registrado: %1 - %2 líneas procesadas', BatchName, LineCount));
    end;

    procedure PostSelectedLines(var ItemJnlLineBuffer: Record "Item Journal Line" temporary): Text
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ProcessedCount: Integer;
    begin
        ProcessedCount := 0;

        if ItemJnlLineBuffer.FindSet() then
            repeat
                // Buscar línea real por SystemId
                if ItemJnlLine.GetBySystemId(ItemJnlLineBuffer.SystemId) then begin
                    ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                    ProcessedCount += 1;
                end;
            until ItemJnlLineBuffer.Next() = 0;

        exit(StrSubstNo('✅ Registradas %1 líneas seleccionadas', ProcessedCount));
    end;
}
