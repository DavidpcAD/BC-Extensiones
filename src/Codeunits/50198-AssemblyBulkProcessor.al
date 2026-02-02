codeunit 50198 "GJW Assembly Bulk Processor"
{
    /// <summary>
    /// Procesa múltiples Assembly Orders desde Power Apps
    /// Recibe productos y componentes con lotes asignados
    /// </summary>
    procedure ProcessBulkAssembly(ProductsJson: Text; ComponentsJson: Text): Text
    var
        ProductsArray: JsonArray;
        ComponentsArray: JsonArray;
        ProductToken: JsonToken;
        ResultArray: JsonArray;
        ResultObject: JsonObject;
        ErrorMsg: Text;
    begin
        // Try-catch para siempre retornar JSON válido
        if not TryProcessBulk(ProductsJson, ComponentsJson, ResultObject) then begin
            // Error en el procesamiento, retornar error JSON
            ErrorMsg := CopyStr(GetLastErrorText(), 1, 250);
            ResultObject.Add('results', ResultArray); // Array vacío
            ResultObject.Add('totalProcessed', 0);
            ResultObject.Add('error', ErrorMsg);
        end;

        exit(FormatJsonOutput(ResultObject));
    end;

    [TryFunction]
    local procedure TryProcessBulk(ProductsJson: Text; ComponentsJson: Text; var ResultObject: JsonObject)
    var
        ProductsArray: JsonArray;
        ComponentsArray: JsonArray;
        ProductToken: JsonToken;
        ResultArray: JsonArray;
    begin
        // Parse JSON
        if not ProductsArray.ReadFrom(ProductsJson) then
            Error('Invalid products JSON format');

        if not ComponentsArray.ReadFrom(ComponentsJson) then
            Error('Invalid components JSON format');

        // Procesar cada producto
        foreach ProductToken in ProductsArray do
            ProcessSingleProduct(ProductToken.AsObject(), ComponentsArray, ResultArray);

        // Construir respuesta
        ResultObject.Add('results', ResultArray);
        ResultObject.Add('totalProcessed', ProductsArray.Count);
    end;

    local procedure ProcessSingleProduct(ProductObj: JsonObject; ComponentsArray: JsonArray; var ResultArray: JsonArray)
    var
        AssemblyHeader: Record "Assembly Header";
        IDPro: Integer;
        AssemblyOrderNo: Code[20];
        PostedDocNo: Code[20];
        ResultObj: JsonObject;
        Success: Boolean;
        ErrorMsg: Text;
    begin
        IDPro := GetIntValue(ProductObj, 'IDPro');

        // Intentar crear y postear
        if TryProcessProduct(ProductObj, ComponentsArray, IDPro, AssemblyOrderNo, PostedDocNo) then begin
            Success := true;
            ErrorMsg := '';
        end else begin
            Success := false;
            ErrorMsg := CopyStr(GetLastErrorText(), 1, 250);
        end;

        // Agregar resultado
        ResultObj.Add('IDPro', IDPro);
        ResultObj.Add('success', Success);
        ResultObj.Add('assemblyOrderNo', AssemblyOrderNo);
        ResultObj.Add('postedDocumentNo', PostedDocNo);
        ResultObj.Add('productItemNo', GetTextValue(ProductObj, 'productItemNo'));
        ResultObj.Add('productDescription', GetTextValue(ProductObj, 'productDescription'));
        ResultObj.Add('errorMessage', ErrorMsg);

        ResultArray.Add(ResultObj);
    end;

    [TryFunction]
    local procedure TryProcessProduct(ProductObj: JsonObject; ComponentsArray: JsonArray; IDPro: Integer; var AssemblyOrderNo: Code[20]; var PostedDocNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyPost: Codeunit "Assembly-Post";
    begin
        // 1. Crear Assembly Order
        CreateAssemblyOrder(ProductObj, AssemblyHeader);
        AssemblyOrderNo := AssemblyHeader."No.";

        // 2. Crear líneas (BC copiará automáticamente las dimensiones del header)
        CreateAssemblyLines(AssemblyHeader, ComponentsArray, IDPro);

        // 3. Asignar dimensiones correctas a las líneas (ANTES de liberar)
        AssignDimensionsByLocation(AssemblyHeader);

        // 4. Liberar el pedido
        ReleaseAssemblyOrder(AssemblyHeader);

        // 5. Asignar tracking con lotes a componentes (INPUT)
        AssignTrackingToLines(AssemblyHeader, ComponentsArray, IDPro);

        // 6. Asignar tracking al producto final (OUTPUT) si requiere lote
        AssignTrackingToOutput(AssemblyHeader);

        // 7. Validar antes de postear
        ValidateAssemblyOrder(AssemblyHeader);

        // 7. Postear
        Commit();
        if not AssemblyPost.Run(AssemblyHeader) then
            Error('Failed to post Assembly Order %1: %2', AssemblyOrderNo, GetLastErrorText());

        // 8. Obtener número de documento posteado
        PostedDocNo := GetPostedDocumentNo(AssemblyOrderNo);

        // 9. Verificar que se posteó correctamente
        if PostedDocNo = '' then
            Error('Assembly Order %1 was processed but no Posted Document was found', AssemblyOrderNo);
    end;

    local procedure CreateAssemblyOrder(ProductObj: JsonObject; var AssemblyHeader: Record "Assembly Header")
    var
        AssemblySetup: Record "Assembly Setup";
        DimensionValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        DimSetID: Integer;
    begin
        AssemblySetup.Get();
        AssemblySetup.TestField("Assembly Order Nos.");

        // Crear header
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader."No." := '';
        AssemblyHeader.Insert(true);

        // Validar campos principales
        AssemblyHeader.Validate("Item No.", GetTextValue(ProductObj, 'productItemNo'));
        AssemblyHeader.Validate(Quantity, GetDecimalValue(ProductObj, 'cantidad'));

        // Almacén destino (donde quedará el producto ensamblado)
        if GetTextValue(ProductObj, 'almacenDestino') <> '' then
            AssemblyHeader.Validate("Location Code", GetTextValue(ProductObj, 'almacenDestino'));

        // Unit of Measure
        if GetTextValue(ProductObj, 'unitOfMeasure') <> '' then
            AssemblyHeader.Validate("Unit of Measure Code", GetTextValue(ProductObj, 'unitOfMeasure'));

        // Fechas
        AssemblyHeader.Validate("Posting Date", WorkDate());
        AssemblyHeader.Validate("Due Date", WorkDate());

        // Cantidad a ensamblar
        AssemblyHeader."Quantity to Assemble" := AssemblyHeader.Quantity;
        AssemblyHeader."Quantity to Assemble (Base)" := AssemblyHeader."Quantity (Base)";

        AssemblyHeader.Modify(true);
    end;

    local procedure CopyDimensionsToLines(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        DimMgt: Codeunit DimensionManagement;
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        if AssemblyLine.FindSet() then
            repeat
                // Copiar dimensiones del header a la línea
                AssemblyLine."Dimension Set ID" := AssemblyHeader."Dimension Set ID";
                AssemblyLine.Modify(true);
            until AssemblyLine.Next() = 0;
    end;

    local procedure AssignDimensionsByLocation(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        DimSetID: Integer;
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        if AssemblyLine.FindSet(true) then  // true = allow modify
            repeat
                // Solo procesar Items con Location Code
                if (AssemblyLine.Type = AssemblyLine.Type::Item) and (AssemblyLine."Location Code" <> '') then begin
                    Clear(TempDimSetEntry);
                    TempDimSetEntry.DeleteAll();

                    // Si el Location es F-MADERAS, asignar AC = PRO FABRICACION y CC = F-MADERAS
                    if AssemblyLine."Location Code" = 'F-MADERAS' then begin
                        // Dimensión 1: AC = PRO FABRICACION
                        TempDimSetEntry.Init();
                        TempDimSetEntry."Dimension Code" := 'AC';
                        TempDimSetEntry."Dimension Value Code" := 'PRO FABRICACION';
                        if DimensionValue.Get('AC', 'PRO FABRICACION') then
                            TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
                        TempDimSetEntry.Insert();

                        // Dimensión 2: CC = F-MADERAS
                        TempDimSetEntry.Init();
                        TempDimSetEntry."Dimension Code" := 'CC';
                        TempDimSetEntry."Dimension Value Code" := 'F-MADERAS';
                        if DimensionValue.Get('CC', 'F-MADERAS') then
                            TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
                        TempDimSetEntry.Insert();

                        DimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
                        AssemblyLine."Dimension Set ID" := DimSetID;
                        AssemblyLine.Modify(true);
                    end else begin
                        // Para otros almacenes, copiar del header
                        AssemblyLine."Dimension Set ID" := AssemblyHeader."Dimension Set ID";
                        AssemblyLine.Modify(true);
                    end;
                end;
            until AssemblyLine.Next() = 0;
    end;

    local procedure AssignTrackingToLines(var AssemblyHeader: Record "Assembly Header"; ComponentsArray: JsonArray; IDPro: Integer)
    var
        AssemblyLine: Record "Assembly Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ComponentToken: JsonToken;
        ComponentObj: JsonObject;
        ComponentIDPro: Integer;
        LotNoInt: Integer;
        LotNo: Code[50];
        Item: Record Item;
        EntryNo: Integer;
        AvailableQty: Decimal;
    begin
        // Iterar componentes para este IDPro
        foreach ComponentToken in ComponentsArray do begin
            ComponentObj := ComponentToken.AsObject();
            ComponentIDPro := GetIntValue(ComponentObj, 'IDPro');

            if ComponentIDPro = IDPro then begin
                // IMPORTANTE: Convertir el lote de Integer a Text
                LotNoInt := GetIntValue(ComponentObj, 'loteseleccionado');
                if LotNoInt > 0 then
                    LotNo := Format(LotNoInt)
                else
                    LotNo := '';

                // Solo si hay lote y es tipo Item
                if (LotNo <> '') and (GetTextValue(ComponentObj, 'type') = 'Item') then begin
                    // Buscar la línea correspondiente
                    AssemblyLine.Reset();
                    AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
                    AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
                    AssemblyLine.SetRange("No.", GetTextValue(ComponentObj, 'componentItemNo'));
                    if AssemblyLine.FindFirst() then begin
                        // CRÍTICO: FORZAR Location Code aquí antes de buscar el lote
                        // BC lo sobrescribe con el del header, necesitamos el almacenOrigen
                        if GetTextValue(ComponentObj, 'almacenOrigen') <> '' then begin
                            AssemblyLine."Location Code" := GetTextValue(ComponentObj, 'almacenOrigen');
                            AssemblyLine.Modify(true);
                            AssemblyLine.Find(); // Refrescar
                        end;

                        // Verificar si el item requiere tracking
                        if Item.Get(AssemblyLine."No.") and (Item."Item Tracking Code" <> '') then begin
                            // Verificar que existe inventario con ese lote en la ubicación correcta
                            // IMPORTANTE: Reconfirmar el Location Code de la línea
                            AssemblyLine.Find();  // Refrescar para obtener el Location Code correcto

                            ItemLedgerEntry.Reset();
                            ItemLedgerEntry.SetCurrentKey("Item No.", "Location Code", "Lot No.");
                            ItemLedgerEntry.SetRange("Item No.", AssemblyLine."No.");
                            ItemLedgerEntry.SetRange("Location Code", AssemblyLine."Location Code");
                            ItemLedgerEntry.SetRange("Lot No.", LotNo);
                            ItemLedgerEntry.SetRange(Open, true);
                            if not ItemLedgerEntry.IsEmpty then begin
                                // Crear par de Reservation Entries (positiva + negativa)
                                // 1. Entrada positiva (desde el inventario)
                                ReservationEntry.Reset();
                                if ReservationEntry.FindLast() then
                                    EntryNo := ReservationEntry."Entry No." + 1
                                else
                                    EntryNo := 1;

                                AvailableQty := Abs(AssemblyLine."Quantity (Base)");

                                // Entrada POSITIVA (disponibilidad)
                                Clear(ReservationEntry);
                                ReservationEntry.Init();
                                ReservationEntry."Entry No." := EntryNo;
                                ReservationEntry."Item No." := AssemblyLine."No.";
                                ReservationEntry."Location Code" := AssemblyLine."Location Code";
                                ReservationEntry."Variant Code" := AssemblyLine."Variant Code";
                                ReservationEntry."Lot No." := LotNo;
                                ReservationEntry."Source Type" := Database::"Item Ledger Entry";
                                ReservationEntry."Source ID" := '';
                                ReservationEntry."Quantity (Base)" := AvailableQty;
                                ReservationEntry."Qty. to Handle (Base)" := AvailableQty;
                                ReservationEntry."Qty. to Invoice (Base)" := AvailableQty;
                                ReservationEntry."Creation Date" := WorkDate();
                                ReservationEntry."Qty. per Unit of Measure" := 1;
                                ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
                                ReservationEntry.Positive := true;
                                ReservationEntry."Expected Receipt Date" := WorkDate();
                                ReservationEntry.Insert(true);

                                // 2. Entrada NEGATIVA (demanda del Assembly)
                                EntryNo += 1;
                                Clear(ReservationEntry);
                                ReservationEntry.Init();
                                ReservationEntry."Entry No." := EntryNo;
                                ReservationEntry."Item No." := AssemblyLine."No.";
                                ReservationEntry."Location Code" := AssemblyLine."Location Code";
                                ReservationEntry."Variant Code" := AssemblyLine."Variant Code";
                                ReservationEntry."Lot No." := LotNo;
                                ReservationEntry."Source Type" := Database::"Assembly Line";
                                ReservationEntry."Source Subtype" := AssemblyLine."Document Type".AsInteger();
                                ReservationEntry."Source ID" := AssemblyLine."Document No.";
                                ReservationEntry."Source Ref. No." := AssemblyLine."Line No.";
                                ReservationEntry."Quantity (Base)" := -AvailableQty;
                                ReservationEntry."Qty. to Handle (Base)" := -AvailableQty;
                                ReservationEntry."Qty. to Invoice (Base)" := -AvailableQty;
                                ReservationEntry."Creation Date" := WorkDate();
                                ReservationEntry."Qty. per Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";
                                ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
                                ReservationEntry.Positive := false;
                                ReservationEntry."Shipment Date" := WorkDate();
                                ReservationEntry.Insert(true);
                            end else begin
                                Error('Lot %1 not found in location %2 for item %3. JSON almacenOrigen: %4',
                                    LotNo,
                                    AssemblyLine."Location Code",
                                    AssemblyLine."No.",
                                    GetTextValue(ComponentObj, 'almacenOrigen'));
                            end;
                        end;
                    end;
                end;
            end;
        end;

        Commit();
    end;

    local procedure CreateAssemblyLines(var AssemblyHeader: Record "Assembly Header"; ComponentsArray: JsonArray; IDPro: Integer)
    var
        AssemblyLine: Record "Assembly Line";
        ComponentToken: JsonToken;
        ComponentObj: JsonObject;
        ComponentIDPro: Integer;
    begin
        // IMPORTANTE: Borrar todas las líneas automáticas que BC creó desde la BOM
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.DeleteAll(true);

        // Filtrar y crear líneas solo para este IDPro
        foreach ComponentToken in ComponentsArray do begin
            ComponentObj := ComponentToken.AsObject();
            ComponentIDPro := GetIntValue(ComponentObj, 'IDPro');

            if ComponentIDPro = IDPro then
                CreateSingleLine(AssemblyHeader, ComponentObj);
        end;
    end;

    local procedure CreateSingleLine(var AssemblyHeader: Record "Assembly Header"; ComponentObj: JsonObject)
    var
        AssemblyLine: Record "Assembly Line";
        LineType: Text;
        NextLineNo: Integer;
    begin
        // Calcular siguiente número de línea
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        if AssemblyLine.FindLast() then
            NextLineNo := AssemblyLine."Line No." + 10000
        else
            NextLineNo := 10000;

        // Crear línea
        AssemblyLine.Init();
        AssemblyLine."Document Type" := AssemblyHeader."Document Type";
        AssemblyLine."Document No." := AssemblyHeader."No.";
        AssemblyLine."Line No." := NextLineNo;

        // Tipo (Item o Resource)
        LineType := GetTextValue(ComponentObj, 'type');
        case LineType of
            'Item':
                AssemblyLine.Type := AssemblyLine.Type::Item;
            'Resource':
                AssemblyLine.Type := AssemblyLine.Type::Resource;
            else
                Error('Invalid line type: %1. Expected "Item" or "Resource"', LineType);
        end;

        AssemblyLine.Insert(true);

        // Validar item/resource primero
        AssemblyLine.Validate("No.", GetTextValue(ComponentObj, 'componentItemNo'));

        // Cantidad por unidad
        AssemblyLine.Validate("Quantity per", GetDecimalValue(ComponentObj, 'componentQty'));

        // Unit of Measure
        if GetTextValue(ComponentObj, 'unitOfMeasure') <> '' then
            AssemblyLine.Validate("Unit of Measure Code", GetTextValue(ComponentObj, 'unitOfMeasure'));

        // CRÍTICO: Forzar Location AL FINAL, después de TODAS las validaciones
        // BC sobrescribe el Location con el del header en cada Validate()
        if (AssemblyLine.Type = AssemblyLine.Type::Item) and (GetTextValue(ComponentObj, 'almacenOrigen') <> '') then begin
            // NO usar Validate aquí porque puede disparar otras validaciones
            // Asignación directa del campo
            AssemblyLine."Location Code" := GetTextValue(ComponentObj, 'almacenOrigen');
        end;

        // Cantidad a consumir
        AssemblyLine."Quantity to Consume" := AssemblyLine.Quantity;
        AssemblyLine."Quantity to Consume (Base)" := AssemblyLine."Quantity (Base)";

        AssemblyLine.Modify(true);

        // NOTA: El lot tracking se debe asignar manualmente en BC o mediante
        // Item Tracking Lines API después de crear el pedido.
        // La asignación automática requiere validaciones complejas que BC
        // realiza internamente en la UI.

        // TODO: Si se requiere tracking automático, implementar llamada a
        // Item Tracking Lines después de Release pero antes de Post.
    end;

    // NOTA: Esta función está deshabilitada porque crear Reservation Entries manualmente
    // para Assembly Lines requiere validaciones muy complejas que BC maneja internamente.
    // Para implementar tracking automático, considerar:
    // 1. Usar Item Tracking Lines API después de crear el pedido
    // 2. O dejar que el usuario asigne tracking manualmente en BC
    /*
    local procedure AssignLotTracking(var AssemblyLine: Record "Assembly Line"; LotNo: Code[50])
    var
        ReservEntry: Record "Reservation Entry";
        Item: Record Item;
        QtyBase: Decimal;
        EntryNo: Integer;
    begin
        if LotNo = '' then
            exit;

        if not Item.Get(AssemblyLine."No.") then
            exit;

        if Item."Item Tracking Code" = '' then
            exit;

        QtyBase := Abs(AssemblyLine."Quantity (Base)");

        ReservEntry.Reset();
        if ReservEntry.FindLast() then
            EntryNo := ReservEntry."Entry No." + 1
        else
            EntryNo := 1;

        Clear(ReservEntry);
        ReservEntry.Init();
        ReservEntry."Entry No." := EntryNo;
        ReservEntry."Source Type" := Database::"Assembly Line";
        ReservEntry."Source Subtype" := AssemblyLine."Document Type".AsInteger();
        ReservEntry."Source ID" := AssemblyLine."Document No.";
        ReservEntry."Source Ref. No." := AssemblyLine."Line No.";
        ReservEntry."Item No." := AssemblyLine."No.";
        ReservEntry."Lot No." := LotNo;
        ReservEntry."Quantity (Base)" := -QtyBase;
        ReservEntry.Positive := false;
        ReservEntry.Insert(true);
        Commit();
    end;
    */

    local procedure ReleaseAssemblyOrder(var AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyHeader.Find();

        if AssemblyHeader.Status = AssemblyHeader.Status::Released then
            exit;

        // NO usar Validate para evitar que BC sobrescriba las dimensiones que acabamos de asignar
        AssemblyHeader.Status := AssemblyHeader.Status::Released;
        AssemblyHeader.Modify(true);
    end;

    local procedure ValidateAssemblyOrder(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyHeader.Find();

        // Validaciones básicas
        AssemblyHeader.TestField("Item No.");
        AssemblyHeader.TestField(Quantity);
        AssemblyHeader.TestField(Status, AssemblyHeader.Status::Released);

        if AssemblyHeader."Quantity to Assemble" = 0 then
            Error('Quantity to Assemble must be greater than 0 for Assembly Order %1', AssemblyHeader."No.");

        // Verificar que haya líneas
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetFilter(Type, '<>%1', AssemblyLine.Type::" ");
        if AssemblyLine.IsEmpty then
            Error('Assembly Order %1 has no component lines', AssemblyHeader."No.");
    end;

    local procedure GetPostedDocumentNo(AssemblyOrderNo: Code[20]): Code[20]
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        PostedAssemblyHeader.SetCurrentKey("Order No.");
        PostedAssemblyHeader.SetRange("Order No.", AssemblyOrderNo);
        if PostedAssemblyHeader.FindLast() then
            exit(PostedAssemblyHeader."No.");

        exit('');
    end;

    // Helper functions para JSON
    local procedure GetTextValue(JObj: JsonObject; KeyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObj.Get(KeyName, JToken) and not JToken.AsValue().IsNull then
            exit(JToken.AsValue().AsText());
        exit('');
    end;

    local procedure AssignTrackingToOutput(var AssemblyHeader: Record "Assembly Header")
    var
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        EntryNo: Integer;
        OutputQty: Decimal;
        GeneratedLotNo: Code[50];
    begin
        // Verificar si el producto final requiere tracking
        if not Item.Get(AssemblyHeader."Item No.") then
            exit;

        if Item."Item Tracking Code" = '' then
            exit; // No requiere tracking

        // Generar número de lote automáticamente usando el No. del Assembly Order
        GeneratedLotNo := AssemblyHeader."No.";

        // Cantidad del producto final
        OutputQty := AssemblyHeader."Quantity (Base)";

        // Obtener siguiente Entry No.
        ReservationEntry.Reset();
        if ReservationEntry.FindLast() then
            EntryNo := ReservationEntry."Entry No." + 1
        else
            EntryNo := 1;

        // Crear Reservation Entry para el OUTPUT (producto ensamblado)
        Clear(ReservationEntry);
        ReservationEntry.Init();
        ReservationEntry."Entry No." := EntryNo;
        ReservationEntry."Item No." := AssemblyHeader."Item No.";
        ReservationEntry."Location Code" := AssemblyHeader."Location Code";
        ReservationEntry."Variant Code" := AssemblyHeader."Variant Code";
        ReservationEntry."Lot No." := GeneratedLotNo;
        ReservationEntry."Source Type" := Database::"Assembly Header";
        ReservationEntry."Source Subtype" := AssemblyHeader."Document Type".AsInteger();
        ReservationEntry."Source ID" := AssemblyHeader."No.";
        ReservationEntry."Source Ref. No." := 0; // El header no tiene Line No.
        ReservationEntry."Quantity (Base)" := OutputQty;
        ReservationEntry."Qty. to Handle (Base)" := OutputQty;
        ReservationEntry."Qty. to Invoice (Base)" := OutputQty;
        ReservationEntry."Creation Date" := WorkDate();
        ReservationEntry."Qty. per Unit of Measure" := AssemblyHeader."Qty. per Unit of Measure";
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
        ReservationEntry.Positive := true;
        ReservationEntry."Expected Receipt Date" := WorkDate();
        ReservationEntry.Insert(true);

        Commit();
    end;

    local procedure GetIntValue(JObj: JsonObject; KeyName: Text): Integer
    var
        JToken: JsonToken;
    begin
        if JObj.Get(KeyName, JToken) and not JToken.AsValue().IsNull then
            exit(JToken.AsValue().AsInteger());
        exit(0);
    end;

    local procedure GetDecimalValue(JObj: JsonObject; KeyName: Text): Decimal
    var
        JToken: JsonToken;
    begin
        if JObj.Get(KeyName, JToken) and not JToken.AsValue().IsNull then
            exit(JToken.AsValue().AsDecimal());
        exit(0);
    end;

    local procedure FormatJsonOutput(JObj: JsonObject): Text
    var
        ResultText: Text;
    begin
        JObj.WriteTo(ResultText);
        exit(ResultText);
    end;
}
