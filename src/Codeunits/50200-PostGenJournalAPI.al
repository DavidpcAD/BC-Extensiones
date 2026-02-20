codeunit 50200 "GJW Post Gen. Journal API"
{
    procedure PostBatch(templateName: Code[10]; batchName: Code[20]): Text
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        LineCount: Integer;
    begin
        GenJnlLine.SetRange("Journal Template Name", templateName);
        GenJnlLine.SetRange("Journal Batch Name", batchName);

        if not GenJnlLine.FindSet() then
            Error('No se encontraron lineas en %1 / %2', templateName, batchName);

        LineCount := GenJnlLine.Count;
        GenJnlPostBatch.Run(GenJnlLine);

        exit(StrSubstNo('OK: %1 lineas registradas en %2/%3', LineCount, templateName, batchName));
    end;

    [ServiceEnabled]
    procedure PostBatchUnbound(templateName: Code[10]; batchName: Code[20]): Text
    begin
        exit(PostBatch(templateName, batchName));
    end;
}
