codeunit 50159 "GJW Item Transfer Bulk"
{
    // 🎯 Procesa transferencias bulk de almacén a almacén/obra
    // Crea líneas en Item Reclass Journal y ejecuta posting automáticamente

    [ServiceEnabled]
    procedure ProcessTransfers(transfersJSON: Text): Text
    var
        Arr: JsonArray;
        Token: JsonToken;
        Obj: JsonObject;
        Val: JsonToken;

        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";

        TemplateName: Code[10];
        BatchName: Code[10];
        LineNo: Integer;

        ItemNo: Code[20];
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        TaskNo: Code[20];
        Description: Text[100];
        Quantity: Decimal;
        PostingDate: Date;
        DocumentNo: Code[20];
        VariantCode: Code[10];
        AppliesFromEntry: Integer;

        InsCount: Integer;
        ErrorCount: Integer;
        ErrorMsg: Text;
    begin
        TemplateName := 'TRANSFEREN';
        BatchName := 'GENERICO';

        // 🧹 Limpiar líneas existentes del batch
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);
        if ItemJnlLine.FindSet() then
            ItemJnlLine.DeleteAll(true);

        // 📝 Procesar JSON y crear líneas
        if transfersJSON = '' then
            exit('ERROR: No se recibió JSON de transferencias');

        if not Arr.ReadFrom(transfersJSON) then
            exit('ERROR: JSON inválido');

        LineNo := 10000;

        foreach Token in Arr do begin
            if Token.IsObject() then begin
                Obj := Token.AsObject();

                // Limpiar variables
                Clear(ItemNo);
                Clear(LocationCode);
                Clear(NewLocationCode);
                Clear(TaskNo);
                Clear(Description);
                Clear(Quantity);
                Clear(PostingDate);
                Clear(DocumentNo);
                Clear(VariantCode);
                Clear(AppliesFromEntry);

                // ✅ Leer campos del JSON
                if Obj.Get('itemNo', Val) and (not Val.AsValue().IsNull()) then
                    ItemNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(ItemNo));

                if Obj.Get('locationCode', Val) and (not Val.AsValue().IsNull()) then
                    LocationCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(LocationCode));

                if Obj.Get('newLocationCode', Val) and (not Val.AsValue().IsNull()) then
                    NewLocationCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NewLocationCode));

                if Obj.Get('quantity', Val) and (not Val.AsValue().IsNull()) then
                    Quantity := Val.AsValue().AsDecimal();

                if Obj.Get('taskNo', Val) and (not Val.AsValue().IsNull()) then
                    TaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskNo));

                if Obj.Get('description', Val) and (not Val.AsValue().IsNull()) then
                    Description := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(Description));

                if Obj.Get('postingDate', Val) and (not Val.AsValue().IsNull()) then
                    Evaluate(PostingDate, Val.AsValue().AsText())
                else
                    PostingDate := Today();

                if Obj.Get('documentNo', Val) and (not Val.AsValue().IsNull()) then
                    DocumentNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(DocumentNo));

                if Obj.Get('variantCode', Val) and (not Val.AsValue().IsNull()) then
                    VariantCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(VariantCode));

                if Obj.Get('appliesFromEntry', Val) and (not Val.AsValue().IsNull()) then
                    AppliesFromEntry := Val.AsValue().AsInteger();

                // ✅ Validar campos obligatorios
                if ItemNo = '' then begin
                    ErrorCount += 1;
                    ErrorMsg := 'ERROR: itemNo es obligatorio';
                end else if Quantity <= 0 then begin
                    ErrorCount += 1;
                    ErrorMsg := 'ERROR: quantity debe ser mayor que 0';
                end else if LocationCode = '' then begin
                    ErrorCount += 1;
                    ErrorMsg := 'ERROR: locationCode es obligatorio';
                end else if NewLocationCode = '' then begin
                    ErrorCount += 1;
                    ErrorMsg := 'ERROR: newLocationCode es obligatorio';
                end else begin
                    // 🚀 Crear línea de transferencia
                    if InsertTransferLine(ItemJnlLine, TemplateName, BatchName, LineNo, ItemNo, LocationCode,
                        NewLocationCode, Quantity, TaskNo, Description, PostingDate, DocumentNo, VariantCode, AppliesFromEntry) then begin
                        InsCount += 1;
                        LineNo += 10000;
                    end else begin
                        ErrorCount += 1;
                        ErrorMsg := 'ERROR: No se pudo crear la línea de transferencia';
                    end;
                end;
            end else
                ErrorCount += 1;
        end;

        // ❌ Si hubo errores, no ejecutar posting
        if ErrorCount > 0 then
            exit(StrSubstNo('%1 líneas creadas, %2 errores. Último error: %3', InsCount, ErrorCount, ErrorMsg));

        if InsCount = 0 then
            exit('ERROR: No se crearon líneas para transferir');

        // ✅ Ejecutar posting
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if not ItemJnlLine.FindFirst() then
            exit('ERROR: No se encontraron líneas para registrar');

        Commit();

        ClearLastError();
        if not ItemJnlPostBatch.Run(ItemJnlLine) then begin
            ErrorMsg := GetLastErrorText();
            ClearLastError();
            exit('ERROR al registrar: ' + ErrorMsg);
        end;

        // 🎉 Éxito
        exit(StrSubstNo('✅ %1 transferencias registradas correctamente', InsCount));
    end;

    local procedure InsertTransferLine(
        var ItemJnlLine: Record "Item Journal Line";
        TemplateName: Code[10];
        BatchName: Code[10];
        LineNo: Integer;
        ItemNo: Code[20];
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        Quantity: Decimal;
        TaskNo: Code[20];
        Description: Text[100];
        PostingDate: Date;
        DocumentNo: Code[20];
        VariantCode: Code[10];
        AppliesFromEntry: Integer
    ): Boolean
    var
        Item: Record Item;
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := TemplateName;
        ItemJnlLine."Journal Batch Name" := BatchName;
        ItemJnlLine."Line No." := LineNo;
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."Posting Date" := PostingDate;
        ItemJnlLine."Document No." := DocumentNo;
        ItemJnlLine.Validate("Item No.", ItemNo);

        // Si el producto existe, usar su UoM base
        if Item.Get(ItemNo) then
            ItemJnlLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");

        // ⚠️ Asignar directamente sin validar para evitar errores de tabla relacionada
        ItemJnlLine."Location Code" := LocationCode;
        ItemJnlLine."New Location Code" := NewLocationCode;
        ItemJnlLine.Validate(Quantity, Quantity);

        if VariantCode <> '' then
            ItemJnlLine.Validate("Variant Code", VariantCode);

        if TaskNo <> '' then
            ItemJnlLine."Task No." := TaskNo;

        // ✅ Aplicar desde movimiento específico (Liq. por n° orden)
        if AppliesFromEntry <> 0 then
            ItemJnlLine."Applies-from Entry" := AppliesFromEntry;

        if Description <> '' then
            ItemJnlLine.Description := Description
        else
            ItemJnlLine.Description := StrSubstNo('Transfer %1 → %2', LocationCode, NewLocationCode);

        exit(ItemJnlLine.Insert(true));
    end;
}
