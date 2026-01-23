codeunit 50195 "GJW Material Disassembly"
{
    procedure DisassembleMaterial(ItemLedgerEntryNo: Integer; Quantity: Decimal): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        LineNo: Integer;
        ComponentCount: Integer;
        TotalComponentQty: Decimal;
    begin
        // Validaciones
        if ItemLedgerEntryNo = 0 then
            Error('Debe especificar un material para desensamblar');

        if Quantity <= 0 then
            Error('La cantidad debe ser mayor a cero');

        // Obtener el Item Ledger Entry
        if not ItemLedgerEntry.Get(ItemLedgerEntryNo) then
            Error('No se encontró el movimiento de almacén %1', ItemLedgerEntryNo);

        // Validar cantidad disponible
        if ItemLedgerEntry."Remaining Quantity" < Quantity then
            Error('Cantidad insuficiente. Disponible: %1, Solicitado: %2',
                ItemLedgerEntry."Remaining Quantity", Quantity);

        // Obtener el producto
        if not Item.Get(ItemLedgerEntry."Item No.") then
            Error('No se encontró el producto %1', ItemLedgerEntry."Item No.");

        // Verificar que tiene BOM
        BOMComponent.SetRange("Parent Item No.", Item."No.");
        if not BOMComponent.FindSet() then
            Error('El producto %1 no tiene lista de materiales (BOM) definida', Item."No.");

        // Obtener siguiente número de línea
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'PRODUCT');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if ItemJnlLine.FindLast() then
            LineNo := ItemJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        ComponentCount := 0;
        TotalComponentQty := 0;

        // 1. Crear línea de salida del material base (negativo)
        Clear(ItemJnlLine);
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'PRODUCT';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        ItemJnlLine."Line No." := LineNo;
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
        ItemJnlLine.Validate("Posting Date", Today);
        ItemJnlLine."Document No." := 'DESENS-' + Format(Today, 0, '<Year4><Month,2><Day,2>');
        ItemJnlLine.Validate("Item No.", Item."No.");
        ItemJnlLine.Description := 'Desensamblado - Material Base';
        ItemJnlLine.Validate(Quantity, Quantity);
        ItemJnlLine."Location Code" := ItemLedgerEntry."Location Code";
        ItemJnlLine."Variant Code" := ItemLedgerEntry."Variant Code";

        // Copiar dimensiones
        ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";

        if ItemJnlLine.Insert(true) then begin
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            LineNo += 10000;
        end else
            Error('Error al crear línea de salida del material base');

        // 2. Crear líneas de entrada para cada componente
        BOMComponent.SetRange("Parent Item No.", Item."No.");
        if BOMComponent.FindSet() then begin
            repeat
                Clear(ItemJnlLine);
                ItemJnlLine.Init();
                ItemJnlLine."Journal Template Name" := 'PRODUCT';
                ItemJnlLine."Journal Batch Name" := 'DEFAULT';
                ItemJnlLine."Line No." := LineNo;
                ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
                ItemJnlLine.Validate("Posting Date", Today);
                ItemJnlLine."Document No." := 'DESENS-' + Format(Today, 0, '<Year4><Month,2><Day,2>');
                ItemJnlLine.Validate("Item No.", BOMComponent."No.");
                ItemJnlLine.Description := 'Componente de ' + Item."No.";
                ItemJnlLine.Validate(Quantity, BOMComponent."Quantity per" * Quantity);
                ItemJnlLine."Location Code" := ItemLedgerEntry."Location Code";
                ItemJnlLine."Variant Code" := BOMComponent."Variant Code";

                // Copiar dimensiones
                ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
                ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";

                if ItemJnlLine.Insert(true) then begin
                    ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                    ComponentCount += 1;
                    TotalComponentQty += ItemJnlLine.Quantity;
                    LineNo += 10000;
                end else
                    Error('Error al crear línea de componente %1', BOMComponent."No.");
            until BOMComponent.Next() = 0;
        end;

        exit(StrSubstNo('✓ Desensamblado exitoso: %1 unidades de %2 → %3 componentes (Total: %4 unidades)',
            Quantity, Item."No.", ComponentCount, TotalComponentQty));
    end;

    procedure DisassembleWithComponents(ItemLedgerEntryNo: Integer; Quantity: Decimal; ComponentsJson: Text): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        JArray: JsonArray;
        JToken: JsonToken;
        JObject: JsonObject;
        JValue: JsonToken;
        LineNo: Integer;
        ComponentCount: Integer;
        TotalComponentQty: Decimal;
        CompItemNo: Code[20];
        CompDescription: Text[100];
        CompQuantity: Decimal;
        CompVariant: Code[10];
    begin
        // Validaciones
        if ItemLedgerEntryNo = 0 then
            Error('Debe especificar un material para desensamblar');

        if Quantity <= 0 then
            Error('La cantidad debe ser mayor a cero');

        if ComponentsJson = '' then
            Error('Debe especificar los componentes del desensamblado');

        // Obtener el Item Ledger Entry
        if not ItemLedgerEntry.Get(ItemLedgerEntryNo) then
            Error('No se encontró el movimiento de almacén %1', ItemLedgerEntryNo);

        // Validar cantidad disponible
        if ItemLedgerEntry."Remaining Quantity" < Quantity then
            Error('Cantidad insuficiente. Disponible: %1, Solicitado: %2',
                ItemLedgerEntry."Remaining Quantity", Quantity);

        // Obtener el producto
        if not Item.Get(ItemLedgerEntry."Item No.") then
            Error('No se encontró el producto %1', ItemLedgerEntry."Item No.");

        // Parsear JSON de componentes
        if not JArray.ReadFrom(ComponentsJson) then
            Error('Error al leer JSON de componentes');

        // Obtener siguiente número de línea
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'PRODUCT');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if ItemJnlLine.FindLast() then
            LineNo := ItemJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        ComponentCount := 0;
        TotalComponentQty := 0;

        // 1. Crear línea de salida del material base (negativo)
        Clear(ItemJnlLine);
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'PRODUCT';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        ItemJnlLine."Line No." := LineNo;
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
        ItemJnlLine.Validate("Posting Date", Today);
        ItemJnlLine."Document No." := 'DESENS-' + Format(Today, 0, '<Year4><Month,2><Day,2>');
        ItemJnlLine.Validate("Item No.", Item."No.");
        ItemJnlLine.Description := 'Desensamblado - Material Base';
        ItemJnlLine.Validate(Quantity, Quantity);
        ItemJnlLine."Location Code" := ItemLedgerEntry."Location Code";
        ItemJnlLine."Variant Code" := ItemLedgerEntry."Variant Code";

        // Copiar dimensiones
        ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";

        if ItemJnlLine.Insert(true) then begin
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            LineNo += 10000;
        end else
            Error('Error al crear línea de salida del material base');

        // 2. Crear líneas de entrada para cada componente desde JSON
        foreach JToken in JArray do begin
            JObject := JToken.AsObject();

            Clear(CompItemNo);
            Clear(CompDescription);
            Clear(CompQuantity);
            Clear(CompVariant);

            if JObject.Get('itemNo', JValue) and (not JValue.AsValue().IsNull()) then
                CompItemNo := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(CompItemNo));

            if JObject.Get('description', JValue) and (not JValue.AsValue().IsNull()) then
                CompDescription := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(CompDescription));

            if JObject.Get('quantity', JValue) and (not JValue.AsValue().IsNull()) then
                CompQuantity := JValue.AsValue().AsDecimal();

            // Obtener variante o lote desde el JSON si existe
            if JObject.Get('variantCode', JValue) and (not JValue.AsValue().IsNull()) then
                CompVariant := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(CompVariant));
            if JObject.Get('lotNo', JValue) and (not JValue.AsValue().IsNull()) then
                // reutilizamos CompVariant temporalmente para almacenar lotNo
                CompVariant := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(CompVariant));

            if (CompItemNo <> '') and (CompQuantity > 0) then begin
                Clear(ItemJnlLine);
                ItemJnlLine.Init();
                ItemJnlLine."Journal Template Name" := 'PRODUCT';
                ItemJnlLine."Journal Batch Name" := 'DEFAULT';
                ItemJnlLine."Line No." := LineNo;
                ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
                ItemJnlLine.Validate("Posting Date", Today);
                ItemJnlLine."Document No." := 'DESENS-' + Format(Today, 0, '<Year4><Month,2><Day,2>');
                ItemJnlLine.Validate("Item No.", CompItemNo);
                ItemJnlLine.Description := CompDescription;
                ItemJnlLine.Validate(Quantity, CompQuantity);
                ItemJnlLine."Location Code" := ItemLedgerEntry."Location Code";
                ItemJnlLine."Variant Code" := CompVariant;
                // Si el JSON contenía lote, asignarlo al Item Journal Line
                if CompVariant <> '' then
                    ItemJnlLine."Lot No." := CompVariant;

                // Copiar dimensiones
                ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
                ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";

                if ItemJnlLine.Insert(true) then begin
                    ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                    ComponentCount += 1;
                    TotalComponentQty += CompQuantity;
                    LineNo += 10000;
                end else
                    Error('Error al crear línea de componente %1', CompItemNo);
            end;
        end;

        exit(StrSubstNo('✓ Desensamblado exitoso: %1 unidades de %2 → %3 componentes (Total: %4 unidades)',
            Quantity, Item."No.", ComponentCount, TotalComponentQty));
    end;

    procedure DisassembleByItemNo(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ComponentsJson: Text): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Buscar el Item Ledger Entry más reciente con cantidad disponible
        ItemLedgerEntry.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
        ItemLedgerEntry.SetAscending("Posting Date", false);

        if not ItemLedgerEntry.FindFirst() then
            Error('No se encontró stock disponible del producto %1 en el almacén %2', ItemNo, LocationCode);

        if ItemLedgerEntry."Remaining Quantity" < Quantity then
            Error('Cantidad insuficiente. Disponible: %1, Solicitado: %2',
                ItemLedgerEntry."Remaining Quantity", Quantity);

        // Llamar al método principal con el Entry No encontrado
        exit(DisassembleWithComponents(ItemLedgerEntry."Entry No.", Quantity, ComponentsJson));
    end;

    procedure DisassembleToDestination(ItemLedgerEntryNo: Integer; Quantity: Decimal; ComponentsJson: Text; DestLocation: Code[10]): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        JArray: JsonArray;
        JToken: JsonToken;
        JObject: JsonObject;
        JValue: JsonToken;
        LineNo: Integer;
        ComponentCount: Integer;
        TotalComponentQty: Decimal;
        CompItemNo: Code[20];
        CompDescription: Text[100];
        CompQuantity: Decimal;
        CompVariantOrLot: Code[50];
    begin
        // Validaciones
        if ItemLedgerEntryNo = 0 then
            Error('Debe especificar un material para desensamblar');

        if Quantity <= 0 then
            Error('La cantidad debe ser mayor a cero');

        if ComponentsJson = '' then
            Error('Debe especificar los componentes del desensamblado');

        // Obtener el Item Ledger Entry
        if not ItemLedgerEntry.Get(ItemLedgerEntryNo) then
            Error('No se encontró el movimiento de almacén %1', ItemLedgerEntryNo);

        // Validar cantidad disponible
        if ItemLedgerEntry."Remaining Quantity" < Quantity then
            Error('Cantidad insuficiente. Disponible: %1, Solicitado: %2',
                ItemLedgerEntry."Remaining Quantity", Quantity);

        // Obtener el producto
        if not Item.Get(ItemLedgerEntry."Item No.") then
            Error('No se encontró el producto %1', ItemLedgerEntry."Item No.");

        // Parsear JSON de componentes
        if not JArray.ReadFrom(ComponentsJson) then
            Error('Error al leer JSON de componentes');

        // Obtener siguiente número de línea
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'PRODUCT');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if ItemJnlLine.FindLast() then
            LineNo := ItemJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        ComponentCount := 0;
        TotalComponentQty := 0;

        // 1. Crear línea de salida del material base (negativo) en origen
        Clear(ItemJnlLine);
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'PRODUCT';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        ItemJnlLine."Line No." := LineNo;
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
        ItemJnlLine.Validate("Posting Date", Today);
        ItemJnlLine."Document No." := 'DESENS-' + Format(Today, 0, '<Year4><Month,2><Day,2>');
        ItemJnlLine.Validate("Item No.", Item."No.");
        ItemJnlLine.Description := 'Desensamblado - Salida origen';
        ItemJnlLine.Validate(Quantity, Quantity);
        ItemJnlLine."Location Code" := ItemLedgerEntry."Location Code";
        ItemJnlLine."Variant Code" := ItemLedgerEntry."Variant Code";

        // Copiar dimensiones
        ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";

        if ItemJnlLine.Insert(true) then begin
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            LineNo += 10000;
        end else
            Error('Error al crear línea de salida del material base');

        // 2. Crear líneas de entrada para cada componente desde JSON en ubicación destino
        foreach JToken in JArray do begin
            JObject := JToken.AsObject();

            Clear(CompItemNo);
            Clear(CompDescription);
            Clear(CompQuantity);
            Clear(CompVariantOrLot);

            if JObject.Get('itemNo', JValue) and (not JValue.AsValue().IsNull()) then
                CompItemNo := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(CompItemNo));

            if JObject.Get('description', JValue) and (not JValue.AsValue().IsNull()) then
                CompDescription := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(CompDescription));

            if JObject.Get('quantity', JValue) and (not JValue.AsValue().IsNull()) then
                CompQuantity := JValue.AsValue().AsDecimal();

            if JObject.Get('lotNo', JValue) and (not JValue.AsValue().IsNull()) then
                CompVariantOrLot := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(CompVariantOrLot));

            if (CompItemNo <> '') and (CompQuantity > 0) then begin
                Clear(ItemJnlLine);
                ItemJnlLine.Init();
                ItemJnlLine."Journal Template Name" := 'PRODUCT';
                ItemJnlLine."Journal Batch Name" := 'DEFAULT';
                ItemJnlLine."Line No." := LineNo;
                ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
                ItemJnlLine.Validate("Posting Date", Today);
                ItemJnlLine."Document No." := 'DESENS-' + Format(Today, 0, '<Year4><Month,2><Day,2>');
                ItemJnlLine.Validate("Item No.", CompItemNo);
                ItemJnlLine.Description := CompDescription;
                ItemJnlLine.Validate(Quantity, CompQuantity);
                // Ubicación destino
                ItemJnlLine."Location Code" := DestLocation;
                // Si vino lote en JSON, usarlo
                if CompVariantOrLot <> '' then
                    ItemJnlLine."Lot No." := CompVariantOrLot;

                // Copiar dimensiones desde origen (puedes ajustar según necesites)
                ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
                ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";

                if ItemJnlLine.Insert(true) then begin
                    ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                    ComponentCount += 1;
                    TotalComponentQty += CompQuantity;
                    LineNo += 10000;
                end else
                    Error('Error al crear línea de componente %1', CompItemNo);
            end;
        end;

        exit(StrSubstNo('✓ Desensamblado hacia %1 exitoso: %2 unidades de %3 → %4 componentes (Total: %5 unidades)',
            DestLocation, Quantity, Item."No.", ComponentCount, TotalComponentQty));
    end;

    procedure DisassembleByItemNoToDestination(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ComponentsJson: Text; DestLocation: Code[10]): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Buscar el Item Ledger Entry más reciente con cantidad disponible
        ItemLedgerEntry.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
        ItemLedgerEntry.SetAscending("Posting Date", false);

        if not ItemLedgerEntry.FindFirst() then
            Error('No se encontró stock disponible del producto %1 en el almacén %2', ItemNo, LocationCode);

        if ItemLedgerEntry."Remaining Quantity" < Quantity then
            Error('Cantidad insuficiente. Disponible: %1, Solicitado: %2',
                ItemLedgerEntry."Remaining Quantity", Quantity);

        // Llamar al método principal con el Entry No encontrado y destino
        exit(DisassembleToDestination(ItemLedgerEntry."Entry No.", Quantity, ComponentsJson, DestLocation));
    end;
}
