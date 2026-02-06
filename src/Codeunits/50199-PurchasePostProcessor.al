// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50199 "GJW Purchase Post Processor"
// Propósito: Procesar el posting (Receive + Invoice) de Pedidos de Compra desde API
// Entrada: Datos del pedido y líneas con cantidades a recibir
// Salida: Resultado del posting con números de documentos registrados
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50199 "GJW Purchase Post Processor"
{
    /// <summary>
    /// Procesa el posting de un pedido de compra (Receive + Invoice)
    /// </summary>
    /// <param name="RequestJSON">JSON con los datos del pedido y líneas</param>
    /// <returns>JSON con el resultado del posting</returns>
    [ServiceEnabled]
    procedure PostPurchaseOrder(RequestJSON: Text): Text
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        ResponseObj: JsonObject;
        RequestObj: JsonObject;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineObj: JsonObject;
        PurchaseOrderNo: Code[20];
        VendorInvoiceNo: Code[35];
        DocumentDate: Date;
        PostingDate: Date;
        LineSystemId: Guid;
        QtyToReceive: Decimal;
        ErrorMsg: Text;
        PostedReceiptNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // Intentar procesar con manejo de errores
        if not TryPostPurchase(RequestJSON, ResponseObj) then begin
            ErrorMsg := GetLastErrorText();
            if ErrorMsg = '' then
                ErrorMsg := 'Error desconocido durante el posting';

            Clear(ResponseObj);
            ResponseObj.Add('posted', false);
            ResponseObj.Add('error', ErrorMsg);
        end;

        exit(FormatJsonOutput(ResponseObj));
    end;

    [TryFunction]
    local procedure TryPostPurchase(RequestJSON: Text; var ResponseObj: JsonObject)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchPost: Codeunit "Purch.-Post";
        RequestObj: JsonObject;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineObj: JsonObject;
        PurchaseOrderNo: Code[20];
        VendorInvoiceNo: Code[35];
        DocumentDate: Date;
        PostingDate: Date;
        LineSystemId: Guid;
        QtyToReceive: Decimal;
        PostedReceiptNo: Code[20];
        PostedInvoiceNo: Code[20];
        ProcessedLines: Integer;
    begin
        // ═══ PASO 1: Parsear JSON ═══
        if not RequestObj.ReadFrom(RequestJSON) then
            Error('JSON inválido');

        PurchaseOrderNo := GetTextValue(RequestObj, 'purchaseOrderNo');
        VendorInvoiceNo := GetTextValue(RequestObj, 'vendorInvoiceNo');

        if not Evaluate(DocumentDate, GetTextValue(RequestObj, 'documentDate')) then
            DocumentDate := WorkDate();

        if not Evaluate(PostingDate, GetTextValue(RequestObj, 'postingDate')) then
            PostingDate := WorkDate();

        if not GetJsonArray(RequestObj, 'lines', LinesArray) then
            Error('No se proporcionaron líneas para procesar');

        // ═══ PASO 2: Validaciones del pedido ═══
        if PurchaseOrderNo = '' then
            Error('purchaseOrderNo es obligatorio');

        if VendorInvoiceNo = '' then
            Error('vendorInvoiceNo es obligatorio');

        // Buscar el pedido
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetRange("No.", PurchaseOrderNo);
        if not PurchHeader.FindFirst() then
            Error('Pedido de compra %1 no encontrado', PurchaseOrderNo);

        if PurchHeader.Status <> PurchHeader.Status::Open then
            Error('El pedido %1 no está en estado Open (estado actual: %2)', PurchaseOrderNo, PurchHeader.Status);

        // ═══ PASO 3: Actualizar encabezado ═══
        PurchHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        if DocumentDate <> 0D then
            PurchHeader.Validate("Document Date", DocumentDate);
        if PostingDate <> 0D then
            PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Modify(true);

        // ═══ PASO 4: Actualizar líneas con Qty. to Receive ═══
        foreach LineToken in LinesArray do begin
            if LineToken.IsObject() then begin
                LineObj := LineToken.AsObject();

                // Obtener SystemId y cantidad
                LineSystemId := GetGuidValue(LineObj, 'lineSystemId');
                QtyToReceive := GetDecimalValue(LineObj, 'qtyToReceive');

                if IsNullGuid(LineSystemId) then
                    Error('lineSystemId es obligatorio para cada línea');

                // Buscar la línea
                PurchLine.SetRange("Document Type", PurchHeader."Document Type");
                PurchLine.SetRange("Document No.", PurchHeader."No.");
                PurchLine.SetRange(SystemId, LineSystemId);

                if not PurchLine.FindFirst() then
                    Error('Línea con SystemId %1 no encontrada', LineSystemId);

                // Validar cantidad
                if QtyToReceive < 0 then
                    Error('qtyToReceive debe ser mayor o igual a 0 (línea %1)', PurchLine."Line No.");

                if QtyToReceive > (PurchLine.Quantity - PurchLine."Quantity Received") then
                    Error('qtyToReceive (%1) excede la cantidad pendiente (%2) en línea %3',
                        QtyToReceive, PurchLine.Quantity - PurchLine."Quantity Received", PurchLine."Line No.");

                // Setear Qty. to Receive
                PurchLine.Validate("Qty. to Receive", QtyToReceive);
                PurchLine.Validate("Qty. to Invoice", QtyToReceive); // Receive + Invoice
                PurchLine.Modify(true);

                ProcessedLines += 1;
            end;
        end;

        if ProcessedLines = 0 then
            Error('No se procesó ninguna línea válida');

        // ═══ PASO 5: Ejecutar posting (Receive + Invoice) ═══
        Commit(); // Asegurar que los cambios estén guardados antes del posting

        // Configurar opciones de posting
        PurchHeader.Receive := true;  // Recibir
        PurchHeader.Invoice := true;  // Facturar
        PurchHeader.Modify();

        // Ejecutar posting
        PurchPost.Run(PurchHeader);

        // ═══ PASO 6: Obtener números de documentos registrados ═══
        // Buscar el último recibo registrado
        PurchRcptHeader.SetCurrentKey("Order No.", "Posting Date");
        PurchRcptHeader.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        if PurchRcptHeader.FindLast() then
            PostedReceiptNo := PurchRcptHeader."No.";

        // Buscar la última factura registrada
        PurchInvHeader.SetCurrentKey("Order No.", "Posting Date");
        PurchInvHeader.SetRange("Order No.", PurchaseOrderNo);
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        if PurchInvHeader.FindLast() then
            PostedInvoiceNo := PurchInvHeader."No.";

        // ═══ PASO 7: Construir respuesta ═══
        ResponseObj.Add('posted', true);
        ResponseObj.Add('purchaseOrderNo', PurchaseOrderNo);
        ResponseObj.Add('postedReceiptNo', PostedReceiptNo);
        ResponseObj.Add('postedInvoiceNo', PostedInvoiceNo);
        ResponseObj.Add('linesProcessed', ProcessedLines);
        ResponseObj.Add('message', StrSubstNo('✅ Pedido %1 registrado correctamente. Recibo: %2, Factura: %3',
            PurchaseOrderNo, PostedReceiptNo, PostedInvoiceNo));
    end;

    local procedure GetTextValue(JObj: JsonObject; KeyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObj.Get(KeyName, JToken) and (not JToken.AsValue().IsNull()) then
            exit(JToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetDecimalValue(JObj: JsonObject; KeyName: Text): Decimal
    var
        JToken: JsonToken;
    begin
        if JObj.Get(KeyName, JToken) and (not JToken.AsValue().IsNull()) then
            exit(JToken.AsValue().AsDecimal());
        exit(0);
    end;

    local procedure GetGuidValue(JObj: JsonObject; KeyName: Text): Guid
    var
        JToken: JsonToken;
        GuidText: Text;
        GuidValue: Guid;
    begin
        if JObj.Get(KeyName, JToken) and (not JToken.AsValue().IsNull()) then begin
            GuidText := JToken.AsValue().AsText();
            if Evaluate(GuidValue, GuidText) then
                exit(GuidValue);
        end;
        exit(GuidValue); // Retorna GUID nulo
    end;

    local procedure GetJsonArray(JObj: JsonObject; KeyName: Text; var JArray: JsonArray): Boolean
    var
        JToken: JsonToken;
    begin
        if JObj.Get(KeyName, JToken) and JToken.IsArray() then begin
            JArray := JToken.AsArray();
            exit(true);
        end;
        exit(false);
    end;

    local procedure FormatJsonOutput(JObj: JsonObject): Text
    var
        OutputText: Text;
    begin
        JObj.WriteTo(OutputText);
        exit(OutputText);
    end;
}
