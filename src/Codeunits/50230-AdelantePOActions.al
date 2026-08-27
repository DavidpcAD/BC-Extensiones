// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50230 "Adelante PO Actions"
// Propósito: Acciones sobre Pedidos de Compra que la API estándar v2.0 NO permite
//            por escritura directa (el campo Status es read-only / sistema).
//            Se exponen como Web Service OData ("AdelantePO") para que la app de
//            Compras las invoque por S2S al aprobar/reabrir una orden.
//
//   - SendForApproval(orderNo)       ->  OnSendPurchaseDocForApproval -> "Pendiente de aprobación"
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
        //    OJO: acá NO se usa ApproveRecordApprovalRequest. Ese aprueba solo las entradas
        //    asignadas al USUARIO CONECTADO, y la app entra por S2S como
        //    BUSINESSCENTRAL_API_ADELANTE mientras las solicitudes salen a nombre del aprobador
        //    de verdad (LUISROBERTO): buscaba una entrada suya, no la encontraba y tiraba
        //    "There is no approval request to approve" (caso del 20/08/2026, con el workflow
        //    MS-POAPW activo). ApproveApprovalRequests aprueba las entradas que uno le pasa
        //    filtradas, sea de quien sea; BC exige para eso que el usuario conectado esté en
        //    Configuración de usuarios con "Administrador de aprobaciones". Quién aprobó de
        //    verdad queda en el historial de la app de Producción.
        for guard := 1 to 20 do begin
            ApprovalEntry.Reset();
            ApprovalEntry.SetRange("Table ID", Database::"Purchase Header");
            ApprovalEntry.SetRange("Document Type", ApprovalEntry."Document Type"::Order);
            ApprovalEntry.SetRange("Document No.", orderNo);
            ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
            if not ApprovalEntry.FindSet() then
                break;
            ApprovalsMgmt.ApproveApprovalRequests(ApprovalEntry);
        end;

        // 3) Si el workflow no lo liberó automáticamente, lanzarlo manualmente.
        PurchHeader.Find();
        if PurchHeader.Status = PurchHeader.Status::Open then
            ReleasePurchDoc.PerformManualRelease(PurchHeader);

        exit(StatusText(orderNo));
    end;

    /// <summary>
    /// Manda el pedido a APROBACIÓN en BC, sin aprobarlo ni lanzarlo: dispara el workflow
    /// (MS-POAPW-01 / MS-POAPW-02) y el documento queda "Pendiente de aprobación" con su
    /// solicitud abierta, así quien mira BC ve qué está esperando visto bueno. Lo llama
    /// Proveeduría al enviar la orden a aprobación; el "Aprobar y lanzar" de la app usa
    /// después ReleaseOrder, que aprueba esa solicitud y libera.
    /// Idempotente y tolerante: si el pedido ya está esperando aprobación no hace nada, y si
    /// no hay workflow activo para ese documento tampoco (lo deja Abierto y ReleaseOrder lo
    /// lanzará derecho). Devuelve el estado resultante.
    /// </summary>
    procedure SendForApproval(orderNo: Code[20]): Text
    var
        PurchHeader: Record "Purchase Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        GetOrder(PurchHeader, orderNo);

        // Ya está esperando aprobación: no se manda otra solicitud.
        if ApprovalsMgmt.IsPurchaseHeaderPendingApproval(PurchHeader) then
            exit(StatusText(orderNo));

        // Solo desde Abierto: si ya está Lanzado no hay nada que aprobar.
        if PurchHeader.Status <> PurchHeader.Status::Open then
            exit(StatusText(orderNo));

        // Sin workflow activo para este documento (p. ej. un almacén que no cae en las
        // condiciones de MS-POAPW-01/02) se queda Abierto: no es un error.
        if not ApprovalsMgmt.IsPurchaseApprovalsWorkflowEnabled(PurchHeader) then
            exit(StatusText(orderNo));

        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);
        exit(StatusText(orderNo));
    end;

    /// <summary>
    /// Reabre (Reopen) un pedido de compra, dejándolo en Abierto para poder editarlo.
    /// Si está esperando aprobación, primero CANCELA la solicitud: BC no deja reabrir un
    /// documento con aprobación viva ("The approval process must be cancelled or completed
    /// to reopen this document." — Release Purchase Document.PerformManualReopen). Es el
    /// ciclo normal de la app: lanzado/pendiente -> reabrir -> editar líneas -> volver a
    /// mandar a aprobación (ReleaseOrder), y ese ciclo se repite sobre el mismo pedido.
    /// </summary>
    procedure ReopenOrder(orderNo: Code[20]): Text
    var
        PurchHeader: Record "Purchase Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        GetOrder(PurchHeader, orderNo);

        // Cancelar la solicitud de aprobación abierta (si la hay) antes de reabrir.
        // Cancelar dispara la respuesta del workflow que ya deja el documento en Abierto,
        // por eso se relee antes del Reopen y este queda como red de seguridad.
        if ApprovalsMgmt.IsPurchaseHeaderPendingApproval(PurchHeader) then
            ApprovalsMgmt.OnCancelPurchaseApprovalRequest(PurchHeader);

        PurchHeader.Find();
        if PurchHeader.Status <> PurchHeader.Status::Open then
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
    procedure PostInvoice(orderNo: Code[20]; vendorInvoiceNo: Code[35]; linesJson: Text; postingDate: Date): Text
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
        PrepararFechaRegistro(PurchHeader, postingDate);
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
    procedure PostReceipt(orderNo: Code[20]; linesJson: Text; postingDate: Date): Text
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
        PrepararFechaRegistro(PurchHeader, postingDate);
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
    procedure PostInvoiceOfReceived(orderNo: Code[20]; vendorInvoiceNo: Code[35]; linesJson: Text; postingDate: Date): Text
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
        PrepararFechaRegistro(PurchHeader, postingDate);
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
    procedure PostChargeOnReceipts(chargeVendorNo: Code[20]; itemChargeNo: Code[20]; chargeAmount: Decimal; vendorInvoiceNo: Code[35]; metodo: Text; receiptLinesJson: Text; postingDate: Date): Text
    var
        PurchHeader: Record "Purchase Header";
        ChargeLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgnt: Record "Item Charge Assignment (Purch)";
        PurchPost: Codeunit "Purch.-Post";
        JArr: JsonArray;
        JTok: JsonToken;
        JObj: JsonObject;
        v: JsonToken;
        docNos: List of [Text];
        lineNos: List of [Integer];
        weights: List of [Decimal];
        docNo: Code[20];
        rcptLineNo: Integer;
        assignLineNo: Integer;
        i: Integer;
        metodoUp: Text;
        totalWeight: Decimal;
        qtyToAssign: Decimal;
        asignadoAcum: Decimal;
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
        if postingDate = 0D then
            postingDate := Today();
        PurchHeader.Validate("Posting Date", postingDate);
        PurchHeader.Validate("Document Date", postingDate);
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

        // 3) Recolectar las líneas de recepción válidas y su "peso" según el método.
        metodoUp := UpperCase(metodo);
        totalWeight := 0;
        foreach JTok in JArr do begin
            JObj := JTok.AsObject();
            docNo := '';
            if JObj.Get('documentNo', v) then
                docNo := CopyStr(v.AsValue().AsText(), 1, MaxStrLen(docNo));
            rcptLineNo := 0;
            if JObj.Get('lineNo', v) then
                rcptLineNo := v.AsValue().AsInteger();
            if (docNo <> '') and (rcptLineNo <> 0) and PurchRcptLine.Get(docNo, rcptLineNo) then begin
                docNos.Add(docNo);
                lineNos.Add(rcptLineNo);
                weights.Add(PesoReparto(metodoUp, PurchRcptLine));
            end;
        end;
        if docNos.Count = 0 then
            Error('No se encontró ninguna línea de recepción válida para asignar el cargo.');

        for i := 1 to weights.Count do
            totalWeight += weights.Get(i);
        // Sin base para el método (ej. sin peso/volumen cargados) -> partes iguales.
        if totalWeight <= 0 then begin
            for i := 1 to weights.Count do
                weights.Set(i, 1);
            totalWeight := weights.Count;
        end;

        // 4) Insertar la asignación distribuyendo la cantidad del cargo (=1) por peso, y
        //    seteando Qty. to Assign a mano para que sume exacto y quede totalmente asignado
        //    (AssignItemCharges no reparte sobre filas apuntadas a recepciones a mano).
        assignLineNo := 0;
        asignadoAcum := 0;
        for i := 1 to docNos.Count do begin
            PurchRcptLine.Get(docNos.Get(i), lineNos.Get(i));
            if i < docNos.Count then
                qtyToAssign := Round(weights.Get(i) / totalWeight, 0.00001)
            else
                qtyToAssign := 1 - asignadoAcum; // el último toma el remanente exacto
            asignadoAcum += qtyToAssign;

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
            ItemChargeAssgnt.Validate("Qty. to Assign", qtyToAssign);
            ItemChargeAssgnt.Modify(true);
        end;

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

    /// <summary>Peso de reparto de un cargo sobre una línea de recepción, según el método.</summary>
    local procedure PesoReparto(metodoUp: Text; PurchRcptLine: Record "Purch. Rcpt. Line"): Decimal
    begin
        case metodoUp of
            'EQUALLY':
                exit(1);
            'WEIGHT':
                exit(PurchRcptLine.Quantity * PurchRcptLine."Gross Weight");
            'VOLUME':
                exit(PurchRcptLine.Quantity * PurchRcptLine."Unit Volume");
            else
                exit(PurchRcptLine.Quantity * PurchRcptLine."Direct Unit Cost"); // por importe (default)
        end;
    end;

    /// <summary>
    /// Agrega (o actualiza) una línea de Cargo (Prod.) sobre un pedido ABIERTO. Se expone
    /// porque la API estándar purchaseOrderLines no crea confiablemente las líneas de tipo
    /// "Charge (Item)". Idempotente por itemChargeNo: si ya hay una línea de ese cargo en el
    /// pedido, actualiza su cantidad/precio en vez de duplicar. Devuelve el N.º de línea.
    /// El reparto del cargo se hace solo al lanzar/registrar (AsignarCargosProducto).
    /// </summary>
    procedure AddChargeLine(orderNo: Code[20]; itemChargeNo: Code[20]; description: Text[100]; quantity: Decimal; directUnitCost: Decimal): Text
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        lastLineNo: Integer;
    begin
        GetOrder(PurchHeader, orderNo);
        if itemChargeNo = '' then
            Error('Falta el cargo de producto (Item Charge).');
        if quantity <= 0 then
            Error('La cantidad del cargo debe ser mayor a cero.');

        // Idempotencia: si ya existe una línea de ese cargo, actualizarla.
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, PurchLine.Type::"Charge (Item)");
        PurchLine.SetRange("No.", itemChargeNo);
        if PurchLine.FindFirst() then begin
            PurchLine.Validate(Quantity, quantity);
            PurchLine.Validate("Direct Unit Cost", directUnitCost);
            if description <> '' then
                PurchLine.Validate(Description, CopyStr(description, 1, MaxStrLen(PurchLine.Description)));
            PurchLine.Modify(true);
            exit(Format(PurchLine."Line No."));
        end;

        // Siguiente N.º de línea.
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindLast() then
            lastLineNo := PurchLine."Line No.";
        lastLineNo += 10000;

        PurchLine.Init();
        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := lastLineNo;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, PurchLine.Type::"Charge (Item)");
        PurchLine.Validate("No.", itemChargeNo);
        if description <> '' then
            PurchLine.Validate(Description, CopyStr(description, 1, MaxStrLen(PurchLine.Description)));
        PurchLine.Validate(Quantity, quantity);
        PurchLine.Validate("Direct Unit Cost", directUnitCost);
        PurchLine.Modify(true);
        exit(Format(lastLineNo));
    end;

    /// <summary>
    /// Reemplaza TODAS las líneas de un pedido de compra ABIERTO con las que vienen en
    /// linesJson, en una sola transacción (todo o nada). Se usa cuando la app corrige un
    /// pedido reabierto (ReopenOrder → editar → ReplaceOrderLines) para que Bodega y
    /// Contabilidad reciban/facturen contra las cantidades y el costo correctos, no los viejos.
    ///
    /// linesJson = { "lines": [
    ///   { "type":"Item", "itemNo":"M01-0147", "variantCode":"", "locationCode":"ALM-GRAL",
    ///     "quantity":6, "directUnitCost":1100, "lineDiscountPct":0, "jobNo":"VB-5.01", "taskNo":"1000" },
    ///   { "type":"Charge", "itemChargeNo":"FLETE", "description":"FLETE / TRANSPORTE",
    ///     "quantity":1, "directUnitCost":45000, "chargeMethod":"Amount" }
    /// ] }
    ///
    /// Guardas server-side (no dependen de la UI de la app):
    ///  · El pedido debe estar ABIERTO. Si está Lanzado u otro estado -> Error claro, sin reemplazo.
    ///  · Falla si hay recepciones registradas o alguna línea con cantidad ya recibida.
    ///  · Todo o nada: cualquier línea inválida lanza Error y revierte TODO (no queda a medias).
    ///  · Excepción a lo anterior: los códigos que solo son "decoración" de la línea (unidad de
    ///    medida, obra, tarea) se aplican únicamente si existen en BC. Un código inexistente ahí
    ///    no tumba el pedido entero: se crea la línea sin ese dato y se reporta en "Avisos".
    ///  · El "Direct Unit Cost" del JSON se valida al final, para que gane sobre el costo del maestro.
    /// El reparto del cargo (Item Charge) se hace al lanzar/registrar (AsignarCargosProducto),
    /// igual que en el resto del flujo; aquí solo se (re)crea la línea del cargo. "chargeMethod"
    /// se acepta pero se aplica en ese momento posterior. Las líneas con cantidad 0 o negativa se
    /// omiten y se reportan. Devuelve un texto con creadas / eliminadas / omitidas.
    /// </summary>
    procedure ReplaceOrderLines(orderNo: Code[20]; linesJson: Text): Text
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        RootObj: JsonObject;
        LinesTok: JsonToken;
        LinesArr: JsonArray;
        JTok: JsonToken;
        JObj: JsonObject;
        v: JsonToken;
        lineType: Text;
        deletedCount: Integer;
        itemCount: Integer;
        chargeCount: Integer;
        skippedCount: Integer;
        skippedMsg: Text;
        warnMsg: Text;
        idx: Integer;
        lastLineNo: Integer;
    begin
        GetOrder(PurchHeader, orderNo);

        // Guard 1: el pedido debe estar ABIERTO (nunca reemplazar sobre un Lanzado).
        if PurchHeader.Status <> PurchHeader.Status::Open then
            Error('El pedido %1 debe estar Abierto para reescribir líneas. Estado actual: %2. Reábrelo primero (AdelantePO_ReopenOrder).',
                orderNo, PurchHeader.Status);

        // Guard 2: no debe tener recepciones registradas ni cantidades ya recibidas.
        PurchRcptLine.SetRange("Order No.", orderNo);
        if not PurchRcptLine.IsEmpty() then
            Error('El pedido %1 tiene recepciones registradas. No se pueden reescribir sus líneas.', orderNo);

        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", orderNo);
        PurchLine.SetFilter("Quantity Received", '<>0');
        if not PurchLine.IsEmpty() then
            Error('El pedido %1 tiene líneas con cantidad ya recibida. No se pueden reescribir.', orderNo);

        // Parseo del JSON: objeto con arreglo "lines".
        if not RootObj.ReadFrom(linesJson) then
            Error('JSON inválido en linesJson.');
        if not RootObj.Get('lines', LinesTok) then
            Error('Falta el arreglo "lines" en linesJson.');
        if not LinesTok.IsArray() then
            Error('"lines" debe ser un arreglo.');
        LinesArr := LinesTok.AsArray();
        if LinesArr.Count() = 0 then
            Error('"lines" está vacío: no se reescribió nada. Este procedure reemplaza con líneas nuevas.');

        // Borrar TODAS las líneas actuales (DeleteAll con trigger limpia asignaciones de cargo).
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", orderNo);
        deletedCount := PurchLine.Count();
        PurchLine.DeleteAll(true);

        // Crear las líneas nuevas. Cualquier fallo -> Error -> rollback total (todo o nada).
        lastLineNo := 0;
        idx := 0;
        foreach JTok in LinesArr do begin
            idx += 1;
            if not JTok.IsObject() then
                Error('Línea %1: se esperaba un objeto JSON.', idx);
            JObj := JTok.AsObject();

            lineType := '';
            if JObj.Get('type', v) then
                if not v.AsValue().IsNull() then
                    lineType := UpperCase(v.AsValue().AsText());

            lastLineNo += 10000;

            case lineType of
                'ITEM':
                    if InsertItemLine(orderNo, lastLineNo, JObj, idx, skippedMsg, warnMsg) then
                        itemCount += 1
                    else
                        skippedCount += 1;
                'CHARGE':
                    if InsertChargeLine(orderNo, lastLineNo, JObj, idx, skippedMsg) then
                        chargeCount += 1
                    else
                        skippedCount += 1;
                else
                    Error('Línea %1: "type" desconocido (''%2''). Use "Item" o "Charge".', idx, lineType);
            end;
        end;

        exit(StrSubstNo('Pedido %1 reescrito. Eliminadas %2 línea(s) previa(s); creadas %3 (%4 ítem, %5 cargo).%6%7',
            orderNo, deletedCount, itemCount + chargeCount, itemCount, chargeCount,
            SkippedText(skippedCount, skippedMsg), WarnText(warnMsg)));
    end;

    /// <summary>Crea una línea de artículo. Devuelve false y reporta si se omite (cantidad 0 o negativa);
    /// cualquier otro problema lanza Error para forzar el rollback total. En warnMsg acumula lo que
    /// se creó pero incompleto (obra o tarea inexistente), que se reporta sin abortar.</summary>
    local procedure InsertItemLine(orderNo: Code[20]; lineNo: Integer; JObj: JsonObject; idx: Integer; var skippedMsg: Text; var warnMsg: Text): Boolean
    var
        PurchLine: Record "Purchase Line";
        ItemUOM: Record "Item Unit of Measure";
        Job: Record Job;
        JobTask: Record "Job Task";
        v: JsonToken;
        itemNo: Code[20];
        uomCode: Code[10];
        variantCode: Code[10];
        locationCode: Code[10];
        jobNo: Code[20];
        taskNo: Code[20];
        qty: Decimal;
        directUnitCost: Decimal;
        lineDiscPct: Decimal;
        hasCost: Boolean;
    begin
        itemNo := CopyStr(GetJsonText(JObj, 'itemNo'), 1, MaxStrLen(itemNo));
        if itemNo = '' then
            Error('Línea %1 (Item): falta "itemNo".', idx);
        qty := GetJsonDec(JObj, 'quantity');
        if qty <= 0 then begin
            skippedMsg += StrSubstNo(' [Línea %1 (Item %2): quantity<=0]', idx, itemNo);
            exit(false);
        end;

        uomCode := CopyStr(GetJsonText(JObj, 'unitOfMeasureCode'), 1, MaxStrLen(uomCode));
        variantCode := CopyStr(GetJsonText(JObj, 'variantCode'), 1, MaxStrLen(variantCode));
        locationCode := CopyStr(GetJsonText(JObj, 'locationCode'), 1, MaxStrLen(locationCode));
        jobNo := CopyStr(GetJsonText(JObj, 'jobNo'), 1, MaxStrLen(jobNo));
        taskNo := CopyStr(GetJsonText(JObj, 'taskNo'), 1, MaxStrLen(taskNo));
        lineDiscPct := GetJsonDec(JObj, 'lineDiscountPct');
        hasCost := JObj.Get('directUnitCost', v);
        if hasCost then
            if v.AsValue().IsNull() then hasCost := false else directUnitCost := v.AsValue().AsDecimal();

        PurchLine.Init();
        PurchLine."Document Type" := PurchLine."Document Type"::Order;
        PurchLine."Document No." := orderNo;
        PurchLine."Line No." := lineNo;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", itemNo);
        // Unidad de medida: al validar el N.º, BC ya pone la de compra del ítem
        // (Item."Purch. Unit of Measure"). Si la app manda una explícita se respeta
        // — así cantidad y precio se interpretan en la MISMA unidad en que los
        // calculó la app (un estañón de adhesivo son 255.000 gramos).
        // Va ANTES de Quantity y Direct Unit Cost a propósito: cambiar la unidad
        // recalcula la conversión de cantidad y el costo del maestro.
        // Solo si el ítem tiene esa unidad registrada: una unidad inexistente haría
        // fallar la reescritura completa (es todo-o-nada) y es mejor quedarse con la
        // que BC ya puso que dejar el pedido con las líneas viejas.
        if (uomCode <> '') and (uomCode <> PurchLine."Unit of Measure Code") then
            if ItemUOM.Get(itemNo, uomCode) then
                PurchLine.Validate("Unit of Measure Code", uomCode);
        if variantCode <> '' then
            PurchLine.Validate("Variant Code", variantCode);
        if locationCode <> '' then
            PurchLine.Validate("Location Code", locationCode);
        PurchLine.Validate(Quantity, qty);
        // Obra y tarea: solo si existen en BC. Mismo criterio que la unidad de medida:
        // un código inexistente hace fallar la reescritura COMPLETA (es todo-o-nada) y deja
        // el pedido con las líneas viejas, que es peor que una línea sin obra — esta se
        // reporta en el resultado y se corrige después. Pasó de verdad: la app mandó un
        // código de almacén ('ALM-GRAL') en jobNo y tumbó el pedido entero.
        // La tarea va DESPUÉS de la obra y solo si la obra entró: validar "Job No." limpia
        // "Job Task No.", y BC tampoco acepta una tarea sin obra.
        // Ojo: aquí solo se comprueba que el código EXISTA. Si la obra existe pero BC la
        // rechaza por regla de negocio (bloqueada, cerrada, tarea que no es de posteo), se
        // deja fallar a propósito: eso el usuario tiene que verlo, no perder el centro de
        // costo en silencio.
        if jobNo = '' then begin
            if taskNo <> '' then
                warnMsg += StrSubstNo(' [Línea %1 (Item %2): tarea ''%3'' sin obra; se ignora]', idx, itemNo, taskNo);
        end else
            if not Job.Get(jobNo) then
                warnMsg += StrSubstNo(' [Línea %1 (Item %2): obra ''%3'' no existe en BC; línea creada sin obra]', idx, itemNo, jobNo)
            else begin
                PurchLine.Validate("Job No.", jobNo);
                if taskNo <> '' then
                    if JobTask.Get(jobNo, taskNo) then
                        PurchLine.Validate("Job Task No.", taskNo)
                    else
                        warnMsg += StrSubstNo(' [Línea %1 (Item %2): tarea ''%3'' no existe en la obra %4; línea creada sin tarea]', idx, itemNo, taskNo, jobNo);
            end;
        if lineDiscPct <> 0 then
            PurchLine.Validate("Line Discount %", lineDiscPct);
        if hasCost then
            PurchLine.Validate("Direct Unit Cost", directUnitCost); // al final: el costo negociado gana sobre el del maestro
        PurchLine.Modify(true);
        exit(true);
    end;

    /// <summary>Crea una línea de Cargo (Item Charge). Mismo patrón fiable que AddChargeLine.</summary>
    local procedure InsertChargeLine(orderNo: Code[20]; lineNo: Integer; JObj: JsonObject; idx: Integer; var skippedMsg: Text): Boolean
    var
        PurchLine: Record "Purchase Line";
        v: JsonToken;
        chargeNo: Code[20];
        description: Text[100];
        qty: Decimal;
        directUnitCost: Decimal;
        hasCost: Boolean;
    begin
        chargeNo := CopyStr(GetJsonText(JObj, 'itemChargeNo'), 1, MaxStrLen(chargeNo));
        if chargeNo = '' then
            Error('Línea %1 (Charge): falta "itemChargeNo".', idx);
        qty := GetJsonDec(JObj, 'quantity');
        if qty <= 0 then begin
            skippedMsg += StrSubstNo(' [Línea %1 (Charge %2): quantity<=0]', idx, chargeNo);
            exit(false);
        end;
        description := CopyStr(GetJsonText(JObj, 'description'), 1, MaxStrLen(description));
        hasCost := JObj.Get('directUnitCost', v);
        if hasCost then
            if v.AsValue().IsNull() then hasCost := false else directUnitCost := v.AsValue().AsDecimal();

        PurchLine.Init();
        PurchLine."Document Type" := PurchLine."Document Type"::Order;
        PurchLine."Document No." := orderNo;
        PurchLine."Line No." := lineNo;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, PurchLine.Type::"Charge (Item)");
        PurchLine.Validate("No.", chargeNo);
        if description <> '' then
            PurchLine.Validate(Description, description);
        PurchLine.Validate(Quantity, qty);
        if hasCost then
            PurchLine.Validate("Direct Unit Cost", directUnitCost);
        PurchLine.Modify(true);
        exit(true);
    end;

    local procedure GetJsonText(JObj: JsonObject; keyName: Text): Text
    var
        v: JsonToken;
    begin
        if JObj.Get(keyName, v) then
            if not v.AsValue().IsNull() then
                exit(v.AsValue().AsText());
        exit('');
    end;

    local procedure GetJsonDec(JObj: JsonObject; keyName: Text): Decimal
    var
        v: JsonToken;
    begin
        if JObj.Get(keyName, v) then
            if not v.AsValue().IsNull() then
                exit(v.AsValue().AsDecimal());
        exit(0);
    end;

    local procedure SkippedText(skippedCount: Integer; skippedMsg: Text): Text
    begin
        if skippedCount = 0 then
            exit('');
        exit(StrSubstNo(' Omitidas %1:%2', skippedCount, skippedMsg));
    end;

    /// <summary>Líneas que SÍ se crearon pero sin algún dato que venía mal en el JSON.
    /// Se devuelve en el mismo texto de resultado para que la app lo muestre.</summary>
    local procedure WarnText(warnMsg: Text): Text
    begin
        if warnMsg = '' then
            exit('');
        exit(StrSubstNo(' Avisos:%1', warnMsg));
    end;

    /// <summary>
    /// Setea, por línea de un pedido de compra, los campos que la API estándar purchaseOrderLines
    /// no expone: Job No. + Job Task No. (+ Job Line Type) para material de Consumo inmediato, y
    /// Location Code para material de Stock. La app crea las líneas con la API estándar y luego
    /// llama aquí, ANTES del Release. Identifica cada línea por "Line No." (el sequence estándar).
    ///
    /// assignmentsJson = [
    ///   { "lineNo":10000, "jobNo":"VN-B.24", "jobTaskNo":"1.2", "jobLineType":"Budget", "locationCode":"" },
    ///   { "lineNo":20000, "jobNo":"", "jobTaskNo":"", "locationCode":"ALM-GRAL" }
    /// ]
    ///  · jobLineType (opcional): Budget (default) | Billable | Both | None. Solo aplica si hay jobNo.
    ///  · Usa Validate en orden Job No. -> Job Task No. -> Job Line Type (dispara la lógica de BC:
    ///    proyecto abierto, tarea de posteo del proyecto, y arma las Job Planning Lines).
    ///  · Idempotente y NO tumba por línea: acumula el motivo real de BC en "errors" y sigue
    ///    (mismo criterio que AddChargeLine), para que la app avise sin abortar el lanzamiento.
    /// Devuelve JSON: { "updated": N, "errors": "..." }.
    /// </summary>
    procedure SetLineJob(orderNo: Code[20]; assignmentsJson: Text): Text
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Arr: JsonArray;
        Tok: JsonToken;
        Obj: JsonObject;
        ResultObj: JsonObject;
        v: JsonToken;
        lineNo: Integer;
        jobNo: Code[20];
        jobTaskNo: Code[20];
        jobLineTypeTxt: Text;
        locCode: Code[10];
        updated: Integer;
        errors: Text;
        resultTxt: Text;
    begin
        GetOrder(PurchHeader, orderNo);
        if not Arr.ReadFrom(assignmentsJson) then
            Error('assignmentsJson inválido (se espera un arreglo JSON).');

        foreach Tok in Arr do begin
            if not Tok.IsObject() then begin
                errors += 'Una entrada no es un objeto JSON. ';
            end else begin
                Obj := Tok.AsObject();
                lineNo := 0;
                if Obj.Get('lineNo', v) then
                    if not v.AsValue().IsNull() then
                        lineNo := v.AsValue().AsInteger();
                jobNo := CopyStr(GetJsonText(Obj, 'jobNo'), 1, MaxStrLen(jobNo));
                jobTaskNo := CopyStr(GetJsonText(Obj, 'jobTaskNo'), 1, MaxStrLen(jobTaskNo));
                jobLineTypeTxt := GetJsonText(Obj, 'jobLineType');
                locCode := CopyStr(GetJsonText(Obj, 'locationCode'), 1, MaxStrLen(locCode));

                if lineNo = 0 then
                    errors += 'Falta "lineNo" en una entrada. '
                else if not PurchLine.Get(PurchLine."Document Type"::Order, orderNo, lineNo) then
                    errors += StrSubstNo('Línea %1 no encontrada. ', lineNo)
                else if TrySetLine(orderNo, lineNo, jobNo, jobTaskNo, jobLineTypeTxt, locCode) then
                    updated += 1
                else
                    errors += StrSubstNo('Línea %1: %2 ', lineNo, GetLastErrorText());
            end;
        end;

        ResultObj.Add('updated', updated);
        ResultObj.Add('errors', errors);
        ResultObj.WriteTo(resultTxt);
        exit(resultTxt);
    end;

    /// <summary>Aplica los campos de una línea dentro de un TryFunction, para que un fallo de
    /// una línea (proyecto cerrado, tarea inválida, etc.) no tumbe el resto ni el lanzamiento.</summary>
    [TryFunction]
    local procedure TrySetLine(orderNo: Code[20]; lineNo: Integer; jobNo: Code[20]; jobTaskNo: Code[20]; jobLineTypeTxt: Text; locCode: Code[10])
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Get(PurchLine."Document Type"::Order, orderNo, lineNo);

        if jobNo <> '' then begin
            if PurchLine.Type <> PurchLine.Type::Item then
                Error('la línea no es de tipo Item; el proyecto solo aplica a artículos.');
            PurchLine.Validate("Job No.", jobNo);              // 1) proyecto primero
            PurchLine.Validate("Job Task No.", jobTaskNo);     // 2) luego la tarea
            case UpperCase(DelChr(jobLineTypeTxt, '<>', ' ')) of // 3) tipo de línea de proyecto
                'BILLABLE':
                    PurchLine.Validate("Job Line Type", PurchLine."Job Line Type"::Billable);
                'BOTH', 'BOTHBUDGETANDBILLABLE':
                    PurchLine.Validate("Job Line Type", PurchLine."Job Line Type"::"Both Budget and Billable");
                'NONE':
                    PurchLine.Validate("Job Line Type", PurchLine."Job Line Type"::" ");
                else // '' o 'BUDGET' -> default Budget (material consumido en obra)
                    PurchLine.Validate("Job Line Type", PurchLine."Job Line Type"::Budget);
            end;
        end;

        if locCode <> '' then
            PurchLine.Validate("Location Code", locCode);

        PurchLine.Modify(true);
    end;

    /// <summary>
    /// Prepara las fechas de registro (Posting Date / Document Date) del encabezado sin
    /// tumbar el registro en pedidos en moneda extranjera. Validar "Posting Date" con
    /// divisa recalcula el tipo de cambio y reescribe las líneas, lo que exige
    /// Status=Abierto: en un pedido Lanzado BC tira "Status must be equal to 'Open'"
    /// (era el error que la PWA parchaba con ReopenOrder + reintento). Por eso:
    ///  · Si la fecha no cambió, NO se revalida: se conserva el factor de cambio que ya
    ///    tiene el pedido (no se re-cotiza en silencio) y el pedido sigue Lanzado.
    ///  · Si cambió y el pedido está Lanzado con divisa, se reabre primero (Reopen) y se
    ///    valida ya en Abierto; Purch.-Post lo vuelve a lanzar solo al registrar. Es el
    ///    mismo ciclo que hacía la PWA desde el cliente, ahora en una sola llamada.
    ///  · En moneda local no se reabre: validar la fecha ahí no toca líneas y hoy funciona
    ///    igual con el pedido Lanzado.
    /// No hace Modify: el caller persiste junto con Receive/Invoice.
    /// </summary>
    local procedure PrepararFechaRegistro(var PurchHeader: Record "Purchase Header"; postingDate: Date)
    var
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        if postingDate = 0D then
            postingDate := Today();

        if (PurchHeader."Posting Date" <> postingDate) and
           (PurchHeader."Currency Code" <> '') and
           (PurchHeader.Status <> PurchHeader.Status::Open)
        then
            ReleasePurchDoc.PerformManualReopen(PurchHeader);

        if PurchHeader."Posting Date" <> postingDate then
            PurchHeader.Validate("Posting Date", postingDate);
        if PurchHeader."Document Date" <> postingDate then
            PurchHeader.Validate("Document Date", postingDate);
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
