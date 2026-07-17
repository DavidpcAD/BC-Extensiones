// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50230 "Adelante PO Actions"
// Propósito: Acciones sobre Pedidos de Compra que la API estándar v2.0 NO permite
//            por escritura directa (el campo Status es read-only / sistema).
//            Se exponen como Web Service OData ("AdelantePO") para que la app de
//            Compras las invoque por S2S al aprobar/reabrir una orden.
//
//   - ReleaseOrder(orderNo)          ->  PerformManualRelease  ->  Status = "Lanzado"
//   - ReopenOrder(orderNo)           ->  PerformManualReopen   ->  Status = "Abierto"
//   - PostInvoice(...)               ->  Recibir + Facturar (Modo 1: todo bien)
//   - PostReceipt(...)               ->  Solo Recibir       (Modo 2: factura en revisión)
//   - PostInvoiceOfReceived(...)     ->  Solo Facturar lo ya recibido (Modo 2: cierre)
//
// Llamada desde la app (OData V4 unbound action, S2S):
//   POST .../ODataV4/AdelantePO_ReleaseOrder?company={companyId}
//   body: { "orderNo": "CP-000867" }   ->  respuesta: { "value": "Released" }
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50230 "Adelante PO Actions"
{
    Access = Public;

    /// <summary>
    /// Aprueba y lanza un pedido de compra en un solo paso (para el botón "Aprobar y lanzar"
    /// de la app): 1) si hay workflow de aprobación activo y el documento está Abierto, envía
    /// la solicitud de aprobación; 2) aprueba todas las solicitudes abiertas del documento
    /// (soporta varios niveles); 3) si el workflow no lo liberó solo, hace el Release manual.
    /// Devuelve el estado resultante (debería ser "Released"/"Lanzado").
    /// NOTA: la auto-aprobación requiere que el usuario con el que la app se conecta a BC (S2S)
    /// sea un aprobador válido del workflow. Si no hay workflow configurado, solo lanza.
    /// </summary>
    procedure ReleaseOrder(orderNo: Code[20]): Text
    var
        PurchHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        guard: Integer;
    begin
        GetOrder(PurchHeader, orderNo);

        // 0) Asignar los cargos de producto (flete) mientras el pedido está Abierto.
        //    Best-effort: si algo falla no debe bloquear el "Aprobar y lanzar" (el
        //    registro volverá a asignar de todos modos). Ver AsignarCargosProducto.
        if PurchHeader.Status = PurchHeader.Status::Open then
            if not TryAsignarCargosEnLanzamiento(PurchHeader) then;

        // 1) Enviar a aprobación si hay workflow activo y el documento está Abierto.
        if PurchHeader.Status = PurchHeader.Status::Open then
            if ApprovalsMgmt.IsPurchaseApprovalsWorkflowEnabled(PurchHeader) then
                ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // 2) Aprobar las solicitudes abiertas del documento (soporta varios niveles).
        //    ApproveRecordApprovalRequest aprueba las entradas asignadas al usuario conectado.
        for guard := 1 to 20 do begin
            ApprovalEntry.Reset();
            ApprovalEntry.SetRange("Table ID", Database::"Purchase Header");
            ApprovalEntry.SetRange("Document Type", ApprovalEntry."Document Type"::Order);
            ApprovalEntry.SetRange("Document No.", orderNo);
            ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
            if ApprovalEntry.IsEmpty() then
                break;
            ApprovalsMgmt.ApproveRecordApprovalRequest(PurchHeader.RecordId);
        end;

        // 3) Si el workflow no lo liberó automáticamente, lanzarlo manualmente.
        PurchHeader.Find();
        if PurchHeader.Status = PurchHeader.Status::Open then
            ReleasePurchDoc.PerformManualRelease(PurchHeader);

        exit(StatusText(orderNo));
    end;

    /// <summary>Reabre (Reopen) un pedido de compra lanzado, dejándolo en Abierto.</summary>
    procedure ReopenOrder(orderNo: Code[20]): Text
    var
        PurchHeader: Record "Purchase Header";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        GetOrder(PurchHeader, orderNo);
        ReleasePurchDoc.PerformManualReopen(PurchHeader);
        exit(StatusText(orderNo));
    end;

    /// <summary>
    /// Registra (Recibir + Facturar) una FACTURA parcial del pedido en BC, generando
    /// todos los movimientos contables. linesJson = [{"itemNo":"M05-0037","qty":3}, ...]
    /// con la cantidad recibida en ESTA factura por línea. Las líneas no incluidas
    /// quedan en 0 (el pedido sigue abierto hasta completar todo). Devuelve el N.º de
    /// la factura de compra registrada.
    /// </summary>
    procedure PostInvoice(orderNo: Code[20]; vendorInvoiceNo: Code[35]; linesJson: Text): Text
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        JArr: JsonArray;
        JTok: JsonToken;
        JObj: JsonObject;
        v: JsonToken;
        itm: Code[20];
        qty: Decimal;
        variantCode: Code[10];
        applyVariant: Boolean;
        postedNo: Code[20];
    begin
        GetOrder(PurchHeader, orderNo);
        if vendorInvoiceNo = '' then
            Error('Falta el N.º de factura del proveedor.');
        if not JArr.ReadFrom(linesJson) then
            Error('No se pudieron leer las líneas (JSON inválido).');

        // Encabezado: N.º factura proveedor + modo Recibir y Facturar.
        PurchHeader.Validate("Vendor Invoice No.", vendorInvoiceNo);
        PurchHeader."Posting Date" := Today();
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchHeader.Modify(true);

        // Reset: nada a recibir/facturar hasta asignar lo de esta factura.
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", orderNo);
        if PurchLine.FindSet() then
            repeat
                if (PurchLine."Qty. to Receive" <> 0) or (PurchLine."Qty. to Invoice" <> 0) then begin
                    PurchLine.Validate("Qty. to Receive", 0);
                    PurchLine.Validate("Qty. to Invoice", 0);
                    PurchLine.Modify(true);
                end;
            until PurchLine.Next() = 0;

        // Asignar la cantidad de esta factura por línea (match por itemNo, secuencial
        // para soportar el mismo ítem repetido y líneas omitidas).
        foreach JTok in JArr do begin
            JObj := JTok.AsObject();
            if JObj.Get('itemNo', v) then itm := CopyStr(v.AsValue().AsText(), 1, MaxStrLen(itm)) else itm := '';
            qty := 0;
            if JObj.Get('qty', v) then qty := v.AsValue().AsDecimal();
            // Variante opcional: si viene en el JSON, se usa para desambiguar cuando el
            // mismo ítem aparece en varias líneas con distinta variante.
            variantCode := '';
            applyVariant := false;
            if JObj.Get('variantCode', v) then
                if not v.AsValue().IsNull() then begin
                    variantCode := CopyStr(v.AsValue().AsText(), 1, MaxStrLen(variantCode));
                    applyVariant := true;
                end;
            if (itm <> '') and (qty > 0) then begin
                PurchLine.Reset();
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange("Document No.", orderNo);
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                PurchLine.SetRange("No.", itm);
                if applyVariant then
                    PurchLine.SetRange("Variant Code", variantCode);
                PurchLine.SetFilter("Outstanding Quantity", '>0');
                PurchLine.SetRange("Qty. to Receive", 0);
                if PurchLine.FindFirst() then begin
                    PurchLine.Validate("Qty. to Receive", qty);
                    PurchLine.Validate("Qty. to Invoice", qty);
                    PurchLine.Modify(true);
                end;
            end;
        end;

        // Distribuir los cargos de producto (flete) por importe entre las líneas de
        // artículo que se reciben/facturan en esta factura, antes de registrar.
        AsignarCargosProducto(PurchHeader, true, MenuTextForMethod(''));

        PurchPost.Run(PurchHeader);
        postedNo := PurchHeader."Last Posting No.";
        if postedNo = '' then
            postedNo := vendorInvoiceNo;
        exit(postedNo);
    end;

    /// <summary>
    /// Registra SOLO la RECEPCIÓN (Receive) de un pedido, SIN facturar. Mueve inventario
    /// y "Cantidad recibida" pero NO genera factura ni movimientos del proveedor. Se usa
    /// en el Modo 2: el material llega bien pero la factura viene con problemas → se recibe
    /// el material y la factura queda pendiente de revisión (Kattya la registra después con
    /// PostInvoiceOfReceived). linesJson = [{"itemNo":"M05-0037","qty":3}, ...] con la
    /// cantidad recibida en ESTA recepción por línea. Devuelve el N.º de recepción registrada.
    /// </summary>
    procedure PostReceipt(orderNo: Code[20]; linesJson: Text): Text
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        JArr: JsonArray;
        JTok: JsonToken;
        JObj: JsonObject;
        v: JsonToken;
        itm: Code[20];
        qty: Decimal;
        variantCode: Code[10];
        applyVariant: Boolean;
        postedNo: Code[20];
    begin
        GetOrder(PurchHeader, orderNo);
        if not JArr.ReadFrom(linesJson) then
            Error('No se pudieron leer las líneas (JSON inválido).');

        // Encabezado: solo Recibir (sin factura).
        PurchHeader."Posting Date" := Today();
        PurchHeader.Receive := true;
        PurchHeader.Invoice := false;
        PurchHeader.Modify(true);

        // Reset: nada a recibir/facturar hasta asignar lo de esta recepción.
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", orderNo);
        if PurchLine.FindSet() then
            repeat
                if (PurchLine."Qty. to Receive" <> 0) or (PurchLine."Qty. to Invoice" <> 0) then begin
                    PurchLine.Validate("Qty. to Receive", 0);
                    PurchLine.Validate("Qty. to Invoice", 0);
                    PurchLine.Modify(true);
                end;
            until PurchLine.Next() = 0;

        // Asignar la cantidad a recibir por línea (match por itemNo, secuencial para
        // soportar el mismo ítem repetido y líneas omitidas). No se factura nada.
        foreach JTok in JArr do begin
            JObj := JTok.AsObject();
            if JObj.Get('itemNo', v) then itm := CopyStr(v.AsValue().AsText(), 1, MaxStrLen(itm)) else itm := '';
            qty := 0;
            if JObj.Get('qty', v) then qty := v.AsValue().AsDecimal();
            // Variante opcional: si viene en el JSON, se usa para desambiguar cuando el
            // mismo ítem aparece en varias líneas con distinta variante.
            variantCode := '';
            applyVariant := false;
            if JObj.Get('variantCode', v) then
                if not v.AsValue().IsNull() then begin
                    variantCode := CopyStr(v.AsValue().AsText(), 1, MaxStrLen(variantCode));
                    applyVariant := true;
                end;
            if (itm <> '') and (qty > 0) then begin
                PurchLine.Reset();
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange("Document No.", orderNo);
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                PurchLine.SetRange("No.", itm);
                if applyVariant then
                    PurchLine.SetRange("Variant Code", variantCode);
                PurchLine.SetFilter("Outstanding Quantity", '>0');
                PurchLine.SetRange("Qty. to Receive", 0);
                if PurchLine.FindFirst() then begin
                    PurchLine.Validate("Qty. to Receive", qty);
                    PurchLine.Validate("Qty. to Invoice", 0); // no facturar en esta recepción
                    PurchLine.Modify(true);
                end;
            end;
        end;

        // Distribuir los cargos de producto (flete) por importe entre las líneas de
        // artículo que se reciben en esta recepción. El cargo se recibe (no se factura);
        // la factura posterior (PostInvoiceOfReceived) conservará esta asignación.
        AsignarCargosProducto(PurchHeader, true, MenuTextForMethod(''));

        PurchPost.Run(PurchHeader);
        postedNo := PurchHeader."Last Receiving No.";
        exit(postedNo);
    end;

    /// <summary>
    /// Registra SOLO la FACTURA de material YA RECIBIDO (Invoice, sin volver a recibir).
    /// Se usa en el Modo 2 cuando Kattya, tras revisar, registra la factura de una recepción
    /// que ya entró por PostReceipt. Solo factura lo que está recibido y pendiente de facturar
    /// ("Qty. Rcd. Not Invoiced"). linesJson = [{"itemNo":"M05-0037","qty":3}, ...] con la
    /// cantidad a facturar por línea. Devuelve el N.º de la factura de compra registrada.
    /// </summary>
    procedure PostInvoiceOfReceived(orderNo: Code[20]; vendorInvoiceNo: Code[35]; linesJson: Text): Text
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        JArr: JsonArray;
        JTok: JsonToken;
        JObj: JsonObject;
        v: JsonToken;
        itm: Code[20];
        qty: Decimal;
        variantCode: Code[10];
        applyVariant: Boolean;
        postedNo: Code[20];
    begin
        GetOrder(PurchHeader, orderNo);
        if vendorInvoiceNo = '' then
            Error('Falta el N.º de factura del proveedor.');
        if not JArr.ReadFrom(linesJson) then
            Error('No se pudieron leer las líneas (JSON inválido).');

        // Encabezado: solo Facturar (sin recibir de nuevo).
        PurchHeader.Validate("Vendor Invoice No.", vendorInvoiceNo);
        PurchHeader."Posting Date" := Today();
        PurchHeader.Receive := false;
        PurchHeader.Invoice := true;
        PurchHeader.Modify(true);

        // Reset: nada a recibir/facturar hasta asignar lo de esta factura.
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", orderNo);
        if PurchLine.FindSet() then
            repeat
                if (PurchLine."Qty. to Receive" <> 0) or (PurchLine."Qty. to Invoice" <> 0) then begin
                    PurchLine.Validate("Qty. to Receive", 0);
                    PurchLine.Validate("Qty. to Invoice", 0);
                    PurchLine.Modify(true);
                end;
            until PurchLine.Next() = 0;

        // Asignar la cantidad a facturar por línea, SOLO sobre lo recibido no facturado.
        foreach JTok in JArr do begin
            JObj := JTok.AsObject();
            if JObj.Get('itemNo', v) then itm := CopyStr(v.AsValue().AsText(), 1, MaxStrLen(itm)) else itm := '';
            qty := 0;
            if JObj.Get('qty', v) then qty := v.AsValue().AsDecimal();
            // Variante opcional: si viene en el JSON, se usa para desambiguar cuando el
            // mismo ítem aparece en varias líneas con distinta variante.
            variantCode := '';
            applyVariant := false;
            if JObj.Get('variantCode', v) then
                if not v.AsValue().IsNull() then begin
                    variantCode := CopyStr(v.AsValue().AsText(), 1, MaxStrLen(variantCode));
                    applyVariant := true;
                end;
            if (itm <> '') and (qty > 0) then begin
                PurchLine.Reset();
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange("Document No.", orderNo);
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                PurchLine.SetRange("No.", itm);
                if applyVariant then
                    PurchLine.SetRange("Variant Code", variantCode);
                PurchLine.SetFilter("Qty. Rcd. Not Invoiced", '>0');
                PurchLine.SetRange("Qty. to Invoice", 0);
                if PurchLine.FindFirst() then begin
                    PurchLine.Validate("Qty. to Receive", 0); // no recibir de nuevo
                    PurchLine.Validate("Qty. to Invoice", qty);
                    PurchLine.Modify(true);
                end;
            end;
        end;

        // Facturar el cargo de producto ya recibido: conserva la asignación creada en la
        // recepción y solo ajusta la cantidad a facturar (o la crea si no existiera).
        AsignarCargosProducto(PurchHeader, true, MenuTextForMethod(''));

        PurchPost.Run(PurchHeader);
        postedNo := PurchHeader."Last Posting No.";
        if postedNo = '' then
            postedNo := vendorInvoiceNo;
        exit(postedNo);
    end;

    /// <summary>
    /// Sugerir asignación de los cargos de producto (flete, etc.) POR IMPORTE sobre el pedido
    /// ABIERTO, distribuyendo entre todas sus líneas de artículo (equivale a la acción estándar
    /// "Asignación cargos prod. → Sugerir asignación → Por importe"). Idempotente: no
    /// sobrescribe una asignación ya existente. Devuelve 'OK'. (Igual se auto-asigna al
    /// registrar; esta acción permite dispararlo antes desde la app.)
    /// </summary>
    procedure AssignItemCharges(orderNo: Code[20]; metodo: Text): Text
    var
        PurchHeader: Record "Purchase Header";
    begin
        GetOrder(PurchHeader, orderNo);
        AsignarCargosProducto(PurchHeader, false, MenuTextForMethod(metodo));
        exit('OK');
    end;

    /// <summary>
    /// Devuelve el "menu text" del método de asignación de cargo para "Item Charge Assgnt.
    /// (Purch.)". metodo: Equally | Amount | Weight | Volume. Vacío o desconocido => Amount
    /// (por importe, el default). Ojo: Weight/Volume solo reparten si los ítems tienen
    /// Gross Weight / Unit Volume en su ficha.
    /// </summary>
    local procedure MenuTextForMethod(metodo: Text): Text
    var
        ItemChargeMgt: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        case UpperCase(metodo) of
            'EQUALLY':
                exit(ItemChargeMgt.AssignEquallyMenuText());
            'WEIGHT':
                exit(ItemChargeMgt.AssignByWeightMenuText());
            'VOLUME':
                exit(ItemChargeMgt.AssignByVolumeMenuText());
            else
                exit(ItemChargeMgt.AssignByAmountMenuText());
        end;
    end;

    /// <summary>
    /// Registra un cargo de producto (flete de un tercero) sobre líneas de recepciones YA
    /// registradas. Crea un pedido al proveedor del cargo con una única línea "Cargo (Prod.)",
    /// asigna ese cargo a las líneas de recepción indicadas (Applies-to = Receipt), reparte con
    /// el método dado (Amount por defecto) y registra la factura. Devuelve el N.º de factura.
    /// receiptLinesJson = [{"documentNo":"CR-000003","lineNo":10000}, ...].
    /// NOTA: es distinto del cargo del propio pedido (que asigna a líneas del mismo pedido).
    /// </summary>
    procedure PostChargeOnReceipts(chargeVendorNo: Code[20]; itemChargeNo: Code[20]; chargeAmount: Decimal; vendorInvoiceNo: Code[35]; metodo: Text; receiptLinesJson: Text): Text
    var
        PurchHeader: Record "Purchase Header";
        ChargeLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgnt: Record "Item Charge Assignment (Purch)";
        ItemChargeMgt: Codeunit "Item Charge Assgnt. (Purch.)";
        PurchPost: Codeunit "Purch.-Post";
        JArr: JsonArray;
        JTok: JsonToken;
        JObj: JsonObject;
        v: JsonToken;
        docNo: Code[20];
        rcptLineNo: Integer;
        assignLineNo: Integer;
        assigned: Integer;
        postedNo: Code[20];
    begin
        if chargeVendorNo = '' then
            Error('Falta el proveedor del cargo.');
        if itemChargeNo = '' then
            Error('Falta el cargo de producto (Item Charge).');
        if vendorInvoiceNo = '' then
            Error('Falta el N.º de factura del proveedor.');
        if chargeAmount <= 0 then
            Error('El importe del cargo debe ser mayor a cero.');
        if not JArr.ReadFrom(receiptLinesJson) then
            Error('No se pudieron leer las líneas de recepción (JSON inválido).');

        // 1) Pedido al proveedor del cargo.
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", chargeVendorNo);
        PurchHeader.Validate("Vendor Invoice No.", vendorInvoiceNo);
        PurchHeader."Posting Date" := Today();
        PurchHeader.Modify(true);

        // 2) Única línea de cargo (Charge (Item)).
        ChargeLine.Init();
        ChargeLine."Document Type" := PurchHeader."Document Type";
        ChargeLine."Document No." := PurchHeader."No.";
        ChargeLine."Line No." := 10000;
        ChargeLine.Insert(true);
        ChargeLine.Validate(Type, ChargeLine.Type::"Charge (Item)");
        ChargeLine.Validate("No.", itemChargeNo);
        ChargeLine.Validate(Quantity, 1);
        ChargeLine.Validate("Direct Unit Cost", chargeAmount);
        ChargeLine.Modify(true);

        // 3) Asignar el cargo a cada línea de recepción indicada (Applies-to = Receipt).
        assignLineNo := 0;
        assigned := 0;
        foreach JTok in JArr do begin
            JObj := JTok.AsObject();
            docNo := '';
            if JObj.Get('documentNo', v) then
                docNo := CopyStr(v.AsValue().AsText(), 1, MaxStrLen(docNo));
            rcptLineNo := 0;
            if JObj.Get('lineNo', v) then
                rcptLineNo := v.AsValue().AsInteger();
            if (docNo <> '') and (rcptLineNo <> 0) and PurchRcptLine.Get(docNo, rcptLineNo) then begin
                assignLineNo += 10000;
                ItemChargeAssgnt.Init();
                ItemChargeAssgnt."Document Type" := ChargeLine."Document Type";
                ItemChargeAssgnt."Document No." := ChargeLine."Document No.";
                ItemChargeAssgnt."Document Line No." := ChargeLine."Line No.";
                ItemChargeAssgnt."Line No." := assignLineNo;
                ItemChargeAssgnt."Item Charge No." := ChargeLine."No.";
                ItemChargeAssgnt."Applies-to Doc. Type" := ItemChargeAssgnt."Applies-to Doc. Type"::Receipt;
                ItemChargeAssgnt."Applies-to Doc. No." := PurchRcptLine."Document No.";
                ItemChargeAssgnt."Applies-to Doc. Line No." := PurchRcptLine."Line No.";
                ItemChargeAssgnt."Item No." := PurchRcptLine."No.";
                ItemChargeAssgnt.Description := PurchRcptLine.Description;
                ItemChargeAssgnt."Unit Cost" := ChargeLine."Direct Unit Cost";
                ItemChargeAssgnt.Insert(true);
                assigned += 1;
            end;
        end;
        if assigned = 0 then
            Error('No se encontró ninguna línea de recepción válida para asignar el cargo.');

        // 4) Distribuir el cargo con el método indicado (default por importe).
        ItemChargeMgt.AssignItemCharges(ChargeLine, ChargeLine.Quantity, ChargeLine."Line Amount", MenuTextForMethod(metodo));

        // 5) Recibir + Facturar el cargo y registrar.
        ChargeLine.Find();
        ChargeLine.Validate("Qty. to Receive", ChargeLine.Quantity);
        ChargeLine.Validate("Qty. to Invoice", ChargeLine.Quantity);
        ChargeLine.Modify(true);

        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchHeader.Modify(true);

        PurchPost.Run(PurchHeader);
        postedNo := PurchHeader."Last Posting No.";
        if postedNo = '' then
            postedNo := vendorInvoiceNo;
        exit(postedNo);
    end;

    local procedure GetOrder(var PurchHeader: Record "Purchase Header"; orderNo: Code[20])
    begin
        PurchHeader.Reset();
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetRange("No.", orderNo);
        if not PurchHeader.FindFirst() then
            Error('Pedido de compra %1 no encontrado en BC.', orderNo);
    end;

    local procedure StatusText(orderNo: Code[20]): Text
    var
        PurchHeader: Record "Purchase Header";
    begin
        GetOrder(PurchHeader, orderNo);
        exit(Format(PurchHeader.Status));
    end;

    // ════════════════════════════════════════════════════════════════════════════════
    //  Cargos de producto (Item Charges) — auto-asignación del flete
    //  ─────────────────────────────────────────────────────────────────────────────
    //  El flete llega como una línea Type = "Charge (Item)" que crea la app al aprobar.
    //  Un cargo con cantidad a recibir/facturar SIN asignar bloquea el registro con
    //  "Debe asignar el cargo de producto ...". Estas rutinas replican la acción estándar
    //  "Sugerir asignación de cargo → Por importe" (codeunit 5805 "Item Charge Assgnt.
    //  (Purch.)"): reparten el cargo, ponderado por el importe de línea, entre las líneas
    //  de artículo que se reciben/facturan en el mismo registro.
    //
    //  Política: el cargo se tramita al 100% en el registro que lo asigna (recibe todo su
    //  pendiente), y se distribuye SOLO entre los artículos en proceso en ese registro:
    //    - PostInvoice  (recibir+facturar): reparte entre las líneas que se reciben ahora.
    //    - PostReceipt  (solo recibir):     recibe el cargo y lo reparte entre lo recibido;
    //                                       la factura posterior conserva la asignación.
    //    - PostInvoiceOfReceived (solo facturar): conserva la asignación de la recepción.
    //    - ReleaseOrder (lanzar):           best-effort, reparte entre todas las líneas.
    // ════════════════════════════════════════════════════════════════════════════════

    /// <summary>
    /// Asigna todas las líneas de cargo (Charge (Item)) del pedido.
    /// EnRegistro=true: ajusta las cantidades a recibir/facturar del cargo según el modo del
    /// encabezado (Receive/Invoice) y distribuye por importe entre las líneas de artículo en
    /// proceso en este registro. EnRegistro=false (lanzamiento): distribuye entre todas las
    /// líneas de artículo del documento, sin tocar cantidades y sin sobrescribir asignaciones
    /// ya existentes.
    /// </summary>
    local procedure AsignarCargosProducto(var PurchHeader: Record "Purchase Header"; EnRegistro: Boolean; metodoMenuText: Text)
    var
        ChargeLine: Record "Purchase Line";
        LineNos: List of [Integer];
        LineNo: Integer;
    begin
        ChargeLine.SetRange("Document Type", PurchHeader."Document Type");
        ChargeLine.SetRange("Document No.", PurchHeader."No.");
        ChargeLine.SetRange(Type, ChargeLine.Type::"Charge (Item)");
        ChargeLine.SetFilter(Quantity, '<>0');
        if ChargeLine.FindSet() then
            repeat
                LineNos.Add(ChargeLine."Line No.");
            until ChargeLine.Next() = 0;

        // Se recorre por número de línea (no sobre el propio FindSet) porque cada iteración
        // modifica la línea de cargo y la tabla de asignación.
        foreach LineNo in LineNos do
            ProcesarCargo(PurchHeader, LineNo, EnRegistro, metodoMenuText);
    end;

    [TryFunction]
    local procedure TryAsignarCargosEnLanzamiento(var PurchHeader: Record "Purchase Header")
    begin
        AsignarCargosProducto(PurchHeader, false, MenuTextForMethod(''));
    end;

    local procedure ProcesarCargo(var PurchHeader: Record "Purchase Header"; ChargeLineNo: Integer; EnRegistro: Boolean; metodoMenuText: Text)
    var
        ChargeLine: Record "Purchase Line";
        QtyPend: Decimal;
    begin
        ChargeLine.Get(PurchHeader."Document Type", PurchHeader."No.", ChargeLineNo);
        if ChargeLine.Type <> ChargeLine.Type::"Charge (Item)" then
            exit;
        if ChargeLine.Quantity = 0 then
            exit;

        if not EnRegistro then begin
            // Lanzamiento: asignar entre todas las líneas de artículo si aún no está asignado
            // (no se sobrescribe una asignación manual previa).
            if not AsignacionExiste(ChargeLine) then
                ConstruirAsignacion(ChargeLine, false, false, metodoMenuText);
            exit;
        end;

        // ── En registro: fijar la cantidad del cargo según el modo del encabezado. ──
        if PurchHeader.Receive then begin
            QtyPend := ChargeLine."Outstanding Quantity";
            ChargeLine.Validate("Qty. to Receive", QtyPend);
            if PurchHeader.Invoice then
                ChargeLine.Validate("Qty. to Invoice", QtyPend)
            else
                ChargeLine.Validate("Qty. to Invoice", 0);
        end else begin
            ChargeLine.Validate("Qty. to Receive", 0);
            if PurchHeader.Invoice then
                ChargeLine.Validate("Qty. to Invoice", ChargeLine."Qty. Rcd. Not Invoiced")
            else
                ChargeLine.Validate("Qty. to Invoice", 0);
        end;
        ChargeLine.Modify(true);

        if PurchHeader.Receive then
            // Recibiendo (con o sin factura): (re)distribuir sobre las líneas que se reciben ahora.
            ConstruirAsignacion(ChargeLine, true, true, metodoMenuText)
        else
            // Solo factura de lo ya recibido: conservar la asignación creada en la recepción
            // (Validate("Qty. to Invoice") ya rebalanceó lo "a tramitar"). Crearla si faltara.
            if not AsignacionExiste(ChargeLine) then
                ConstruirAsignacion(ChargeLine, true, false, metodoMenuText);
    end;

    /// <summary>
    /// Construye la asignación de una línea de cargo distribuyéndola POR IMPORTE.
    /// SoloEnProceso=true poda las líneas destino a las que se reciben (PorRecepcion=true)
    /// o se facturan (PorRecepcion=false) en este registro; false asigna a todas las líneas
    /// de artículo del documento.
    /// </summary>
    local procedure ConstruirAsignacion(var ChargeLine: Record "Purchase Line"; SoloEnProceso: Boolean; PorRecepcion: Boolean; metodoMenuText: Text)
    var
        ItemChargeAssgnt: Record "Item Charge Assignment (Purch)";
        TargetLine: Record "Purchase Line";
        ItemChargeMgt: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // 1) Limpiar la asignación previa de esta línea de cargo.
        BorrarAsignacion(ChargeLine);

        // 2) Crear candidatos para todas las líneas de artículo del documento (Applies-to = Order).
        ItemChargeAssgnt.Init();
        ItemChargeAssgnt."Document Type" := ChargeLine."Document Type";
        ItemChargeAssgnt."Document No." := ChargeLine."Document No.";
        ItemChargeAssgnt."Document Line No." := ChargeLine."Line No.";
        ItemChargeAssgnt."Item Charge No." := ChargeLine."No.";
        ItemChargeAssgnt."Unit Cost" := ChargeLine."Direct Unit Cost";
        ItemChargeMgt.CreateDocChargeAssgnt(ItemChargeAssgnt, '');

        // 3) Podar los candidatos que no están en proceso en este registro.
        if SoloEnProceso then begin
            ItemChargeAssgnt.Reset();
            ItemChargeAssgnt.SetRange("Document Type", ChargeLine."Document Type");
            ItemChargeAssgnt.SetRange("Document No.", ChargeLine."Document No.");
            ItemChargeAssgnt.SetRange("Document Line No.", ChargeLine."Line No.");
            ItemChargeAssgnt.SetRange("Applies-to Doc. Type", ItemChargeAssgnt."Applies-to Doc. Type"::Order);
            if ItemChargeAssgnt.FindSet() then
                repeat
                    if TargetLine.Get(ChargeLine."Document Type", ItemChargeAssgnt."Applies-to Doc. No.", ItemChargeAssgnt."Applies-to Doc. Line No.") then begin
                        if not LineaEnProceso(TargetLine, PorRecepcion) then
                            ItemChargeAssgnt.Delete();
                    end else
                        ItemChargeAssgnt.Delete();
                until ItemChargeAssgnt.Next() = 0;
        end;

        // 4) Debe quedar al menos una línea destino.
        if not AsignacionExiste(ChargeLine) then
            Error(
              'No hay líneas de artículo en proceso a las que asignar el cargo de producto "%1" del pedido %2. ' +
              'Recibí o factura al menos un artículo junto con el cargo.',
              ChargeLine."No.", ChargeLine."Document No.");

        // 5) Distribuir con el método indicado (default Por importe).
        ItemChargeMgt.AssignItemCharges(
          ChargeLine, ChargeLine.Quantity, ChargeLine."Line Amount", metodoMenuText);
    end;

    local procedure LineaEnProceso(TargetLine: Record "Purchase Line"; PorRecepcion: Boolean): Boolean
    begin
        if TargetLine.Type <> TargetLine.Type::Item then
            exit(false);
        if PorRecepcion then
            exit(TargetLine."Qty. to Receive" > 0);
        exit(TargetLine."Qty. to Invoice" > 0);
    end;

    local procedure AsignacionExiste(var ChargeLine: Record "Purchase Line"): Boolean
    var
        ItemChargeAssgnt: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssgnt.SetRange("Document Type", ChargeLine."Document Type");
        ItemChargeAssgnt.SetRange("Document No.", ChargeLine."Document No.");
        ItemChargeAssgnt.SetRange("Document Line No.", ChargeLine."Line No.");
        exit(not ItemChargeAssgnt.IsEmpty());
    end;

    local procedure BorrarAsignacion(var ChargeLine: Record "Purchase Line")
    var
        ItemChargeAssgnt: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssgnt.SetRange("Document Type", ChargeLine."Document Type");
        ItemChargeAssgnt.SetRange("Document No.", ChargeLine."Document No.");
        ItemChargeAssgnt.SetRange("Document Line No.", ChargeLine."Line No.");
        ItemChargeAssgnt.DeleteAll();
    end;
}
