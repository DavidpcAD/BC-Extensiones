codeunit 50128 "GJW ProdLines Bulk"
{
    // 🎯 SOLO INSERT - Production Lines (avance de obra)
    // Crea múltiples líneas de producción de una vez

    [ServiceEnabled]
    procedure Import(jsonNuevos: Text): Text;
    var
        Arr: JsonArray;
        Token: JsonToken;
        Obj: JsonObject;
        Val: JsonToken;

        ProdLine: Record "GomJob Works Production Line";
        InsCount: Integer;
        ErrorCount: Integer;

        // Campos obligatorios
        WorksNo: Code[20];

        // Campos de Power Apps
        TaskNo: Code[50];
        TaskTypeTxt: Text;
        Description: Text[250];
        UnitOfMeasure: Code[10];
        UnitAmount: Decimal;
        Quantity: Decimal;
        CodeOrder: Code[50];
    begin
        // ✅ SOLO INSERTAR NUEVOS
        if jsonNuevos <> '' then begin
            if Arr.ReadFrom(jsonNuevos) then begin
                foreach Token in Arr do begin
                    if Token.IsObject() then begin
                        Obj := Token.AsObject();

                        // Limpiar variables
                        Clear(WorksNo);
                        Clear(TaskNo);
                        Clear(TaskTypeTxt);
                        Clear(Description);
                        Clear(UnitOfMeasure);
                        Clear(UnitAmount);
                        Clear(Quantity);
                        Clear(CodeOrder);

                        // Leer JSON
                        if Obj.Get('worksNo', Val) and (not Val.AsValue().IsNull()) then
                            WorksNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(WorksNo));

                        if Obj.Get('taskNo', Val) and (not Val.AsValue().IsNull()) then
                            TaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskNo));

                        if Obj.Get('taskType', Val) and (not Val.AsValue().IsNull()) then
                            TaskTypeTxt := Val.AsValue().AsText();

                        if Obj.Get('description', Val) and (not Val.AsValue().IsNull()) then
                            Description := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(Description));

                        if Obj.Get('unitOfMeasure', Val) and (not Val.AsValue().IsNull()) then
                            UnitOfMeasure := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(UnitOfMeasure));

                        if Obj.Get('unitAmount', Val) and (not Val.AsValue().IsNull()) then
                            UnitAmount := Val.AsValue().AsDecimal();

                        if Obj.Get('quantity', Val) and (not Val.AsValue().IsNull()) then
                            Quantity := Val.AsValue().AsDecimal();

                        if Obj.Get('codeOrder', Val) and (not Val.AsValue().IsNull()) then
                            CodeOrder := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(CodeOrder));

                        // ✅ VALIDAR campos obligatorios
                        if WorksNo = '' then begin
                            ErrorCount += 1;
                        end else if TaskTypeTxt = '' then begin
                            ErrorCount += 1;
                        end else begin
                            // 🚀 INSERTAR
                            if InsertNewProdLine(ProdLine, WorksNo, TaskNo, TaskTypeTxt, Description,
                                UnitOfMeasure, UnitAmount, Quantity, CodeOrder) then begin
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
            exit(Format(InsCount) + ' líneas de producción creadas. ⚠️ ' + Format(ErrorCount) + ' errores.')
        else
            exit('✅ ' + Format(InsCount) + ' líneas de producción creadas correctamente.');
    end;

    local procedure InsertNewProdLine(var RecLine: Record "GomJob Works Production Line";
        WorksNo: Code[20]; TaskNo: Code[50]; TaskTypeTxt: Text; Description: Text[250];
        UnitOfMeasure: Code[10]; UnitAmount: Decimal; Quantity: Decimal; CodeOrder: Code[50]): Boolean
    var
        TaskTypeOpt: Option Posting,Heading,Total;
    begin
        RecLine.Init();

        RecLine."Works No." := WorksNo;
        RecLine."Task No." := TaskNo;

        // ✅ VALIDAR Task Type
        if not Evaluate(TaskTypeOpt, TaskTypeTxt) then
            exit(false);
        RecLine."Task Type" := TaskTypeOpt;

        // Asignar resto de campos
        RecLine.Description := Description;
        RecLine."Unit of Measure" := UnitOfMeasure;
        RecLine."Unit Amount" := UnitAmount;
        RecLine.Quantity := Quantity;
        RecLine."Code Order" := CodeOrder;

        exit(RecLine.Insert(true));
    end;
}
