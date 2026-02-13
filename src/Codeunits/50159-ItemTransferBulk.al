codeunit 50159 "GJW Item Transfer Bulk"
{
    [ServiceEnabled]
    procedure ProcessTransfers(transfersJSON: Text): Text
    var
        JsonOut: Text;
    begin
        exit(ProcessTransfersWithJson(transfersJSON, JsonOut));
    end;

    procedure ProcessTransfersWithJson(transfersJSON: Text; var JsonResultsOut: Text): Text
    var
        // ─── JSON parsing ───
        Arr: JsonArray;
        Token: JsonToken;
        Obj: JsonObject;
        Val: JsonToken;

        // ─── BC records ───
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";

        // ─── Setup ───
        TemplateName: Code[10];
        BatchName: Code[10];
        LineNo: Integer;

        // ─── Fields per transfer ───
        ItemNo: Code[20];
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        TaskNo: Code[20];
        NewJobNo: Code[20];
        NewJobTaskNo: Code[20];
        Description: Text[100];
        Quantity: Decimal;
        PostingDate: Date;
        DocumentNo: Code[20];
        VariantCode: Code[10];
        AppliesFromEntry: Integer;

        // ─── Counters/errors ───
        InsCount: Integer;
        ErrorCount: Integer;
        ErrorMsg: Text;

        // ─── For results ───
        ResultsText: Text;
        StartEntryNo: Integer;
    begin
        TemplateName := 'TRANSFEREN';
        BatchName := 'GENERICO';

        // limpiar batch
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);
        if ItemJnlLine.FindSet() then
            ItemJnlLine.DeleteAll(true);

        if transfersJSON = '' then begin
            JsonResultsOut := '[]';
            exit('ERROR: No se recibió JSON de transferencias');
        end;

        if not Arr.ReadFrom(transfersJSON) then begin
            JsonResultsOut := '[]';
            exit('ERROR: JSON inválido');
        end;

        LineNo := 10000;

        foreach Token in Arr do begin
            if not Token.IsObject() then begin
                ErrorCount += 1;
                ErrorMsg := 'ERROR: Elemento del array no es un objeto';
                continue;
            end;

            Obj := Token.AsObject();

            Clear(ItemNo);
            Clear(LocationCode);
            Clear(NewLocationCode);
            Clear(TaskNo);
            Clear(NewJobNo);
            Clear(NewJobTaskNo);
            Clear(Description);
            Clear(Quantity);
            Clear(PostingDate);
            Clear(DocumentNo);
            Clear(VariantCode);
            Clear(AppliesFromEntry);

            // itemNo
            if Obj.Get('itemNo', Val) and (not Val.AsValue().IsNull()) then
                ItemNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(ItemNo));

            // locationCode
            if Obj.Get('locationCode', Val) and (not Val.AsValue().IsNull()) then
                LocationCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(LocationCode));

            // newLocationCode
            if Obj.Get('newLocationCode', Val) and (not Val.AsValue().IsNull()) then
                NewLocationCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NewLocationCode));

            // quantity
            if Obj.Get('quantity', Val) and (not Val.AsValue().IsNull()) then
                Quantity := Val.AsValue().AsDecimal();

            // taskNo (opcional)
            if Obj.Get('taskNo', Val) and (not Val.AsValue().IsNull()) then
                TaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskNo));

            // newJobNo (opcional)
            if Obj.Get('newJobNo', Val) and (not Val.AsValue().IsNull()) then
                NewJobNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NewJobNo));

            // newJobTaskNo (opcional)
            if Obj.Get('newJobTaskNo', Val) and (not Val.AsValue().IsNull()) then
                NewJobTaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NewJobTaskNo));

            // description (opcional)
            if Obj.Get('description', Val) and (not Val.AsValue().IsNull()) then
                Description := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(Description));

            // postingDate (opcional)
            if Obj.Get('postingDate', Val) and (not Val.AsValue().IsNull()) then
                Evaluate(PostingDate, Val.AsValue().AsText())
            else
                PostingDate := Today();

            // documentNo (opcional)
            if Obj.Get('documentNo', Val) and (not Val.AsValue().IsNull()) then
                DocumentNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(DocumentNo))
            else
                DocumentNo := CopyStr('TRANS-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'), 1, 20);

            // variantCode (opcional)
            if Obj.Get('variantCode', Val) and (not Val.AsValue().IsNull()) then
                VariantCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(VariantCode));

            // appliesFromEntry (opcional)
            if Obj.Get('appliesFromEntry', Val) and (not Val.AsValue().IsNull()) then
                AppliesFromEntry := Val.AsValue().AsInteger();

            // validaciones mínimas
            if ItemNo = '' then begin
                ErrorCount += 1;
                ErrorMsg := 'ERROR: itemNo es obligatorio';
                continue;
            end;

            if Quantity <= 0 then begin
                ErrorCount += 1;
                ErrorMsg := 'ERROR: quantity debe ser mayor que 0';
                continue;
            end;

            if LocationCode = '' then begin
                ErrorCount += 1;
                ErrorMsg := 'ERROR: locationCode es obligatorio';
                continue;
            end;

            if NewLocationCode = '' then begin
                ErrorCount += 1;
                ErrorMsg := 'ERROR: newLocationCode es obligatorio';
                continue;
            end;

            // insertar línea de transferencia
            if InsertTransferLine(ItemJnlLine, TemplateName, BatchName, LineNo, ItemNo, LocationCode,
                NewLocationCode, Quantity, TaskNo, NewJobNo, NewJobTaskNo, Description, PostingDate, DocumentNo, VariantCode, AppliesFromEntry) then begin
                InsCount += 1;
                LineNo += 10000;
            end else begin
                ErrorCount += 1;
                ErrorMsg := 'ERROR: No se pudo crear la línea de transferencia';
            end;
        end;

        if ErrorCount > 0 then begin
            JsonResultsOut := '[]';
            exit(StrSubstNo('%1 líneas creadas, %2 errores. Último error: %3', InsCount, ErrorCount, ErrorMsg));
        end;

        if InsCount = 0 then begin
            JsonResultsOut := '[]';
            exit('ERROR: No se crearon líneas para transferir');
        end;

        // Validar locations (debug)
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);
        if not ItemJnlLine.FindFirst() then begin
            JsonResultsOut := '[]';
            exit('ERROR: No se encontraron líneas para registrar');
        end;

        if not ValidateLocationExists(ItemJnlLine."Location Code") then begin
            JsonResultsOut := '[]';
            exit(StrSubstNo('DEBUG: Location origen "%1" (len:%2) no existe antes de posting',
                ItemJnlLine."Location Code", StrLen(ItemJnlLine."Location Code")));
        end;

        if not ValidateLocationExists(ItemJnlLine."New Location Code") then begin
            JsonResultsOut := '[]';
            exit(StrSubstNo('DEBUG: Location destino "%1" (len:%2) no existe antes de posting',
                ItemJnlLine."New Location Code", StrLen(ItemJnlLine."New Location Code")));
        end;

        Commit();

        // Capturar último Entry No. antes del posting para identificar ILEs nuevos
        StartEntryNo := GetLastILEEntryNo();

        // POST BATCH
        ClearLastError();
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        Clear(ItemJnlPostBatch);

        if not Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJnlLine) then begin
            ErrorMsg := GetLastErrorText();
            if ErrorMsg = '' then
                ErrorMsg := 'Error desconocido durante el posting';
            JsonResultsOut := '[]';
            exit(StrSubstNo('❌ ERROR en posting: %1', ErrorMsg));
        end;

        // ✅ construir resultados “por línea”, con EntryNo destino + data destino, sin depender de Document No.
        JsonResultsOut := BuildTransferResultsJson(transfersJSON, StartEntryNo);

        exit(StrSubstNo('✅ %1 transferencias registradas.', InsCount));
    end;

    // ─────────────────────────────────────────────────────────────────────────────
    // InsertTransferLine (MODIFICADA con fix de TaskNo)
    // ─────────────────────────────────────────────────────────────────────────────
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
        NewJobNo: Code[20];
        NewJobTaskNo: Code[20];
        Description: Text[100];
        PostingDate: Date;
        DocumentNo: Code[20];
        VariantCode: Code[10];
        AppliesFromEntry: Integer
    ): Boolean
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemJnlLine.Init();

        if AppliesFromEntry <> 0 then begin
            if ItemLedgerEntry.Get(AppliesFromEntry) then begin
                if ItemLedgerEntry.Positive or (not ItemLedgerEntry.Open) then
                    AppliesFromEntry := 0;
            end else
                AppliesFromEntry := 0;
        end;

        ItemJnlLine."Journal Template Name" := TemplateName;
        ItemJnlLine."Journal Batch Name" := BatchName;
        ItemJnlLine."Line No." := LineNo;

        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;

        ItemJnlLine."Posting Date" := PostingDate;
        ItemJnlLine."Document No." := DocumentNo;

        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate("Location Code", LocationCode);

        if Item.Get(ItemNo) then
            ItemJnlLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");

        if VariantCode <> '' then
            ItemJnlLine.Validate("Variant Code", VariantCode);

        ItemJnlLine.Validate("New Location Code", NewLocationCode);

        ItemJnlLine.Validate(Quantity, Abs(Quantity));

        // ✅ FIX:
        // Solo setear Task No. (origen) cuando NO viene destino (NewJobNo/NewJobTaskNo)
        // Si viene destino, dejar Task No. vacío para que no "herede" la tarea anterior.
        if (NewJobNo = '') and (NewJobTaskNo = '') then begin
            if TaskNo <> '' then
                ItemJnlLine."Task No." := TaskNo;
        end else begin
            ItemJnlLine."Task No." := '';
        end;

        if NewJobNo <> '' then
            ItemJnlLine."New Job No." := NewJobNo;
        if NewJobTaskNo <> '' then
            ItemJnlLine."New Job Task No." := NewJobTaskNo;

        if (NewJobNo = '') and (NewJobTaskNo = '') then begin
            ItemJnlLine."Job No." := '';
            ItemJnlLine."Job Task No." := '';
            ItemJnlLine."Task No." := '';
        end;

        if Description <> '' then
            ItemJnlLine.Description := Description
        else
            ItemJnlLine.Description := StrSubstNo('Transfer %1 → %2', LocationCode, NewLocationCode);

        if AppliesFromEntry <> 0 then
            ItemJnlLine."Applies-from Entry" := AppliesFromEntry;

        exit(ItemJnlLine.Insert(true));
    end;

    local procedure ValidateLocationExists(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit(false);
        exit(Location.Get(LocationCode));
    end;

    // ─────────────────────────────────────────────────────────────────────────────
    // ✅ Helpers para identificar ILEs creados por el posting
    // ─────────────────────────────────────────────────────────────────────────────
    local procedure GetLastILEEntryNo(): Integer
    var
        ILE: Record "Item Ledger Entry";
    begin
        ILE.Reset();
        ILE.SetCurrentKey("Entry No.");
        if ILE.FindLast() then
            exit(ILE."Entry No.");
        exit(0);
    end;

    local procedure FindReceiptEntryNoAfterPosting(StartEntryNo: Integer; ItemNo: Code[20]; DestLocation: Code[10]; ReqQuantity: Decimal; PostingDate: Date): Integer
    var
        ILE: Record "Item Ledger Entry";
    begin
        ILE.Reset();
        ILE.SetCurrentKey("Entry No.");
        ILE.SetFilter("Entry No.", '>%1', StartEntryNo);
        ILE.SetRange("Item No.", ItemNo);
        ILE.SetRange("Location Code", DestLocation);
        if ReqQuantity <> 0 then
            ILE.SetRange(Quantity, Abs(ReqQuantity))
        else
            ILE.SetFilter(Quantity, '>%1', 0);

        if PostingDate <> 0D then
            ILE.SetRange("Posting Date", PostingDate);

        if ILE.FindFirst() then
            exit(ILE."Entry No.");

        exit(0);
    end;

    // ─────────────────────────────────────────────────────────────────────────────
    // BuildTransferResultsJson (igual, sin cambios)
    // ─────────────────────────────────────────────────────────────────────────────
    local procedure BuildTransferResultsJson(TransfersJSON: Text; StartEntryNo: Integer): Text
    var
        Arr: JsonArray;
        Token: JsonToken;
        Obj: JsonObject;
        Val: JsonToken;

        ResultsArr: JsonArray;
        ResultObj: JsonObject;
        SourceObj: JsonObject;
        DestObj: JsonObject;
        GomJobWarehouseQty: Record "GomJob Warehouse Quantity";

        ItemNo: Code[20];
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        Quantity: Decimal;
        DocumentNo: Code[20];
        TaskNo: Code[20];
        NewJobNo: Code[20];
        NewJobTaskNo: Code[20];
        AppliesFromEntry: Integer;

        DestILE: Record "Item Ledger Entry";
        DestEntryNo: Integer;
        PostingDate: Date;
        ResultText: Text;
    begin
        if TransfersJSON = '' then
            exit('[]');

        if not Arr.ReadFrom(TransfersJSON) then
            exit('[]');

        foreach Token in Arr do begin
            Clear(ResultObj);
            Clear(SourceObj);
            Clear(DestObj);

            Clear(ItemNo);
            Clear(LocationCode);
            Clear(NewLocationCode);
            Clear(Quantity);
            Clear(DocumentNo);
            Clear(TaskNo);
            Clear(NewJobNo);
            Clear(NewJobTaskNo);
            Clear(AppliesFromEntry);

            DestEntryNo := 0;
            PostingDate := 0D;

            if not Token.IsObject() then
                continue;

            Obj := Token.AsObject();

            if Obj.Get('itemNo', Val) and (not Val.AsValue().IsNull()) then
                ItemNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(ItemNo));

            if Obj.Get('locationCode', Val) and (not Val.AsValue().IsNull()) then
                LocationCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(LocationCode));

            if Obj.Get('newLocationCode', Val) and (not Val.AsValue().IsNull()) then
                NewLocationCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NewLocationCode));

            if Obj.Get('quantity', Val) and (not Val.AsValue().IsNull()) then
                Quantity := Val.AsValue().AsDecimal();

            if Obj.Get('documentNo', Val) and (not Val.AsValue().IsNull()) then
                DocumentNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(DocumentNo));

            if Obj.Get('taskNo', Val) and (not Val.AsValue().IsNull()) then
                TaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskNo));

            if Obj.Get('newJobNo', Val) and (not Val.AsValue().IsNull()) then
                NewJobNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NewJobNo));

            if Obj.Get('newJobTaskNo', Val) and (not Val.AsValue().IsNull()) then
                NewJobTaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NewJobTaskNo));

            if Obj.Get('appliesFromEntry', Val) and (not Val.AsValue().IsNull()) then
                AppliesFromEntry := Val.AsValue().AsInteger();

            // Buscar ILE destino (receipt)
            if (ItemNo <> '') and (NewLocationCode <> '') and (Quantity <> 0) then begin
                DestEntryNo := FindReceiptEntryNoAfterPosting(StartEntryNo, ItemNo, NewLocationCode, Quantity, PostingDate);
                if DestEntryNo <> 0 then begin
                    if DestILE.Get(DestEntryNo) then
                        PostingDate := DestILE."Posting Date";

                    if (NewJobNo <> '') and (NewJobTaskNo <> '') then begin
                        GomJobWarehouseQty.Reset();
                        GomJobWarehouseQty.SetRange("Item Ledger Entry No.", DestEntryNo);
                        GomJobWarehouseQty.SetRange("Job No.", NewJobNo);
                        GomJobWarehouseQty.SetRange("Job Task No.", NewJobTaskNo);
                        if GomJobWarehouseQty.FindFirst() then begin
                            GomJobWarehouseQty.Quantity := Abs(Quantity);
                            GomJobWarehouseQty.Modify(true);
                        end else begin
                            GomJobWarehouseQty.Init();
                            GomJobWarehouseQty."Item Ledger Entry No." := DestEntryNo;
                            GomJobWarehouseQty."Job No." := NewJobNo;
                            GomJobWarehouseQty."Job Task No." := NewJobTaskNo;
                            GomJobWarehouseQty.Quantity := Abs(Quantity);
                            GomJobWarehouseQty.Insert(true);
                        end;
                    end;
                end;
            end;

            ResultObj.Add('ok', DestEntryNo <> 0);
            ResultObj.Add('documentNo', DocumentNo);
            ResultObj.Add('itemNo', ItemNo);
            ResultObj.Add('quantity', Abs(Quantity));
            if PostingDate <> 0D then
                ResultObj.Add('postingDate', PostingDate);

            SourceObj.Add('locationCode', LocationCode);
            SourceObj.Add('taskNo', TaskNo);
            SourceObj.Add('appliesFromEntry', AppliesFromEntry);

            DestObj.Add('locationCode', NewLocationCode);
            DestObj.Add('jobNo', NewJobNo);
            DestObj.Add('jobTaskNo', NewJobTaskNo);
            DestObj.Add('entryNoALM', DestEntryNo);

            ResultObj.Add('source', SourceObj);
            ResultObj.Add('destination', DestObj);

            if DestEntryNo = 0 then
                ResultObj.Add('message', '❌ No se encontró EntryNo destino (ILE receipt)')
            else
                ResultObj.Add('message', StrSubstNo('✅ Transfer OK. EntryNo destino: %1', DestEntryNo));

            ResultsArr.Add(ResultObj);
        end;

        ResultsArr.WriteTo(ResultText);
        exit(ResultText);
    end;
}
