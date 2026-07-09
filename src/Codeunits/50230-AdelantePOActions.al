// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50230 "Adelante PO Actions"
// Propósito: Acciones sobre Pedidos de Compra que la API estándar v2.0 NO permite
//            por escritura directa (el campo Status es read-only / sistema).
//            Se exponen como Web Service OData ("AdelantePO") para que la app de
//            Compras las invoque por S2S al aprobar/reabrir una orden.
//
//   - ReleaseOrder(orderNo)  ->  PerformManualRelease  ->  Status = "Lanzado"
//   - ReopenOrder(orderNo)   ->  PerformManualReopen   ->  Status = "Abierto"
//
// Llamada desde la app (OData V4 unbound action, S2S):
//   POST .../ODataV4/AdelantePO_ReleaseOrder?company={companyId}
//   body: { "orderNo": "CP-000867" }   ->  respuesta: { "value": "Released" }
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50230 "Adelante PO Actions"
{
    Access = Public;

    /// <summary>Lanza (Release) un pedido de compra por su N.º. Devuelve el estado resultante.</summary>
    procedure ReleaseOrder(orderNo: Code[20]): Text
    var
        PurchHeader: Record "Purchase Header";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        GetOrder(PurchHeader, orderNo);
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
            if (itm <> '') and (qty > 0) then begin
                PurchLine.Reset();
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange("Document No.", orderNo);
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                PurchLine.SetRange("No.", itm);
                PurchLine.SetFilter("Outstanding Quantity", '>0');
                PurchLine.SetRange("Qty. to Receive", 0);
                if PurchLine.FindFirst() then begin
                    PurchLine.Validate("Qty. to Receive", qty);
                    PurchLine.Validate("Qty. to Invoice", qty);
                    PurchLine.Modify(true);
                end;
            end;
        end;

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
}
