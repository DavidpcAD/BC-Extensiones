codeunit 50114 "GJW WorksDecomp Bulk"
{
    [ServiceEnabled]
    procedure Import(jsonNuevos: Text; jsonEditados: Text; jsonEliminados: Text): Text;
    var
        Arr: JsonArray;
        Token: JsonToken;
        Obj: JsonObject;
        Val: JsonToken;

        WorkLine: Record "GomJob Works Decomposed Lines";
        Existing: Record "GomJob Works Decomposed Lines";

        InsCount: Integer;
        UpdCount: Integer;
        DelCount: Integer;
        ErrorCount: Integer;

        ErrNonObj: Integer;
        ErrWorksNoMissing: Integer;
        ErrIdMissing: Integer;
        ErrIdNotFound: Integer;
        ErrDeleteFailed: Integer;

        WorksNo: Code[20];
        LineNo: Integer;
        TaskNo: Code[50];
        TaskTypeTxt: Code[50];
        Description: Text[250];
        UnitCost: Decimal;
        UnitAmount: Decimal;
        LineAmount: Decimal;
        NoValue: Code[50];
        CodeOrder: Code[50];
        VariantCode: Code[50];
        Performance: Decimal;

        HasSystemId: Boolean;
        SystemIdTxt: Text;
        SystemIdGuid: Guid;
        LastError: Text;
    begin
        // 🔹 1️⃣ INSERTAR NUEVOS
        if jsonNuevos <> '' then begin
            if Arr.ReadFrom(jsonNuevos) then begin
                foreach Token in Arr do begin
                    Clear(LastError);
                    if not Token.IsObject() then begin
                        ErrorCount += 1;
                        ErrNonObj += 1;
                    end else begin

                        Obj := Token.AsObject();

                        Clear(WorksNo);
                        Clear(LineNo);
                        Clear(TaskNo);
                        Clear(TaskTypeTxt);
                        Clear(Description);
                        Clear(UnitCost);
                        Clear(UnitAmount);
                        Clear(LineAmount);
                        Clear(NoValue);
                        Clear(CodeOrder);
                        Clear(VariantCode);
                        Clear(Performance);

                        if Obj.Get('worksNo', Val) and (not Val.AsValue().IsNull()) then WorksNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(WorksNo));
                        if Obj.Get('lineNo', Val) and (not Val.AsValue().IsNull()) then LineNo := Val.AsValue().AsInteger();
                        if Obj.Get('taskNo', Val) and (not Val.AsValue().IsNull()) then TaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskNo));
                        if Obj.Get('taskType', Val) and (not Val.AsValue().IsNull()) then TaskTypeTxt := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskTypeTxt));
                        if Obj.Get('description', Val) and (not Val.AsValue().IsNull()) then Description := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(Description));
                        if Obj.Get('unitCost', Val) and (not Val.AsValue().IsNull()) then UnitCost := Val.AsValue().AsDecimal();
                        if Obj.Get('unitAmount', Val) and (not Val.AsValue().IsNull()) then UnitAmount := Val.AsValue().AsDecimal();
                        if Obj.Get('lineAmount', Val) and (not Val.AsValue().IsNull()) then LineAmount := Val.AsValue().AsDecimal();
                        if Obj.Get('no', Val) and (not Val.AsValue().IsNull()) then NoValue := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NoValue));
                        if Obj.Get('codeOrder', Val) and (not Val.AsValue().IsNull()) then CodeOrder := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(CodeOrder));
                        if Obj.Get('variantCode', Val) and (not Val.AsValue().IsNull()) then VariantCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(VariantCode));
                        if Obj.Get('performance', Val) and (not Val.AsValue().IsNull()) then Performance := Val.AsValue().AsDecimal();

                        if WorksNo <> '' then begin
                            if InitAndInsert(WorkLine, WorksNo, LineNo, TaskNo, TaskTypeTxt, Description, UnitCost, UnitAmount, LineAmount, NoValue, CodeOrder, VariantCode, Performance) then begin
                                InsCount += 1;
                                Commit(); // ⚡ Commit después de cada inserción exitosa
                            end else
                                ErrorCount += 1;
                        end else begin
                            ErrorCount += 1;
                            ErrWorksNoMissing += 1;
                        end;
                    end;
                end;
            end;
        end;

        // 🔹 2️⃣ ACTUALIZAR EXISTENTES
        if jsonEditados <> '' then begin
            if Arr.ReadFrom(jsonEditados) then begin
                foreach Token in Arr do begin
                    if not Token.IsObject() then begin
                        ErrorCount += 1;
                        ErrNonObj += 1;
                    end else begin
                        Obj := Token.AsObject();

                        Clear(SystemIdTxt);
                        Clear(WorksNo);
                        Clear(LineNo);
                        Clear(TaskNo);
                        Clear(TaskTypeTxt);
                        Clear(Description);
                        Clear(UnitCost);
                        Clear(UnitAmount);
                        Clear(LineAmount);
                        Clear(NoValue);
                        Clear(CodeOrder);
                        Clear(VariantCode);
                        Clear(Performance);

                        HasSystemId := false;
                        if Obj.Get('id', Val) and (not Val.AsValue().IsNull()) then begin
                            SystemIdTxt := Val.AsValue().AsText();
                            if TryStrToGuid(SystemIdTxt, SystemIdGuid) then
                                HasSystemId := true;
                        end;

                        if not HasSystemId then begin
                            ErrorCount += 1;
                            ErrIdMissing += 1;
                        end else if not WorkLine.GetBySystemId(SystemIdGuid) then begin
                            ErrorCount += 1;
                            ErrIdNotFound += 1;
                        end else begin

                            if Obj.Get('worksNo', Val) and (not Val.AsValue().IsNull()) then WorksNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(WorksNo));
                            if Obj.Get('lineNo', Val) and (not Val.AsValue().IsNull()) then LineNo := Val.AsValue().AsInteger();
                            if Obj.Get('taskNo', Val) and (not Val.AsValue().IsNull()) then TaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskNo));
                            if Obj.Get('taskType', Val) and (not Val.AsValue().IsNull()) then TaskTypeTxt := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskTypeTxt));
                            if Obj.Get('description', Val) and (not Val.AsValue().IsNull()) then Description := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(Description));
                            if Obj.Get('unitCost', Val) and (not Val.AsValue().IsNull()) then UnitCost := Val.AsValue().AsDecimal();
                            if Obj.Get('unitAmount', Val) and (not Val.AsValue().IsNull()) then UnitAmount := Val.AsValue().AsDecimal();
                            if Obj.Get('lineAmount', Val) and (not Val.AsValue().IsNull()) then LineAmount := Val.AsValue().AsDecimal();
                            if Obj.Get('no', Val) and (not Val.AsValue().IsNull()) then NoValue := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NoValue));
                            if Obj.Get('codeOrder', Val) and (not Val.AsValue().IsNull()) then CodeOrder := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(CodeOrder));
                            if Obj.Get('variantCode', Val) and (not Val.AsValue().IsNull()) then VariantCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(VariantCode));
                            if Obj.Get('performance', Val) and (not Val.AsValue().IsNull()) then Performance := Val.AsValue().AsDecimal();

                            if UpdateLine(WorkLine, WorksNo, LineNo, TaskNo, TaskTypeTxt, Description, UnitCost, UnitAmount, LineAmount, NoValue, CodeOrder, VariantCode, Performance) then begin
                                UpdCount += 1;
                                Commit(); // ⚡ Commit después de cada actualización
                            end else
                                ErrorCount += 1;
                        end;
                    end;
                end;
            end;
        end;

        // 🔹 3️⃣ ELIMINAR REGISTROS
        if jsonEliminados <> '' then begin
            if Arr.ReadFrom(jsonEliminados) then begin
                foreach Token in Arr do begin
                    Obj := Token.AsObject();
                    if Obj.Get('id', Val) and (not Val.AsValue().IsNull()) then begin
                        SystemIdTxt := Val.AsValue().AsText();
                        if TryStrToGuid(SystemIdTxt, SystemIdGuid) then
                            if Existing.GetBySystemId(SystemIdGuid) then begin
                                if Existing.Delete(true) then begin
                                    DelCount += 1;
                                    Commit(); // ⚡ Commit después de cada eliminación
                                end else begin
                                    ErrorCount += 1;
                                    ErrDeleteFailed += 1;
                                end;
                            end;
                    end;
                end;
            end;
        end;

        // 🔹 4️⃣ RESULTADO FINAL
        if ErrorCount > 0 then
            exit(
                Format(InsCount) + ' insertados, ' +
                Format(UpdCount) + ' actualizados, ' +
                Format(DelCount) + ' eliminados. ⚠️ ' +
                Format(ErrorCount) + ' errores ' +
                '[' +
                'nonObj=' + Format(ErrNonObj) + ', ' +
                'worksNo=' + Format(ErrWorksNoMissing) + ', ' +
                'idMissing=' + Format(ErrIdMissing) + ', ' +
                'idNotFound=' + Format(ErrIdNotFound) + ', ' +
                'deleteFail=' + Format(ErrDeleteFailed) +
                ']'
            )
        else
            exit(
                Format(InsCount) + ' insertados, ' +
                Format(UpdCount) + ' actualizados, ' +
                Format(DelCount) + ' eliminados.'
            );
    end;

    // 🧩 Subprocedimientos
    local procedure InitAndInsert(var RecLine: Record "GomJob Works Decomposed Lines";
        WorksNo: Code[20]; LineNo: Integer; TaskNo: Code[50]; TaskTypeTxt: Code[50]; Description: Text[250];
        UnitCost: Decimal; UnitAmount: Decimal; LineAmount: Decimal; NoValue: Code[50];
        CodeOrder: Code[50]; VariantCode: Code[50]; Performance: Decimal): Boolean
    begin
        RecLine.Init();
        if (LineNo = 0) then
            LineNo := GetNextLineNo(WorksNo);
        if not SetLineFields(RecLine, WorksNo, LineNo, TaskNo, TaskTypeTxt, Description, UnitCost, UnitAmount, LineAmount, NoValue, CodeOrder, VariantCode, Performance, true) then
            exit(false);
        exit(RecLine.Insert(true));
    end;

    local procedure UpdateLine(var RecLine: Record "GomJob Works Decomposed Lines";
        WorksNo: Code[20]; LineNo: Integer; TaskNo: Code[50]; TaskTypeTxt: Code[50]; Description: Text[250];
        UnitCost: Decimal; UnitAmount: Decimal; LineAmount: Decimal; NoValue: Code[50];
        CodeOrder: Code[50]; VariantCode: Code[50]; Performance: Decimal): Boolean
    begin
        if not SetLineFields(RecLine, WorksNo, LineNo, TaskNo, TaskTypeTxt, Description, UnitCost, UnitAmount, LineAmount, NoValue, CodeOrder, VariantCode, Performance, false) then
            exit(false);
        exit(RecLine.Modify(true));
    end;

    local procedure SetLineFields(var RecLine: Record "GomJob Works Decomposed Lines";
        WorksNo: Code[20]; LineNo: Integer; TaskNo: Code[50]; TaskTypeTxt: Code[50]; Description: Text[250];
        UnitCost: Decimal; UnitAmount: Decimal; LineAmount: Decimal; NoValue: Code[50];
        CodeOrder: Code[50]; VariantCode: Code[50]; Performance: Decimal; IsInsert: Boolean): Boolean
    var
        TaskTypeOpt: Option Posting,Heading,Total;
    begin
        // ⚡ Asignación directa en lugar de Validate para mayor velocidad
        RecLine."Works No." := WorksNo;
        if IsInsert then
            RecLine."Line No." := LineNo;
        RecLine."Task No." := TaskNo;

        case UpperCase(TaskTypeTxt) of
            'POSTING':
                TaskTypeOpt := TaskTypeOpt::Posting;
            'HEADING':
                TaskTypeOpt := TaskTypeOpt::Heading;
            'TOTAL':
                TaskTypeOpt := TaskTypeOpt::Total;
            else
                exit(false); // Retornar false en lugar de Error
        end;

        RecLine."Task Type" := TaskTypeOpt;
        RecLine.Description := Description;
        RecLine."Unit Cost" := UnitCost;
        RecLine."Unit Amount" := UnitAmount;
        if LineAmount <> 0 then
            RecLine."Line Amount" := LineAmount;
        RecLine."No." := NoValue;
        RecLine."Code Order" := CodeOrder;
        RecLine."Variant Code" := VariantCode;
        RecLine.Performance := Performance;
        exit(true);
    end;

    local procedure GetNextLineNo(WorksNo: Code[20]): Integer
    var
        Tmp: Record "GomJob Works Decomposed Lines";
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
