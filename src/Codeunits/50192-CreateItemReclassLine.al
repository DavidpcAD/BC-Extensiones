codeunit 50192 "GJW Create Item Reclass Line"
{
    procedure CreateLine(ItemNo: Code[20]; Qty: Decimal; FromLocation: Code[10]; ToLocation: Code[10]): Boolean
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        JobTask: Record "Job Task";
        LineNo: Integer;
        JobNo: Code[20];
        TaskNo: Code[20];
    begin
        // Validar que existan Template y Batch
        if not ItemJnlTemplate.Get('TRANSFEREN') then
            Error('Template TRANSFEREN no existe');

        if not ItemJnlBatch.Get('TRANSFEREN', 'GENERICO') then
            Error('Batch GENERICO no existe en template TRANSFEREN');

        // Buscar Job Task por Location Code para obtener Job No. y Task No.
        JobTask.SetRange("Location Code", FromLocation);
        if not JobTask.FindFirst() then
            Error('No se encontró Job Task con Location Code: %1', FromLocation);

        JobNo := JobTask."Job No.";
        TaskNo := JobTask."Job Task No.";

        // Obtener siguiente Line No.
        ItemJnlLine.SetRange("Journal Template Name", 'TRANSFEREN');
        ItemJnlLine.SetRange("Journal Batch Name", 'GENERICO');
        if ItemJnlLine.FindLast() then
            LineNo := ItemJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        // Crear nueva línea SIN validaciones
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'TRANSFEREN';
        ItemJnlLine."Journal Batch Name" := 'GENERICO';
        ItemJnlLine."Line No." := LineNo;
        ItemJnlLine."Posting Date" := WorkDate();
        ItemJnlLine."Document No." := 'TRANSFER-' + Format(WorkDate(), 0, '<Year4><Month,2><Day,2>');
        ItemJnlLine."Item No." := ItemNo;
        ItemJnlLine.Description := 'Transfer - ' + ItemNo;
        ItemJnlLine.Quantity := Qty;
        ItemJnlLine."Location Code" := FromLocation;
        ItemJnlLine."New Location Code" := ToLocation;

        // CRÍTICO: Asignar dimensiones origen y mantenerlas en destino para devoluciones
        ItemJnlLine."Shortcut Dimension 1 Code" := JobNo;
        ItemJnlLine."New Shortcut Dimension 1 Code" := JobNo;  // Mantener misma dimensión
        ItemJnlLine."Task No." := TaskNo;

        // CRÍTICO: Forzar Entry Type a Transfer DESPUÉS de todo (sin Validate)
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;

        ItemJnlLine.Insert(false); // Sin validaciones

        exit(true);
    end;
}
