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

        // 2. Crear líneas con tracking
        CreateAssemblyLines(AssemblyHeader, ComponentsArray, IDPro);

        // 3. Asignar tracking ANTES de copiar dimensiones
        AssignTrackingToLines(AssemblyHeader, ComponentsArray, IDPro);

        // 4. Copiar dimensiones del header a las líneas
        CopyDimensionsToLines(AssemblyHeader);

        // 5. Liberar el pedido
        ReleaseAssemblyOrder(AssemblyHeader);

        // 6. Validar antes de postear
        ValidateAssemblyOrder(AssemblyHeader);

        // 7. Postear
        Commit();
        AssemblyPost.Run(AssemblyHeader);

        // 8. Obtener número de documento posteado
        PostedDocNo := GetPostedDocumentNo(AssemblyOrderNo);
    end;

    local procedure CreateAssemblyOrder(ProductObj: JsonObject; var AssemblyHeader: Record "Assembly Header")
    var
        AssemblySetup: Record "Assembly Setup";
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

    local procedure AssignTrackingToLines(var AssemblyHeader: Record "Assembly Header"; ComponentsArray: JsonArray; IDPro: Integer)
    var
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        ComponentToken: JsonToken;
        ComponentObj: JsonObject;
        ComponentIDPro: Integer;
        LotNo: Code[50];
        Item: Record Item;
        EntryNo: Integer;
    begin
        // Iterar componentes para este IDPro
        foreach ComponentToken in ComponentsArray do begin
            ComponentObj := ComponentToken.AsObject();
            ComponentIDPro := GetIntValue(ComponentObj, 'IDPro');

            if ComponentIDPro = IDPro then begin
                LotNo := GetTextValue(ComponentObj, 'loteseleccionado');

                // Solo si hay lote y es tipo Item
                if (LotNo <> '') and (GetTextValue(ComponentObj, 'type') = 'Item') then begin
                    // Buscar la línea correspondiente
                    AssemblyLine.Reset();
                    AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
                    AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
                    AssemblyLine.SetRange("No.", GetTextValue(ComponentObj, 'componentItemNo'));
                    if AssemblyLine.FindFirst() then begin
                        // Verificar si el item requiere tracking
                        if Item.Get(AssemblyLine."No.") and (Item."Item Tracking Code" <> '') then begin
                            // Crear Reservation Entry
                            ReservEntry.Reset();
                            if ReservEntry.FindLast() then
                                EntryNo := ReservEntry."Entry No." + 1
                            else
                                EntryNo := 1;

                            Clear(ReservEntry);
                            ReservEntry.Init();
                            ReservEntry."Entry No." := EntryNo;
                            ReservEntry."Item No." := AssemblyLine."No.";
                            ReservEntry."Location Code" := AssemblyLine."Location Code";
                            ReservEntry."Variant Code" := AssemblyLine."Variant Code";
                            ReservEntry."Lot No." := LotNo;
                            ReservEntry."Source Type" := Database::"Assembly Line";
                            ReservEntry."Source Subtype" := AssemblyLine."Document Type".AsInteger();
                            ReservEntry."Source ID" := AssemblyLine."Document No.";
                            ReservEntry."Source Ref. No." := AssemblyLine."Line No.";
                            ReservEntry."Quantity (Base)" := -Abs(AssemblyLine."Quantity (Base)");
                            ReservEntry."Qty. to Handle (Base)" := ReservEntry."Quantity (Base)";
                            ReservEntry."Qty. to Invoice (Base)" := ReservEntry."Quantity (Base)";
                            ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
                            ReservEntry.Positive := false;
                            ReservEntry."Creation Date" := WorkDate();
                            ReservEntry."Shipment Date" := AssemblyLine."Due Date";
                            ReservEntry."Qty. per Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";
                            ReservEntry.Insert(true);
                        end;
                    end;
                end;
            end;
        end;

        Commit();
    end;

    local procedure CreateAssemblyLines(var AssemblyHeader: Record "Assembly Header"; ComponentsArray: JsonArray; IDPro: Integer)
    var
        ComponentToken: JsonToken;
        ComponentObj: JsonObject;
        ComponentIDPro: Integer;
    begin
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

        // Validar campos
        AssemblyLine.Validate("No.", GetTextValue(ComponentObj, 'componentItemNo'));

        // Location - SOLO para Items, Resources no tienen Location
        if (AssemblyLine.Type = AssemblyLine.Type::Item) and (GetTextValue(ComponentObj, 'almacenOrigen') <> '') then
            AssemblyLine.Validate("Location Code", GetTextValue(ComponentObj, 'almacenOrigen'));

        // Cantidad por unidad
        AssemblyLine.Validate("Quantity per", GetDecimalValue(ComponentObj, 'componentQty'));

        // Unit of Measure
        if GetTextValue(ComponentObj, 'unitOfMeasure') <> '' then
            AssemblyLine.Validate("Unit of Measure Code", GetTextValue(ComponentObj, 'unitOfMeasure'));

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

        AssemblyHeader.Validate(Status, AssemblyHeader.Status::Released);
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
