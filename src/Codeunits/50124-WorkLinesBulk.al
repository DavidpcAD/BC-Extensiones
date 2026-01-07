codeunit 50124 "GJW WorkLines Bulk"
{
    [ServiceEnabled]
    procedure Import(jsonNuevos: Text; jsonEditados: Text; jsonEliminados: Text): Text;
    var
        Arr: JsonArray;
        Token: JsonToken;
        Obj: JsonObject;
        Val: JsonToken;

        WorkLine: Record "GomJob Works Line";
        Existing: Record "GomJob Works Line";

        InsCount: Integer;
        UpdCount: Integer;
        DelCount: Integer;
        ErrorCount: Integer;

        WorksNo: Code[20];
        VersionCode: Code[20];
        LineNo: Integer;
        LineTypeTxt: Code[50];
        TaskTypeTxt: Code[50];
        TaskNo: Code[50];
        Description: Text[250];
        Quantity: Decimal;
        UnitAmount: Decimal;
        LineAmount: Decimal;
        QuantityToProduce: Decimal;
        UnitOfMeasure: Code[10];
        CodeOrder: Code[50];
        IdEncargado: Integer;
        ReStudy: Boolean;

        HasSystemId: Boolean;
        SystemIdTxt: Text;
        SystemIdGuid: Guid;
    begin
        // 1) Insertar nuevos
        if jsonNuevos <> '' then
            if Arr.ReadFrom(jsonNuevos) then
                foreach Token in Arr do begin
                    if Token.IsObject() then begin
                        Obj := Token.AsObject();
                        Clear(WorksNo);
                        Clear(VersionCode);
                        Clear(LineNo);
                        Clear(LineTypeTxt);
                        Clear(TaskTypeTxt);
                        Clear(TaskNo);
                        Clear(Description);
                        Clear(Quantity);
                        Clear(UnitAmount);
                        Clear(LineAmount);
                        Clear(QuantityToProduce);
                        Clear(UnitOfMeasure);
                        Clear(CodeOrder);
                        Clear(IdEncargado);
                        ReStudy := false;

                        if Obj.Get('worksNo', Val) and (not Val.AsValue().IsNull()) then WorksNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(WorksNo));
                        if Obj.Get('versionCode', Val) and (not Val.AsValue().IsNull()) then VersionCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(VersionCode));
                        if Obj.Get('lineNo', Val) and (not Val.AsValue().IsNull()) then LineNo := Val.AsValue().AsInteger();
                        if Obj.Get('lineType', Val) and (not Val.AsValue().IsNull()) then LineTypeTxt := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(LineTypeTxt));
                        if Obj.Get('taskType', Val) and (not Val.AsValue().IsNull()) then TaskTypeTxt := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskTypeTxt));
                        if Obj.Get('taskNo', Val) and (not Val.AsValue().IsNull()) then TaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskNo));
                        if Obj.Get('description', Val) and (not Val.AsValue().IsNull()) then Description := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(Description));
                        if Obj.Get('quantity', Val) and (not Val.AsValue().IsNull()) then Quantity := Val.AsValue().AsDecimal();
                        if Obj.Get('unitAmount', Val) and (not Val.AsValue().IsNull()) then UnitAmount := Val.AsValue().AsDecimal();
                        if Obj.Get('lineAmount', Val) and (not Val.AsValue().IsNull()) then LineAmount := Val.AsValue().AsDecimal();
                        if Obj.Get('quantityToProduce', Val) and (not Val.AsValue().IsNull()) then QuantityToProduce := Val.AsValue().AsDecimal();
                        if Obj.Get('unitOfMeasure', Val) and (not Val.AsValue().IsNull()) then UnitOfMeasure := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(UnitOfMeasure));
                        if Obj.Get('codeOrder', Val) and (not Val.AsValue().IsNull()) then CodeOrder := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(CodeOrder));
                        if Obj.Get('idEncargado', Val) and (not Val.AsValue().IsNull()) then IdEncargado := Val.AsValue().AsInteger();
                        if Obj.Get('reStudy', Val) and (not Val.AsValue().IsNull()) then ReStudy := Val.AsValue().AsBoolean();

                        if WorksNo = '' then
                            ErrorCount += 1
                        else if InitAndInsert(WorkLine, WorksNo, VersionCode, LineNo, LineTypeTxt, TaskTypeTxt, TaskNo, Description, Quantity, UnitAmount, LineAmount, QuantityToProduce, UnitOfMeasure, CodeOrder, IdEncargado, ReStudy) then begin
                            InsCount += 1;
                            Commit();
                        end else
                            ErrorCount += 1;
                    end else
                        ErrorCount += 1;
                end;

        // 2) Actualizar existentes
        if jsonEditados <> '' then
            if Arr.ReadFrom(jsonEditados) then
                foreach Token in Arr do begin
                    if Token.IsObject() then begin
                        Obj := Token.AsObject();

                        Clear(SystemIdTxt);
                        HasSystemId := false;
                        if Obj.Get('id', Val) and (not Val.AsValue().IsNull()) then begin
                            SystemIdTxt := Val.AsValue().AsText();
                            if TryStrToGuid(SystemIdTxt, SystemIdGuid) then
                                HasSystemId := true;
                        end;

                        if HasSystemId and WorkLine.GetBySystemId(SystemIdGuid) then begin
                            // Solo asignar campos que vienen en el JSON (preservar existentes)
                            if Obj.Get('worksNo', Val) and (not Val.AsValue().IsNull()) then WorksNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(WorksNo)) else WorksNo := WorkLine."Works No.";
                            if Obj.Get('versionCode', Val) and (not Val.AsValue().IsNull()) then VersionCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(VersionCode)) else VersionCode := WorkLine."Version Code";
                            if Obj.Get('lineNo', Val) and (not Val.AsValue().IsNull()) then LineNo := Val.AsValue().AsInteger() else LineNo := WorkLine."Line No.";
                            if Obj.Get('lineType', Val) and (not Val.AsValue().IsNull()) then LineTypeTxt := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(LineTypeTxt)) else LineTypeTxt := Format(WorkLine."Line Type");
                            if Obj.Get('taskType', Val) and (not Val.AsValue().IsNull()) then TaskTypeTxt := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskTypeTxt)) else TaskTypeTxt := Format(WorkLine."Task Type");
                            if Obj.Get('taskNo', Val) and (not Val.AsValue().IsNull()) then TaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskNo)) else TaskNo := WorkLine."Task No.";
                            if Obj.Get('description', Val) and (not Val.AsValue().IsNull()) then Description := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(Description)) else Description := WorkLine.Description;
                            if Obj.Get('quantity', Val) and (not Val.AsValue().IsNull()) then Quantity := Val.AsValue().AsDecimal() else Quantity := WorkLine.Quantity;
                            if Obj.Get('unitAmount', Val) and (not Val.AsValue().IsNull()) then UnitAmount := Val.AsValue().AsDecimal() else UnitAmount := WorkLine."Unit Amount";
                            if Obj.Get('lineAmount', Val) and (not Val.AsValue().IsNull()) then LineAmount := Val.AsValue().AsDecimal() else LineAmount := WorkLine."Line Amount";
                            if Obj.Get('quantityToProduce', Val) and (not Val.AsValue().IsNull()) then QuantityToProduce := Val.AsValue().AsDecimal() else QuantityToProduce := WorkLine."Quantity to Produce";
                            if Obj.Get('unitOfMeasure', Val) and (not Val.AsValue().IsNull()) then UnitOfMeasure := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(UnitOfMeasure)) else UnitOfMeasure := WorkLine."Unit of Measure";
                            if Obj.Get('codeOrder', Val) and (not Val.AsValue().IsNull()) then CodeOrder := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(CodeOrder)) else CodeOrder := WorkLine."Code Order";
                            if Obj.Get('idEncargado', Val) and (not Val.AsValue().IsNull()) then IdEncargado := Val.AsValue().AsInteger() else IdEncargado := WorkLine."ID Encargado";
                            if Obj.Get('reStudy', Val) and (not Val.AsValue().IsNull()) then ReStudy := Val.AsValue().AsBoolean() else ReStudy := WorkLine."Re-Study";

                            if UpdateLine(WorkLine, WorksNo, VersionCode, LineNo, LineTypeTxt, TaskTypeTxt, TaskNo, Description, Quantity, UnitAmount, LineAmount, QuantityToProduce, UnitOfMeasure, CodeOrder, IdEncargado, ReStudy) then begin
                                UpdCount += 1;
                                Commit();
                            end else
                                ErrorCount += 1;
                        end else
                            ErrorCount += 1;
                    end else
                        ErrorCount += 1;
                end;

        // 3) Eliminar registros
        if jsonEliminados <> '' then
            if Arr.ReadFrom(jsonEliminados) then
                foreach Token in Arr do begin
                    if Token.IsObject() then begin
                        Obj := Token.AsObject();
                        if Obj.Get('id', Val) and (not Val.AsValue().IsNull()) then begin
                            SystemIdTxt := Val.AsValue().AsText();
                            if TryStrToGuid(SystemIdTxt, SystemIdGuid) then
                                if Existing.GetBySystemId(SystemIdGuid) then
                                    if Existing.Delete(true) then begin
                                        DelCount += 1;
                                        Commit();
                                    end else
                                        ErrorCount += 1;
                        end;
                    end;
                end;

        // 4) Resultado
        if ErrorCount > 0 then
            exit(Format(InsCount) + ' insertados, ' + Format(UpdCount) + ' actualizados, ' + Format(DelCount) + ' eliminados. ' + Format(ErrorCount) + ' errores.')
        else
            exit(Format(InsCount) + ' insertados, ' + Format(UpdCount) + ' actualizados, ' + Format(DelCount) + ' eliminados.');
    end;

    local procedure InitAndInsert(var RecLine: Record "GomJob Works Line";
        WorksNo: Code[20]; VersionCode: Code[20]; LineNo: Integer; LineTypeTxt: Code[50]; TaskTypeTxt: Code[50]; TaskNo: Code[50];
        Description: Text[250]; Quantity: Decimal; UnitAmount: Decimal; LineAmount: Decimal; QuantityToProduce: Decimal; UnitOfMeasure: Code[10];
        CodeOrder: Code[50]; IdEncargado: Integer; ReStudy: Boolean): Boolean
    begin
        RecLine.Init();
        if LineNo = 0 then
            LineNo := GetNextLineNo(WorksNo);
        RecLine."Line No." := LineNo;
        if not SetLineFields(RecLine, WorksNo, VersionCode, LineTypeTxt, TaskTypeTxt, TaskNo, Description, Quantity, UnitAmount, LineAmount, QuantityToProduce, UnitOfMeasure, CodeOrder, IdEncargado, ReStudy, true) then
            exit(false);
        exit(RecLine.Insert(true));
    end;

    local procedure UpdateLine(var RecLine: Record "GomJob Works Line";
        WorksNo: Code[20]; VersionCode: Code[20]; LineNo: Integer; LineTypeTxt: Code[50]; TaskTypeTxt: Code[50]; TaskNo: Code[50];
        Description: Text[250]; Quantity: Decimal; UnitAmount: Decimal; LineAmount: Decimal; QuantityToProduce: Decimal; UnitOfMeasure: Code[10];
        CodeOrder: Code[50]; IdEncargado: Integer; ReStudy: Boolean): Boolean
    begin
        if not SetLineFields(RecLine, WorksNo, VersionCode, LineTypeTxt, TaskTypeTxt, TaskNo, Description, Quantity, UnitAmount, LineAmount, QuantityToProduce, UnitOfMeasure, CodeOrder, IdEncargado, ReStudy, false) then
            exit(false);
        if LineNo <> 0 then
            RecLine."Line No." := LineNo;
        exit(RecLine.Modify(true));
    end;

    local procedure SetLineFields(var RecLine: Record "GomJob Works Line";
        WorksNo: Code[20]; VersionCode: Code[20]; LineTypeTxt: Code[50]; TaskTypeTxt: Code[50]; TaskNo: Code[50];
        Description: Text[250]; Quantity: Decimal; UnitAmount: Decimal; LineAmount: Decimal; QuantityToProduce: Decimal; UnitOfMeasure: Code[10];
        CodeOrder: Code[50]; IdEncargado: Integer; ReStudy: Boolean; IsInsert: Boolean): Boolean
    var
        LineTypeEnum: Enum "GomJob Works Line Type";
        TaskTypeOpt: Option Posting,Heading,Total;
    begin
        RecLine."Works No." := WorksNo;
        RecLine."Version Code" := VersionCode;

        if (LineTypeTxt <> '') then
            if not Evaluate(LineTypeEnum, LineTypeTxt) then
                exit(false)
            else
                RecLine."Line Type" := LineTypeEnum;

        if (TaskTypeTxt <> '') then
            if not Evaluate(TaskTypeOpt, TaskTypeTxt) then
                exit(false)
            else
                RecLine."Task Type" := TaskTypeOpt;
        RecLine."Task No." := TaskNo;
        RecLine.Description := Description;
        if Quantity <> 0 then
            RecLine.Quantity := Quantity;
        RecLine."Unit Amount" := UnitAmount;
        if LineAmount <> 0 then
            RecLine."Line Amount" := LineAmount;
        if QuantityToProduce <> 0 then
            RecLine."Quantity to Produce" := QuantityToProduce;
        RecLine."Unit of Measure" := UnitOfMeasure;
        RecLine."Code Order" := CodeOrder;
        RecLine."ID Encargado" := IdEncargado;
        RecLine."Re-Study" := ReStudy;
        exit(true);
    end;

    local procedure GetNextLineNo(WorksNo: Code[20]): Integer
    var
        Tmp: Record "GomJob Works Line";
    begin
        Tmp.SetRange("Works No.", WorksNo);
        if Tmp.FindLast() then
            exit(Tmp."Line No." + 10000)
        else
            exit(10000);
    end;

    local procedure TryStrToGuid(TextGuid: Text; var OutGuid: Guid): Boolean
    var
        TempGuid: Guid;
    begin
        if TextGuid = '' then
            exit(false);
        if Evaluate(TempGuid, TextGuid) then begin
            OutGuid := TempGuid;
            exit(true);
        end else
            exit(false);
    end;
}
