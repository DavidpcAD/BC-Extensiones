codeunit 50208 "GJW Item Transfer Bulk FIFO"
{
    procedure ProcessTransfersWithTrace(TransfersJSON: Text; var JsonResultsOut: Text): Text
    var
        Arr: JsonArray;
        Token: JsonToken;
        Obj: JsonObject;
        ResultsArr: JsonArray;
        ResultObj: JsonObject;
        ResultText: Text;

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
        SourceEntryNo: Integer;

        DestEntryNo: Integer;
        LineMessage: Text;

        OkCount: Integer;
        ErrorCount: Integer;
    begin
        if TransfersJSON = '' then begin
            JsonResultsOut := '[]';
            exit('ERROR: No se recibio JSON de transferencias');
        end;

        if not Arr.ReadFrom(TransfersJSON) then begin
            JsonResultsOut := '[]';
            exit('ERROR: JSON invalido');
        end;

        foreach Token in Arr do begin
            Clear(ResultObj);
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
            Clear(SourceEntryNo);
            Clear(DestEntryNo);
            Clear(LineMessage);

            if not Token.IsObject() then begin
                ErrorCount += 1;
                ResultObj.Add('ok', false);
                ResultObj.Add('message', 'Elemento de array no es objeto');
                ResultsArr.Add(ResultObj);
                continue;
            end;

            Obj := Token.AsObject();
            ReadTransferFields(Obj, ItemNo, LocationCode, NewLocationCode, Quantity, TaskNo, NewJobNo, NewJobTaskNo, Description, PostingDate, DocumentNo, VariantCode, SourceEntryNo);

            if not ValidateTransfer(ItemNo, LocationCode, NewLocationCode, Quantity, SourceEntryNo, LineMessage) then begin
                ErrorCount += 1;
                ResultObj.Add('ok', false);
                ResultObj.Add('itemNo', ItemNo);
                ResultObj.Add('sourceEntryNo', SourceEntryNo);
                ResultObj.Add('message', LineMessage);
                ResultsArr.Add(ResultObj);
                continue;
            end;

            if ExecuteSingleTransfer(ItemNo, LocationCode, NewLocationCode, Quantity, TaskNo, NewJobNo, NewJobTaskNo, Description, PostingDate, DocumentNo, VariantCode, SourceEntryNo, DestEntryNo, LineMessage) then begin
                OkCount += 1;
                ResultObj.Add('ok', true);
                ResultObj.Add('itemNo', ItemNo);
                ResultObj.Add('quantity', Abs(Quantity));
                ResultObj.Add('documentNo', DocumentNo);
                ResultObj.Add('sourceEntryNo', SourceEntryNo);
                ResultObj.Add('destinationEntryNo', DestEntryNo);
                ResultObj.Add('sourceLocationCode', LocationCode);
                ResultObj.Add('destinationLocationCode', NewLocationCode);
                ResultObj.Add('destinationJobNo', NewJobNo);
                ResultObj.Add('destinationJobTaskNo', NewJobTaskNo);
                ResultObj.Add('message', LineMessage);
            end else begin
                ErrorCount += 1;
                ResultObj.Add('ok', false);
                ResultObj.Add('itemNo', ItemNo);
                ResultObj.Add('quantity', Abs(Quantity));
                ResultObj.Add('documentNo', DocumentNo);
                ResultObj.Add('sourceEntryNo', SourceEntryNo);
                ResultObj.Add('destinationEntryNo', DestEntryNo);
                ResultObj.Add('sourceLocationCode', LocationCode);
                ResultObj.Add('destinationLocationCode', NewLocationCode);
                ResultObj.Add('destinationJobNo', NewJobNo);
                ResultObj.Add('destinationJobTaskNo', NewJobTaskNo);
                ResultObj.Add('message', LineMessage);
            end;

            ResultsArr.Add(ResultObj);
        end;

        ResultsArr.WriteTo(ResultText);
        JsonResultsOut := ResultText;

        if ErrorCount > 0 then
            exit(StrSubstNo('ERROR: %1 procesadas, %2 con error.', OkCount, ErrorCount));

        exit(StrSubstNo('OK: %1 transferencias procesadas.', OkCount));
    end;

    local procedure ReadTransferFields(Obj: JsonObject; var ItemNo: Code[20]; var LocationCode: Code[10]; var NewLocationCode: Code[10]; var Quantity: Decimal; var TaskNo: Code[20]; var NewJobNo: Code[20]; var NewJobTaskNo: Code[20]; var Description: Text[100]; var PostingDate: Date; var DocumentNo: Code[20]; var VariantCode: Code[10]; var SourceEntryNo: Integer)
    var
        TextVal: Text;
    begin
        if TryGetText(Obj, 'itemNo', TextVal) then
            ItemNo := CopyStr(TextVal, 1, MaxStrLen(ItemNo));

        if TryGetText(Obj, 'locationCode', TextVal) then
            LocationCode := CopyStr(TextVal, 1, MaxStrLen(LocationCode));

        if TryGetText(Obj, 'newLocationCode', TextVal) then
            NewLocationCode := CopyStr(TextVal, 1, MaxStrLen(NewLocationCode));

        if TryGetDecimal(Obj, 'quantity', Quantity) then;

        if TryGetText(Obj, 'taskNo', TextVal) then
            TaskNo := CopyStr(TextVal, 1, MaxStrLen(TaskNo));

        if TryGetText(Obj, 'newJobNo', TextVal) then
            NewJobNo := CopyStr(TextVal, 1, MaxStrLen(NewJobNo));

        if TryGetText(Obj, 'newJobTaskNo', TextVal) then
            NewJobTaskNo := CopyStr(TextVal, 1, MaxStrLen(NewJobTaskNo));

        if TryGetText(Obj, 'description', TextVal) then
            Description := CopyStr(TextVal, 1, MaxStrLen(Description));

        if TryGetText(Obj, 'postingDate', TextVal) then begin
            if not Evaluate(PostingDate, TextVal) then
                PostingDate := Today();
        end else
            PostingDate := Today();

        if TryGetText(Obj, 'documentNo', TextVal) then
            DocumentNo := CopyStr(TextVal, 1, MaxStrLen(DocumentNo))
        else
            DocumentNo := CopyStr('TRANS-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'), 1, MaxStrLen(DocumentNo));

        if TryGetText(Obj, 'variantCode', TextVal) then
            VariantCode := CopyStr(TextVal, 1, MaxStrLen(VariantCode));

        if TryGetInteger(Obj, 'sourceEntryNo', SourceEntryNo) then;

        if (SourceEntryNo = 0) then
            if TryGetInteger(Obj, 'appliesFromEntry', SourceEntryNo) then;
    end;

    local procedure ValidateTransfer(ItemNo: Code[20]; LocationCode: Code[10]; NewLocationCode: Code[10]; Quantity: Decimal; SourceEntryNo: Integer; var Message: Text): Boolean
    begin
        if ItemNo = '' then begin
            Message := 'itemNo es obligatorio';
            exit(false);
        end;

        if Quantity <= 0 then begin
            Message := 'quantity debe ser mayor que 0';
            exit(false);
        end;

        if LocationCode = '' then begin
            Message := 'locationCode es obligatorio';
            exit(false);
        end;

        if NewLocationCode = '' then begin
            Message := 'newLocationCode es obligatorio';
            exit(false);
        end;

        if SourceEntryNo = 0 then begin
            Message := 'sourceEntryNo/appliesFromEntry es obligatorio para trazabilidad exacta';
            exit(false);
        end;

        Message := '';
        exit(true);
    end;

    local procedure ExecuteSingleTransfer(ItemNo: Code[20]; LocationCode: Code[10]; NewLocationCode: Code[10]; Quantity: Decimal; TaskNo: Code[20]; NewJobNo: Code[20]; NewJobTaskNo: Code[20]; Description: Text[100]; PostingDate: Date; DocumentNo: Code[20]; VariantCode: Code[10]; SourceEntryNo: Integer; var DestEntryNo: Integer; var Message: Text): Boolean
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        StartEntryNo: Integer;
        ErrorMsg: Text;
    begin
        DestEntryNo := 0;

        PrepareBatch(ItemJnlLine);

        if not InsertTransferLine(ItemJnlLine, ItemNo, LocationCode, NewLocationCode, Quantity, TaskNo, NewJobNo, NewJobTaskNo, Description, PostingDate, DocumentNo, VariantCode, SourceEntryNo) then begin
            Message := 'No se pudo crear linea de transferencia';
            exit(false);
        end;

        Commit();

        StartEntryNo := GetLastILEEntryNo();

        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'TRANSFEREN');
        ItemJnlLine.SetRange("Journal Batch Name", 'GENERICO');

        Clear(ItemJnlPostBatch);
        ClearLastError();
        if not Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJnlLine) then begin
            ErrorMsg := GetLastErrorText();
            if ErrorMsg = '' then
                ErrorMsg := 'Error desconocido en posting';
            Message := ErrorMsg;
            exit(false);
        end;

        DestEntryNo := FindDestinationEntryAfterPosting(StartEntryNo, ItemNo, NewLocationCode, Quantity, PostingDate, DocumentNo);
        if DestEntryNo = 0 then begin
            Message := 'No se encontro destinationEntryNo para la transferencia';
            exit(false);
        end;

        if (NewJobNo <> '') and (NewJobTaskNo <> '') then
            UpsertDestinationWarehouseQty(DestEntryNo, NewJobNo, NewJobTaskNo, Quantity);

        Message := StrSubstNo('Transferencia OK. sourceEntryNo=%1, destinationEntryNo=%2', SourceEntryNo, DestEntryNo);
        exit(true);
    end;

    local procedure PrepareBatch(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'TRANSFEREN');
        ItemJnlLine.SetRange("Journal Batch Name", 'GENERICO');
        if ItemJnlLine.FindSet() then
            ItemJnlLine.DeleteAll(true);
    end;

    local procedure InsertTransferLine(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; NewLocationCode: Code[10]; Quantity: Decimal; TaskNo: Code[20]; NewJobNo: Code[20]; NewJobTaskNo: Code[20]; Description: Text[100]; PostingDate: Date; DocumentNo: Code[20]; VariantCode: Code[10]; SourceEntryNo: Integer): Boolean
    var
        Item: Record Item;
        SourceILE: Record "Item Ledger Entry";
    begin
        if not SourceILE.Get(SourceEntryNo) then
            Error('sourceEntryNo %1 no existe', SourceEntryNo);

        if SourceILE.Open = false then
            Error('sourceEntryNo %1 esta cerrado', SourceEntryNo);

        if SourceILE.Positive then
            Error('sourceEntryNo %1 debe ser salida/consumo previo, no entrada positiva', SourceEntryNo);

        if SourceILE."Item No." <> ItemNo then
            Error('sourceEntryNo %1 no corresponde a itemNo %2', SourceEntryNo, ItemNo);

        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'TRANSFEREN';
        ItemJnlLine."Journal Batch Name" := 'GENERICO';
        ItemJnlLine."Line No." := 10000;

        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."Posting Date" := PostingDate;
        ItemJnlLine."Document No." := DocumentNo;

        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate("Location Code", LocationCode);
        ItemJnlLine.Validate("New Location Code", NewLocationCode);

        if Item.Get(ItemNo) then
            ItemJnlLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");

        if VariantCode <> '' then
            ItemJnlLine.Validate("Variant Code", VariantCode);

        if Description <> '' then
            ItemJnlLine.Description := Description;

        if TaskNo <> '' then
            ItemJnlLine."Task No." := TaskNo;

        if NewJobNo <> '' then
            ItemJnlLine."New Job No." := NewJobNo;

        if NewJobTaskNo <> '' then
            ItemJnlLine."New Job Task No." := NewJobTaskNo;

        ItemJnlLine.Validate(Quantity, Abs(Quantity));
        ItemJnlLine."Applies-from Entry" := SourceEntryNo;

        exit(ItemJnlLine.Insert(true));
    end;

    local procedure FindDestinationEntryAfterPosting(StartEntryNo: Integer; ItemNo: Code[20]; NewLocationCode: Code[10]; Quantity: Decimal; PostingDate: Date; DocumentNo: Code[20]): Integer
    var
        ILE: Record "Item Ledger Entry";
    begin
        ILE.Reset();
        ILE.SetCurrentKey("Entry No.");
        ILE.SetFilter("Entry No.", '>%1', StartEntryNo);
        ILE.SetRange("Item No.", ItemNo);
        ILE.SetRange("Location Code", NewLocationCode);
        ILE.SetRange(Positive, true);
        ILE.SetRange(Quantity, Abs(Quantity));

        if PostingDate <> 0D then
            ILE.SetRange("Posting Date", PostingDate);

        if DocumentNo <> '' then
            ILE.SetRange("Document No.", DocumentNo);

        if ILE.FindFirst() then
            exit(ILE."Entry No.");

        exit(0);
    end;

    local procedure UpsertDestinationWarehouseQty(DestEntryNo: Integer; NewJobNo: Code[20]; NewJobTaskNo: Code[20]; Quantity: Decimal)
    var
        WarehouseQty: Record "GomJob Warehouse Quantity";
        JobTask: Record "Job Task";
    begin
        if not JobTask.Get(NewJobNo, NewJobTaskNo) then
            exit;

        if WarehouseQty.Get(DestEntryNo, NewJobNo, NewJobTaskNo) then begin
            WarehouseQty.Quantity := Abs(Quantity);
            WarehouseQty.Modify(true);
            exit;
        end;

        WarehouseQty.Init();
        WarehouseQty."Item Ledger Entry No." := DestEntryNo;
        WarehouseQty."Job No." := NewJobNo;
        WarehouseQty."Job Task No." := NewJobTaskNo;
        WarehouseQty."Job Task Description" := JobTask.Description;
        WarehouseQty.Quantity := Abs(Quantity);
        WarehouseQty.Insert(true);
    end;

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

    local procedure TryGetText(Obj: JsonObject; Name: Text; var ValueText: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not Obj.Get(Name, Token) then
            exit(false);

        if Token.AsValue().IsNull() then
            exit(false);

        ValueText := Token.AsValue().AsText();
        exit(true);
    end;

    local procedure TryGetDecimal(Obj: JsonObject; Name: Text; var ValueDecimal: Decimal): Boolean
    var
        TextVal: Text;
    begin
        if not TryGetText(Obj, Name, TextVal) then
            exit(false);

        exit(Evaluate(ValueDecimal, TextVal));
    end;

    local procedure TryGetInteger(Obj: JsonObject; Name: Text; var ValueInteger: Integer): Boolean
    var
        TextVal: Text;
    begin
        if not TryGetText(Obj, Name, TextVal) then
            exit(false);

        exit(Evaluate(ValueInteger, TextVal));
    end;
}
