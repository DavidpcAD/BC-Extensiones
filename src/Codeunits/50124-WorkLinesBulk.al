codeunit 50124 "GJW WorkLines Bulk"
{
    // 🎯 SOLO INSERT - Presupuesto General (Works Line)
    // No edita, no elimina - solo crea líneas nuevas con versión específica

    [ServiceEnabled]
    procedure Import(jsonNuevos: Text; jsonEditados: Text; jsonEliminados: Text): Text;
    var
        Arr: JsonArray;
        Token: JsonToken;
        Obj: JsonObject;
        Val: JsonToken;

        WorkLine: Record "GomJob Works Line";
        InsCount: Integer;
        ErrorCount: Integer;

        // Campos obligatorios
        WorksNo: Code[20];
        VersionCode: Code[20];

        // Campos de Power Apps
        LineNo: Integer;
        LineTypeTxt: Text;
        TaskTypeTxt: Text;
        TaskNo: Code[50];
        Description: Text[250];
        Quantity: Decimal;
        UnitAmount: Decimal;
        LineAmount: Decimal;
        QuantityToProduce: Decimal;
        UnitOfMeasure: Code[10];
        CodeOrder: Code[50];
        IdEncargado: Text[100];
        ReStudy: Boolean;
    begin
        // ✅ SOLO INSERTAR NUEVOS
        if jsonNuevos <> '' then begin
            if Arr.ReadFrom(jsonNuevos) then begin
                foreach Token in Arr do begin
                    if Token.IsObject() then begin
                        Obj := Token.AsObject();

                        // Limpiar variables
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

                        // Leer JSON
                        if Obj.Get('worksNo', Val) and (not Val.AsValue().IsNull()) then
                            WorksNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(WorksNo));

                        if Obj.Get('versionCode', Val) and (not Val.AsValue().IsNull()) then
                            VersionCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(VersionCode));

                        if Obj.Get('lineNo', Val) and (not Val.AsValue().IsNull()) then
                            LineNo := Val.AsValue().AsInteger();

                        if Obj.Get('lineType', Val) and (not Val.AsValue().IsNull()) then
                            LineTypeTxt := Val.AsValue().AsText();

                        if Obj.Get('taskType', Val) and (not Val.AsValue().IsNull()) then
                            TaskTypeTxt := Val.AsValue().AsText();

                        if Obj.Get('taskNo', Val) and (not Val.AsValue().IsNull()) then
                            TaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskNo));

                        if Obj.Get('description', Val) and (not Val.AsValue().IsNull()) then
                            Description := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(Description));

                        if Obj.Get('quantity', Val) and (not Val.AsValue().IsNull()) then
                            Quantity := Val.AsValue().AsDecimal();

                        if Obj.Get('unitAmount', Val) and (not Val.AsValue().IsNull()) then
                            UnitAmount := Val.AsValue().AsDecimal();

                        if Obj.Get('lineAmount', Val) and (not Val.AsValue().IsNull()) then
                            LineAmount := Val.AsValue().AsDecimal();

                        if Obj.Get('quantityToProduce', Val) and (not Val.AsValue().IsNull()) then
                            QuantityToProduce := Val.AsValue().AsDecimal();

                        if Obj.Get('unitOfMeasure', Val) and (not Val.AsValue().IsNull()) then
                            UnitOfMeasure := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(UnitOfMeasure));

                        if Obj.Get('codeOrder', Val) and (not Val.AsValue().IsNull()) then
                            CodeOrder := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(CodeOrder));

                        if Obj.Get('idEncargado', Val) and (not Val.AsValue().IsNull()) then
                            IdEncargado := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(IdEncargado));

                        if Obj.Get('reStudy', Val) and (not Val.AsValue().IsNull()) then
                            ReStudy := Val.AsValue().AsBoolean();

                        // ✅ VALIDAR campos obligatorios
                        if WorksNo = '' then begin
                            ErrorCount += 1;
                        end else if VersionCode = '' then begin
                            ErrorCount += 1;
                        end else if LineTypeTxt = '' then begin
                            ErrorCount += 1;
                        end else if TaskTypeTxt = '' then begin
                            ErrorCount += 1;
                        end else begin
                            // 🚀 INSERTAR
                            if InsertNewLine(WorkLine, WorksNo, VersionCode, LineNo, LineTypeTxt, TaskTypeTxt,
                                TaskNo, Description, Quantity, UnitAmount, LineAmount, QuantityToProduce,
                                UnitOfMeasure, CodeOrder, IdEncargado, ReStudy) then begin
                                InsCount += 1;
                                Commit();
                            end else
                                ErrorCount += 1;
                        end;
                    end else
                        ErrorCount += 1;
                end;
            end;
        end;

        // 📊 RESULTADO
        if ErrorCount > 0 then
            exit(Format(InsCount) + ' líneas creadas. ⚠️ ' + Format(ErrorCount) + ' errores.')
        else
            exit('✅ ' + Format(InsCount) + ' líneas creadas correctamente.');
    end;

    local procedure InsertNewLine(var RecLine: Record "GomJob Works Line";
        WorksNo: Code[20]; VersionCode: Code[20]; LineNo: Integer; LineTypeTxt: Text; TaskTypeTxt: Text;
        TaskNo: Code[50]; Description: Text[250]; Quantity: Decimal; UnitAmount: Decimal; LineAmount: Decimal;
        QuantityToProduce: Decimal; UnitOfMeasure: Code[10]; CodeOrder: Code[50]; IdEncargado: Text[100];
        ReStudy: Boolean): Boolean
    var
        LineTypeEnum: Enum "GomJob Works Line Type";
        TaskTypeOpt: Option Posting,Heading,Total;
    begin
        RecLine.Init();

        // ✅ Auto-numerar si no viene LineNo
        if LineNo = 0 then
            LineNo := GetNextLineNo(WorksNo, VersionCode);

        RecLine."Works No." := WorksNo;
        RecLine."Version Code" := VersionCode;
        RecLine."Line No." := LineNo;

        // ✅ VALIDAR Line Type
        if not Evaluate(LineTypeEnum, LineTypeTxt) then
            exit(false);
        RecLine."Line Type" := LineTypeEnum;

        // ✅ VALIDAR Task Type
        if not Evaluate(TaskTypeOpt, TaskTypeTxt) then
            exit(false);
        RecLine."Task Type" := TaskTypeOpt;

        // Asignar resto de campos
        RecLine."Task No." := TaskNo;
        RecLine.Description := Description;
        RecLine.Quantity := Quantity;
        RecLine."Unit Amount" := UnitAmount;
        RecLine."Line Amount" := LineAmount;
        RecLine."Quantity to Produce" := QuantityToProduce;
        RecLine."Unit of Measure" := UnitOfMeasure;
        RecLine."Code Order" := CodeOrder;
        RecLine."ID Encargado Text" := IdEncargado;
        RecLine."Re-Study" := ReStudy;

        exit(RecLine.Insert(true));
    end;

    local procedure GetNextLineNo(WorksNo: Code[20]; VersionCode: Code[20]): Integer
    var
        Tmp: Record "GomJob Works Line";
    begin
        Tmp.SetRange("Works No.", WorksNo);
        Tmp.SetRange("Version Code", VersionCode);
        if Tmp.FindLast() then
            exit(Tmp."Line No." + 10000)
        else
            exit(10000);
    end;
}
