namespace Adelante.Inventory;

codeunit 50222 "GJW Material Op Bulk Proc"
{
    procedure ProcessRequest(RequestJson: Text): Text
    var
        Root: JsonObject;
        LinesTok: JsonToken;
        Lines: JsonArray;
        LineTok: JsonToken;
        LineObj: JsonObject;
        ResultObj: JsonObject;
        ResponseObj: JsonObject;
        ResultsArr: JsonArray;
        Op: Record "GJW Material Operation";
        i: Integer;
        TotalLines: Integer;
        ClosedLines: Integer;
        FailedLines: Integer;
        MaxSteps: Integer;
        Qty: Decimal;
        DocumentNo: Text;
        OperationTypeTxt: Text;
        HeaderVariantCode: Text;
        ItemNoTxt: Text;
        VariantCodeTxt: Text;
        SourceJobNoTxt: Text;
        SourceJobTaskNoTxt: Text;
        SourceLocationCodeTxt: Text;
        DestinationJobNoTxt: Text;
        DestinationJobTaskNoTxt: Text;
        DestinationLocationCodeTxt: Text;
        ExecMsg: Text;
        LineErr: Text;
    begin
        if RequestJson = '' then
            Error('requestJson es requerido.');

        if not Root.ReadFrom(RequestJson) then
            Error('requestJson invalido. Debe ser objeto JSON.');

        DocumentNo := GetOptionalText(Root, 'documentNo');
        if DocumentNo = '' then
            DocumentNo := GetOptionalTextFromObject(Root, 'encabezado', 'boletaNo');
        if DocumentNo = '' then
            Error('documentNo es requerido.');

        OperationTypeTxt := GetRequiredText(Root, 'operationType');
        HeaderVariantCode := GetOptionalText(Root, 'variantCode');
        MaxSteps := GetOptionalInteger(Root, 'maxSteps', 5);
        if MaxSteps <= 0 then
            MaxSteps := 5;

        if not Root.Get('lines', LinesTok) then
            if not Root.Get('lineas', LinesTok) then
                Error('lines es requerido.');
        if not LinesTok.IsArray() then
            Error('lines debe ser arreglo JSON.');

        Lines := LinesTok.AsArray();
        TotalLines := Lines.Count();
        if TotalLines = 0 then
            Error('lines debe traer al menos una linea.');

        for i := 0 to TotalLines - 1 do begin
            Clear(ResultObj);
            Clear(ExecMsg);
            Clear(LineErr);

            ResultObj.Add('lineNo', i + 1);

            if not Lines.Get(i, LineTok) then begin
                FailedLines += 1;
                ResultObj.Add('success', false);
                ResultObj.Add('error', 'No se pudo leer la linea.');
                ResultsArr.Add(ResultObj);
                continue;
            end;

            if not LineTok.IsObject() then begin
                FailedLines += 1;
                ResultObj.Add('success', false);
                ResultObj.Add('error', 'Cada linea debe ser un objeto JSON.');
                ResultsArr.Add(ResultObj);
                continue;
            end;

            LineObj := LineTok.AsObject();
            ItemNoTxt := GetOptionalText(LineObj, 'itemNo');
            VariantCodeTxt := GetOptionalText(LineObj, 'variantCode');
            if VariantCodeTxt = '' then
                VariantCodeTxt := HeaderVariantCode;

            ResultObj.Add('itemNo', ItemNoTxt);
            ResultObj.Add('variantCode', VariantCodeTxt);

            if ItemNoTxt = '' then begin
                FailedLines += 1;
                ResultObj.Add('success', false);
                ResultObj.Add('error', 'itemNo es requerido por linea.');
                ResultsArr.Add(ResultObj);
                continue;
            end;

            Qty := GetOptionalDecimal(LineObj, 'quantity', 0);
            if Qty <= 0 then
                Qty := GetOptionalDecimal(LineObj, 'cantidad', 0);
            ResultObj.Add('quantity', Qty);

            if Qty <= 0 then begin
                FailedLines += 1;
                ResultObj.Add('success', false);
                ResultObj.Add('error', 'quantity debe ser mayor que 0 por linea.');
                ResultsArr.Add(ResultObj);
                continue;
            end;

            Op.Init();
            Op."Document No." := CopyStr(DocumentNo, 1, MaxStrLen(Op."Document No."));
            ApplyOperationType(Op, OperationTypeTxt);

            SourceJobNoTxt := GetOptionalText(LineObj, 'sourceJobNo');
            if SourceJobNoTxt = '' then
                SourceJobNoTxt := GetOptionalText(Root, 'sourceJobNo');
            if SourceJobNoTxt = '' then
                SourceJobNoTxt := GetOptionalText(Root, 'jobNo');
            if SourceJobNoTxt = '' then
                SourceJobNoTxt := GetOptionalTextFromObject(Root, 'encabezado', 'jobNo');

            SourceJobTaskNoTxt := GetOptionalText(LineObj, 'sourceJobTaskNo');
            if SourceJobTaskNoTxt = '' then
                SourceJobTaskNoTxt := GetOptionalText(LineObj, 'sourceTaskNo');
            if SourceJobTaskNoTxt = '' then
                SourceJobTaskNoTxt := GetOptionalText(Root, 'sourceJobTaskNo');
            if SourceJobTaskNoTxt = '' then
                SourceJobTaskNoTxt := GetOptionalText(Root, 'taskNo');
            if SourceJobTaskNoTxt = '' then
                SourceJobTaskNoTxt := GetOptionalTextFromObject(Root, 'encabezado', 'taskNo');

            SourceLocationCodeTxt := GetOptionalText(LineObj, 'sourceLocationCode');
            if SourceLocationCodeTxt = '' then
                SourceLocationCodeTxt := GetOptionalText(Root, 'sourceLocationCode');
            if SourceLocationCodeTxt = '' then
                SourceLocationCodeTxt := GetOptionalText(Root, 'locationCode');
            if SourceLocationCodeTxt = '' then
                SourceLocationCodeTxt := GetOptionalTextFromObject(Root, 'encabezado', 'locationCode');

            DestinationJobNoTxt := GetOptionalText(LineObj, 'destinationJobNo');
            if DestinationJobNoTxt = '' then
                DestinationJobNoTxt := GetOptionalText(LineObj, 'newJobNo');
            if DestinationJobNoTxt = '' then
                DestinationJobNoTxt := GetOptionalText(Root, 'destinationJobNo');
            if DestinationJobNoTxt = '' then
                DestinationJobNoTxt := GetOptionalText(Root, 'newJobNo');

            DestinationJobTaskNoTxt := GetOptionalText(LineObj, 'destinationJobTaskNo');
            if DestinationJobTaskNoTxt = '' then
                DestinationJobTaskNoTxt := GetOptionalText(LineObj, 'newJobTaskNo');
            if DestinationJobTaskNoTxt = '' then
                DestinationJobTaskNoTxt := GetOptionalText(Root, 'destinationJobTaskNo');
            if DestinationJobTaskNoTxt = '' then
                DestinationJobTaskNoTxt := GetOptionalText(Root, 'newJobTaskNo');

            DestinationLocationCodeTxt := GetOptionalText(LineObj, 'destinationLocationCode');
            if DestinationLocationCodeTxt = '' then
                DestinationLocationCodeTxt := GetOptionalText(LineObj, 'newLocationCode');
            if DestinationLocationCodeTxt = '' then
                DestinationLocationCodeTxt := GetOptionalText(Root, 'destinationLocationCode');
            if DestinationLocationCodeTxt = '' then
                DestinationLocationCodeTxt := GetOptionalText(Root, 'newLocationCode');

            Op."Source Job No." := CopyStr(SourceJobNoTxt, 1, MaxStrLen(Op."Source Job No."));
            Op."Source Job Task No." := CopyStr(SourceJobTaskNoTxt, 1, MaxStrLen(Op."Source Job Task No."));
            Op."Source Location Code" := CopyStr(SourceLocationCodeTxt, 1, MaxStrLen(Op."Source Location Code"));
            Op."Destination Job No." := CopyStr(DestinationJobNoTxt, 1, MaxStrLen(Op."Destination Job No."));
            Op."Destination Job Task No." := CopyStr(DestinationJobTaskNoTxt, 1, MaxStrLen(Op."Destination Job Task No."));
            Op."Destination Location Code" := CopyStr(DestinationLocationCodeTxt, 1, MaxStrLen(Op."Destination Location Code"));
            Op."Item No." := CopyStr(ItemNoTxt, 1, MaxStrLen(Op."Item No."));
            Op."Variant Code" := CopyStr(VariantCodeTxt, 1, MaxStrLen(Op."Variant Code"));
            Op.Quantity := Qty;

            if not TryStartAndRunOperation(Op, MaxSteps, ExecMsg) then begin
                LineErr := GetLastErrorText();
                FailedLines += 1;
                ResultObj.Add('success', false);
                ResultObj.Add('operationId', Format(Op."Operation Id"));
                ResultObj.Add('status', 'Failed');
                ResultObj.Add('message', ExecMsg);
                ResultObj.Add('error', LineErr);
                ResultsArr.Add(ResultObj);
                continue;
            end;

            if Op.Get(Op."Operation Id") then begin
                ResultObj.Add('operationId', Format(Op."Operation Id"));
                ResultObj.Add('status', Format(Op.Status));
                ResultObj.Add('currentStep', Format(Op."Current Step"));
                ResultObj.Add('entryNos', Op."Last BC Entry Nos");
                ResultObj.Add('lastError', Op."Last Error");

                if Op.Status = Op.Status::Closed then begin
                    ClosedLines += 1;
                    ResultObj.Add('success', true);
                end else begin
                    FailedLines += 1;
                    ResultObj.Add('success', false);
                end;
            end else begin
                FailedLines += 1;
                ResultObj.Add('success', false);
                ResultObj.Add('operationId', Format(Op."Operation Id"));
                ResultObj.Add('status', 'Unknown');
            end;

            ResultObj.Add('message', ExecMsg);
            ResultsArr.Add(ResultObj);
        end;

        ResponseObj.Add('ok', FailedLines = 0);
        ResponseObj.Add('documentNo', DocumentNo);
        ResponseObj.Add('operationType', OperationTypeTxt);
        ResponseObj.Add('totalLines', TotalLines);
        ResponseObj.Add('closedLines', ClosedLines);
        ResponseObj.Add('failedLines', FailedLines);
        ResponseObj.Add('results', ResultsArr);
        ResponseObj.WriteTo(RequestJson);

        exit(RequestJson);
    end;

    [TryFunction]
    local procedure TryStartAndRunOperation(var Op: Record "GJW Material Operation"; MaxSteps: Integer; var ExecMsg: Text)
    var
        Orchestrator: Codeunit "GJW Material Op Orchestrator";
    begin
        // OnInsert de la tabla resetea Status/Current Step a PendingReverse/Reverse
        // de forma incondicional. Por eso StartOperation (que ajusta el estado
        // inicial segun el tipo, p.ej. ConsumeFromGeneral salta Reverse) debe
        // correr DESPUES del Insert y persistirse con Modify; si no, OnInsert pisa
        // el estado y el consumo termina ejecutando RunReverse contra un consumo
        // inexistente. Mismo orden que usa la page API single (OnInsertRecord).
        Op.Insert(true);
        ExecMsg := Orchestrator.StartOperation(Op);
        Op.Modify(true);
        ExecMsg := Orchestrator.ExecuteUntilStop(Op."Operation Id", MaxSteps);
    end;

    local procedure ApplyOperationType(var Op: Record "GJW Material Operation"; OperationTypeTxt: Text)
    begin
        case UpperCase(OperationTypeTxt) of
            'CONSUMEFROMGENERAL':
                Op."Operation Type" := Op."Operation Type"::ConsumeFromGeneral;
            'TRANSFERCONSUMEDBETWEENJOBS':
                Op."Operation Type" := Op."Operation Type"::TransferConsumedBetweenJobs;
            'RETURNCONSUMEDTOGENERAL':
                Op."Operation Type" := Op."Operation Type"::ReturnConsumedToGeneral;
            else
                Error('operationType invalido. Valores: ConsumeFromGeneral, TransferConsumedBetweenJobs, ReturnConsumedToGeneral.');
        end;
    end;

    local procedure GetRequiredText(var Obj: JsonObject; NameTxt: Text): Text
    var
        Txt: Text;
    begin
        Txt := GetOptionalText(Obj, NameTxt);
        if Txt = '' then
            Error('%1 es requerido.', NameTxt);

        exit(Txt);
    end;

    local procedure GetOptionalText(var Obj: JsonObject; NameTxt: Text): Text
    var
        Tok: JsonToken;
    begin
        if not Obj.Get(NameTxt, Tok) then
            exit('');

        if not Tok.IsValue() then
            exit('');

        exit(Tok.AsValue().AsText());
    end;

    local procedure GetOptionalTextFromObject(var Obj: JsonObject; ParentNameTxt: Text; NameTxt: Text): Text
    var
        Tok: JsonToken;
        ParentObj: JsonObject;
    begin
        if not Obj.Get(ParentNameTxt, Tok) then
            exit('');

        if not Tok.IsObject() then
            exit('');

        ParentObj := Tok.AsObject();
        exit(GetOptionalText(ParentObj, NameTxt));
    end;

    local procedure GetOptionalInteger(var Obj: JsonObject; NameTxt: Text; DefaultValue: Integer): Integer
    var
        Txt: Text;
        Parsed: Integer;
    begin
        if TryReadIntegerValue(Obj, NameTxt, Parsed) then
            exit(Parsed);

        Txt := GetOptionalText(Obj, NameTxt);
        if Txt = '' then
            exit(DefaultValue);

        if Evaluate(Parsed, Txt) then
            exit(Parsed);

        exit(DefaultValue);
    end;

    local procedure GetOptionalDecimal(var Obj: JsonObject; NameTxt: Text; DefaultValue: Decimal): Decimal
    var
        Txt: Text;
        Parsed: Decimal;
    begin
        if TryReadDecimalValue(Obj, NameTxt, Parsed) then
            exit(Parsed);

        Txt := GetOptionalText(Obj, NameTxt);
        if Txt = '' then
            exit(DefaultValue);

        if Evaluate(Parsed, Txt) then
            exit(Parsed);

        exit(DefaultValue);
    end;

    [TryFunction]
    local procedure TryReadIntegerValue(var Obj: JsonObject; NameTxt: Text; var Parsed: Integer)
    var
        Tok: JsonToken;
    begin
        if not Obj.Get(NameTxt, Tok) then
            Error('%1 not found.', NameTxt);
        if not Tok.IsValue() then
            Error('%1 not value.', NameTxt);

        Parsed := Tok.AsValue().AsInteger();
    end;

    [TryFunction]
    local procedure TryReadDecimalValue(var Obj: JsonObject; NameTxt: Text; var Parsed: Decimal)
    var
        Tok: JsonToken;
    begin
        if not Obj.Get(NameTxt, Tok) then
            Error('%1 not found.', NameTxt);
        if not Tok.IsValue() then
            Error('%1 not value.', NameTxt);

        Parsed := Tok.AsValue().AsDecimal();
    end;
}
