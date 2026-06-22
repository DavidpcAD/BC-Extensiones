// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50199 "GJW Purchase Post Processor"
// Propósito: Procesar Vista Previa (Preview) y Registro (Post = Receive + Invoice)
//            de Pedidos de Compra desde API.
//
// Flujo "vista previa -> registrar" con token de confirmación:
//   1) action = "preview"  -> simula el posting SIN grabar, devuelve los asientos
//      que se generarían y un "previewToken" (hash del estado del documento + payload).
//   2) action = "post" (u omitido) -> registra. Si se envía "previewToken", se
//      revalida que el documento NO haya cambiado desde la vista previa; si cambió,
//      se rechaza el registro.
//
// El mismo payload se usa en ambas llamadas, de modo que se registra exactamente
// lo que se previsualizó.
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50199 "GJW Purchase Post Processor"
{
    // ─────────────────────────────────────────────────────────────────────────────
    // PUNTO DE ENTRADA: enruta según el campo "action" del JSON.
    // ─────────────────────────────────────────────────────────────────────────────
    [ServiceEnabled]
    procedure Process(RequestJSON: Text): Text
    var
        RequestObj: JsonObject;
        Action: Text;
    begin
        if RequestObj.ReadFrom(RequestJSON) then
            Action := LowerCase(GetTextValue(RequestObj, 'action'));

        case Action of
            'preview':
                exit(PreviewPurchaseOrder(RequestJSON));
            else
                exit(PostPurchaseOrder(RequestJSON));
        end;
    end;

    // ═════════════════════════════════════════════════════════════════════════════
    // VISTA PREVIA (no graba): simula y devuelve los asientos + previewToken.
    // ═════════════════════════════════════════════════════════════════════════════
    [ServiceEnabled]
    procedure PreviewPurchaseOrder(RequestJSON: Text): Text
    var
        PreviewHandler: Codeunit "GJW Purch Posting Preview";
        RequestObj: JsonObject;
        ResponseObj: JsonObject;
        EntriesArray: JsonArray;
        OrderNo: Code[20];
        Token: Text;
        ErrTxt: Text;
    begin
        if not RequestObj.ReadFrom(RequestJSON) then begin
            ResponseObj.Add('preview', false);
            ResponseObj.Add('error', 'JSON inválido');
            exit(FormatJsonOutput(ResponseObj));
        end;

        OrderNo := CopyStr(GetTextValue(RequestObj, 'purchaseOrderNo'), 1, MaxStrLen(OrderNo));

        // Token calculado sobre el estado ACTUAL (antes de aplicar cambios).
        Token := ComputeStateToken(OrderNo, RequestObj);

        // TryApplyAndPreview SIEMPRE termina con un error deliberado para hacer
        // rollback de las modificaciones (la previa no debe persistir nada).
        // Los asientos capturados viven en memoria (PreviewHandler) y sobreviven al rollback.
        if not TryApplyAndPreview(RequestObj, PreviewHandler) then begin
            if TryUnbindPreview(PreviewHandler) then;

            if PreviewHandler.HasCapturedEntries() then begin
                EntriesArray := PreviewHandler.GetEntries();
                ResponseObj.Add('preview', true);
                ResponseObj.Add('purchaseOrderNo', OrderNo);
                ResponseObj.Add('previewToken', Token);
                ResponseObj.Add('entries', EntriesArray);
                ResponseObj.Add('message', 'Vista previa generada. Envíe previewToken en la llamada de registro para confirmar.');
            end else begin
                ErrTxt := GetLastErrorText();
                if ErrTxt = '' then
                    ErrTxt := 'No se pudo generar la vista previa';
                ResponseObj.Add('preview', false);
                ResponseObj.Add('error', ErrTxt);
            end;
        end else begin
            // No debería ocurrir: TryApplyAndPreview siempre fuerza rollback vía Error.
            if TryUnbindPreview(PreviewHandler) then;
            ResponseObj.Add('preview', false);
            ResponseObj.Add('error', 'No se pudo generar la vista previa (sin rollback).');
        end;

        exit(FormatJsonOutput(ResponseObj));
    end;

    [TryFunction]
    local procedure TryApplyAndPreview(var RequestObj: JsonObject; var PreviewHandler: Codeunit "GJW Purch Posting Preview")
    var
        PurchHeader: Record "Purchase Header";
    begin
        LoadAndValidateHeader(RequestObj, PurchHeader);
        ApplyRequestToDocument(RequestObj, PurchHeader);

        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchHeader.Modify();

        BindSubscription(PreviewHandler);
        PreviewHandler.RunPreview(PurchHeader);
        UnbindSubscription(PreviewHandler);

        // Rollback deliberado: deshace todas las modificaciones de la previa.
        Error('__PREVIEW_ROLLBACK__');
    end;

    [TryFunction]
    local procedure TryUnbindPreview(var PreviewHandler: Codeunit "GJW Purch Posting Preview")
    begin
        UnbindSubscription(PreviewHandler);
    end;

    // ═════════════════════════════════════════════════════════════════════════════
    // REGISTRO (Receive + Invoice). Valida previewToken si se proporciona.
    // ═════════════════════════════════════════════════════════════════════════════
    [ServiceEnabled]
    procedure PostPurchaseOrder(RequestJSON: Text): Text
    var
        ResponseObj: JsonObject;
        ErrorMsg: Text;
    begin
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
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchPost: Codeunit "Purch.-Post";
        RequestObj: JsonObject;
        PreviewToken: Text;
        PurchaseOrderNo: Code[20];
        PostedReceiptNo: Code[20];
        PostedInvoiceNo: Code[20];
        ProcessedLines: Integer;
    begin
        // ═══ PASO 1: Parsear y validar encabezado ═══
        if not RequestObj.ReadFrom(RequestJSON) then
            Error('JSON inválido');

        LoadAndValidateHeader(RequestObj, PurchHeader);
        PurchaseOrderNo := PurchHeader."No.";

        // ═══ PASO 2: Validar token de la vista previa (si viene) ═══
        PreviewToken := GetTextValue(RequestObj, 'previewToken');
        if PreviewToken <> '' then
            if ComputeStateToken(PurchaseOrderNo, RequestObj) <> PreviewToken then
                Error('El documento %1 cambió desde la vista previa (previewToken no coincide). Genere la vista previa de nuevo antes de registrar.', PurchaseOrderNo);

        // ═══ PASO 3: Aplicar cambios al documento (encabezado + líneas) ═══
        ProcessedLines := ApplyRequestToDocument(RequestObj, PurchHeader);

        // ═══ PASO 4: Ejecutar posting (Receive + Invoice) ═══
        Commit(); // asegurar cambios guardados antes del posting

        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchHeader.Modify();

        PurchPost.Run(PurchHeader);

        // ═══ PASO 5: Obtener números de documentos registrados ═══
        PurchRcptHeader.SetCurrentKey("Order No.", "Posting Date");
        PurchRcptHeader.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        if PurchRcptHeader.FindLast() then
            PostedReceiptNo := PurchRcptHeader."No.";

        PurchInvHeader.SetCurrentKey("Order No.", "Posting Date");
        PurchInvHeader.SetRange("Order No.", PurchaseOrderNo);
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        if PurchInvHeader.FindLast() then
            PostedInvoiceNo := PurchInvHeader."No.";

        // ═══ PASO 6: Construir respuesta ═══
        ResponseObj.Add('posted', true);
        ResponseObj.Add('purchaseOrderNo', PurchaseOrderNo);
        ResponseObj.Add('postedReceiptNo', PostedReceiptNo);
        ResponseObj.Add('postedInvoiceNo', PostedInvoiceNo);
        ResponseObj.Add('linesProcessed', ProcessedLines);
        ResponseObj.Add('message', StrSubstNo('Pedido %1 registrado correctamente. Recibo: %2, Factura: %3',
            PurchaseOrderNo, PostedReceiptNo, PostedInvoiceNo));
    end;

    // ═════════════════════════════════════════════════════════════════════════════
    // HELPERS COMPARTIDOS (usados por preview y post -> garantizan mismo resultado)
    // ═════════════════════════════════════════════════════════════════════════════

    local procedure LoadAndValidateHeader(var RequestObj: JsonObject; var PurchHeader: Record "Purchase Header")
    var
        OrderNo: Code[20];
    begin
        OrderNo := CopyStr(GetTextValue(RequestObj, 'purchaseOrderNo'), 1, MaxStrLen(OrderNo));
        if OrderNo = '' then
            Error('purchaseOrderNo es obligatorio');

        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetRange("No.", OrderNo);
        if not PurchHeader.FindFirst() then
            Error('Pedido de compra %1 no encontrado', OrderNo);

        if PurchHeader.Status <> PurchHeader.Status::Open then
            Error('El pedido %1 no está en estado Open (estado actual: %2)', OrderNo, PurchHeader.Status);
    end;

    local procedure ApplyRequestToDocument(var RequestObj: JsonObject; var PurchHeader: Record "Purchase Header"): Integer
    var
        PurchLine: Record "Purchase Line";
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineObj: JsonObject;
        VendorInvoiceNo: Code[35];
        DocumentDate: Date;
        PostingDate: Date;
        LineSystemId: Guid;
        QtyToReceive: Decimal;
        ProcessedLines: Integer;
    begin
        VendorInvoiceNo := CopyStr(GetTextValue(RequestObj, 'vendorInvoiceNo'), 1, MaxStrLen(VendorInvoiceNo));
        if VendorInvoiceNo = '' then
            Error('vendorInvoiceNo es obligatorio');

        if not Evaluate(DocumentDate, GetTextValue(RequestObj, 'documentDate')) then
            DocumentDate := WorkDate();
        if not Evaluate(PostingDate, GetTextValue(RequestObj, 'postingDate')) then
            PostingDate := WorkDate();

        if not GetJsonArray(RequestObj, 'lines', LinesArray) then
            Error('No se proporcionaron líneas para procesar');

        // Encabezado
        PurchHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        if DocumentDate <> 0D then
            PurchHeader.Validate("Document Date", DocumentDate);
        if PostingDate <> 0D then
            PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Modify(true);

        // Líneas
        foreach LineToken in LinesArray do
            if LineToken.IsObject() then begin
                LineObj := LineToken.AsObject();

                LineSystemId := GetGuidValue(LineObj, 'lineSystemId');
                QtyToReceive := GetDecimalValue(LineObj, 'qtyToReceive');

                if IsNullGuid(LineSystemId) then
                    Error('lineSystemId es obligatorio para cada línea');

                PurchLine.SetRange("Document Type", PurchHeader."Document Type");
                PurchLine.SetRange("Document No.", PurchHeader."No.");
                PurchLine.SetRange(SystemId, LineSystemId);
                if not PurchLine.FindFirst() then
                    Error('Línea con SystemId %1 no encontrada', LineSystemId);

                if QtyToReceive < 0 then
                    Error('qtyToReceive debe ser mayor o igual a 0 (línea %1)', PurchLine."Line No.");

                if QtyToReceive > (PurchLine.Quantity - PurchLine."Quantity Received") then
                    Error('qtyToReceive (%1) excede la cantidad pendiente (%2) en línea %3',
                        QtyToReceive, PurchLine.Quantity - PurchLine."Quantity Received", PurchLine."Line No.");

                PurchLine.Validate("Qty. to Receive", QtyToReceive);
                PurchLine.Validate("Qty. to Invoice", QtyToReceive); // Receive + Invoice
                PurchLine.Modify(true);

                ProcessedLines += 1;
            end;

        if ProcessedLines = 0 then
            Error('No se procesó ninguna línea válida');

        exit(ProcessedLines);
    end;

    // ═════════════════════════════════════════════════════════════════════════════
    // TOKEN DE ESTADO: hash del estado del documento + payload. Detecta cambios
    // entre la vista previa y el registro.
    // ═════════════════════════════════════════════════════════════════════════════
    local procedure ComputeStateToken(OrderNo: Code[20]; var RequestObj: JsonObject): Text
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineObj: JsonObject;
        Sb: TextBuilder;
    begin
        if OrderNo = '' then
            exit('');

        Sb.Append('H|');
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetRange("No.", OrderNo);
        if PurchHeader.FindFirst() then begin
            Sb.Append(PurchHeader."No.");
            Sb.Append('|');
            Sb.Append(Format(PurchHeader.Status, 0, 9));
            Sb.Append('|');
            Sb.Append(PurchHeader."Buy-from Vendor No.");
            Sb.Append('|');
        end;

        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", OrderNo);
        if PurchLine.FindSet() then
            repeat
                Sb.Append('L|');
                Sb.Append(Format(PurchLine."Line No."));
                Sb.Append('|');
                Sb.Append(Format(PurchLine.Type, 0, 9));
                Sb.Append('|');
                Sb.Append(PurchLine."No.");
                Sb.Append('|');
                Sb.Append(Format(PurchLine.Quantity, 0, 9));
                Sb.Append('|');
                Sb.Append(Format(PurchLine."Quantity Received", 0, 9));
                Sb.Append('|');
                Sb.Append(Format(PurchLine."Direct Unit Cost", 0, 9));
                Sb.Append('|');
            until PurchLine.Next() = 0;

        // Payload (mismo en preview y post)
        Sb.Append('P|');
        Sb.Append(GetTextValue(RequestObj, 'vendorInvoiceNo'));
        Sb.Append('|');
        Sb.Append(GetTextValue(RequestObj, 'documentDate'));
        Sb.Append('|');
        Sb.Append(GetTextValue(RequestObj, 'postingDate'));
        Sb.Append('|');
        if GetJsonArray(RequestObj, 'lines', LinesArray) then
            foreach LineToken in LinesArray do
                if LineToken.IsObject() then begin
                    LineObj := LineToken.AsObject();
                    Sb.Append(GetTextValue(LineObj, 'lineSystemId'));
                    Sb.Append('=');
                    Sb.Append(Format(GetDecimalValue(LineObj, 'qtyToReceive'), 0, 9));
                    Sb.Append(';');
                end;

        exit(HashText(Sb.ToText()));
    end;

    // FNV-1a de 32 bits, dos pasadas con semillas distintas (token de 64 bits efectivos).
    local procedure HashText(InputText: Text): Text
    var
        Seed1: BigInteger;
        Seed2: BigInteger;
    begin
        Seed1 := 2000000000;
        Seed1 := Seed1 + 166136261; // total 2166136261 — FNV offset basis
        Seed2 := 2000000000;
        Seed2 := Seed2 + 166144180; // total 2166144180 — offset basis alternativo
        exit(Format(Fnv32(InputText, Seed1)) + '-' + Format(Fnv32(InputText, Seed2)));
    end;

    local procedure Fnv32(InputText: Text; Seed: BigInteger): BigInteger
    var
        Hash: BigInteger;
        Modulo: BigInteger;
        Prime: BigInteger;
        ByteVal: Integer;
        i: Integer;
    begin
        Modulo := 2000000000;
        Modulo := Modulo + 2000000000;
        Modulo := Modulo + 294967296; // total 4294967296 = 2^32
        Prime := 16777619;
        Hash := Seed mod Modulo;
        for i := 1 to StrLen(InputText) do begin
            ByteVal := InputText[i];
            Hash := BigIntXor(Hash, ByteVal); // bxor no soportado en BigInteger
            Hash := (Hash * Prime) mod Modulo;
        end;
        exit(Hash);
    end;

    // XOR bit a bit para BigInteger (bxor solo soporta Integer en AL).
    local procedure BigIntXor(A: BigInteger; B: BigInteger): BigInteger
    var
        Result: BigInteger;
        BitVal: BigInteger;
        ABit: BigInteger;
        BBit: BigInteger;
        i: Integer;
    begin
        Result := 0;
        BitVal := 1;
        for i := 1 to 32 do begin
            ABit := A mod 2;
            BBit := B mod 2;
            if ABit <> BBit then
                Result += BitVal;
            A := A div 2;
            B := B div 2;
            BitVal := BitVal * 2;
        end;
        exit(Result);
    end;

    // ═════════════════════════════════════════════════════════════════════════════
    // HELPERS DE LECTURA DE JSON
    // ═════════════════════════════════════════════════════════════════════════════
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
        exit(GuidValue); // GUID nulo
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
