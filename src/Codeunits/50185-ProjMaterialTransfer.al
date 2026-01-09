codeunit 50185 "GJW Proj Material Transfer"
{
    procedure CreateTransferFromNegativeAdjustments(ProjectNo: Code[20]; LocationCode: Code[10]; DestinationType: Option Project,GeneralWarehouse; DestinationProjectNo: Code[20]; DestinationTaskNo: Code[20]; DestinationLocationCode: Code[10]): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        LineNo: Integer;
        TransferCount: Integer;
    begin
        // Buscar movimientos negativos del proyecto y ubicación especificados
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Global Dimension 1 Code", ProjectNo);
        if LocationCode <> '' then
            ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetFilter("Remaining Quantity", '<0'); // Solo con stock negativo pendiente

        if not ItemLedgerEntry.FindSet() then
            Error('No se encontraron ajustes negativos para el proyecto %1 y ubicación %2', ProjectNo, LocationCode);

        // Obtener siguiente número de línea
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'TRANSFEREN');
        ItemJnlLine.SetRange("Journal Batch Name", 'GENERICO');
        if ItemJnlLine.FindLast() then
            LineNo := ItemJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        TransferCount := 0;

        // Crear líneas de diario de reclasificación
        repeat
            ItemJnlLine.Init();
            ItemJnlLine."Journal Template Name" := 'TRANSFEREN';
            ItemJnlLine."Journal Batch Name" := 'GENERICO';
            ItemJnlLine."Line No." := LineNo;
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
            ItemJnlLine."Posting Date" := WorkDate();
            ItemJnlLine."Document No." := 'TRANS-' + Format(Today, 0, '<Year4><Month,2><Day,2>');

            // Datos del item
            ItemJnlLine."Item No." := ItemLedgerEntry."Item No.";
            ItemJnlLine.Description := ItemLedgerEntry.Description;
            ItemJnlLine."Variant Code" := ItemLedgerEntry."Variant Code";
            ItemJnlLine.Quantity := Abs(ItemLedgerEntry."Remaining Quantity");
            ItemJnlLine."Unit of Measure Code" := ItemLedgerEntry."Unit of Measure Code";

            // Origen
            ItemJnlLine."Location Code" := ItemLedgerEntry."Location Code";
            ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
            ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";
            ItemJnlLine."Applies-from Entry" := ItemLedgerEntry."Entry No.";

            // Destino
            ItemJnlLine."New Location Code" := DestinationLocationCode;

            if DestinationType = DestinationType::Project then begin
                ItemJnlLine."New Shortcut Dimension 1 Code" := DestinationProjectNo;
                ItemJnlLine."New Shortcut Dimension 2 Code" := DestinationTaskNo;
            end else begin
                // Para almacén general, limpiar dimensiones
                ItemJnlLine."New Shortcut Dimension 1 Code" := '';
                ItemJnlLine."New Shortcut Dimension 2 Code" := '';
            end;

            // Costo
            if ItemLedgerEntry."GomJob Cost per Unit" <> 0 then
                ItemJnlLine."Unit Amount" := ItemLedgerEntry."GomJob Cost per Unit";

            ItemJnlLine.Insert(true);

            LineNo += 10000;
            TransferCount += 1;

        until ItemLedgerEntry.Next() = 0;

        exit(StrSubstNo('Se crearon %1 líneas de transferencia en el diario TRANSFEREN-GENERICO', TransferCount));
    end;

    procedure GetNegativeAdjustmentsByProject(ProjectNo: Code[20]; LocationCode: Code[10]) Result: Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        JSONArray: Text;
        ItemInfo: Text;
        Count: Integer;
    begin
        JSONArray := '[';
        Count := 0;

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Global Dimension 1 Code", ProjectNo);
        if LocationCode <> '' then
            ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetFilter("Remaining Quantity", '<0');

        if ItemLedgerEntry.FindSet() then begin
            repeat
                if Count > 0 then
                    JSONArray += ',';

                ItemInfo := '{';
                ItemInfo += '"entryNo":' + Format(ItemLedgerEntry."Entry No.") + ',';
                ItemInfo += '"itemNo":"' + ItemLedgerEntry."Item No." + '",';
                ItemInfo += '"description":"' + ItemLedgerEntry.Description + '",';
                ItemInfo += '"variantCode":"' + ItemLedgerEntry."Variant Code" + '",';
                ItemInfo += '"locationCode":"' + ItemLedgerEntry."Location Code" + '",';
                ItemInfo += '"projectNo":"' + ItemLedgerEntry."Global Dimension 1 Code" + '",';
                ItemInfo += '"taskNo":"' + ItemLedgerEntry."Global Dimension 2 Code" + '",';
                ItemInfo += '"remainingQty":' + Format(ItemLedgerEntry."Remaining Quantity") + ',';
                ItemInfo += '"postingDate":"' + Format(ItemLedgerEntry."Posting Date", 0, 9) + '"';
                ItemInfo += '}';

                JSONArray += ItemInfo;
                Count += 1;

            until ItemLedgerEntry.Next() = 0;
        end;

        JSONArray += ']';
        Result := JSONArray;
    end;
}
