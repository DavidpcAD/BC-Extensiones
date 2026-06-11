codeunit 50220 "GJW Material Op Orchestrator"
{
    procedure StartOperation(var Op: Record "GJW Material Operation"): Text
    begin
        ValidateStart(Op);

        if IsNullGuid(Op."Operation Id") then
            Op."Operation Id" := CreateGuid();

        if Op."Document No." = '' then
            Op."Document No." := CopyStr('OP-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'), 1, 20);

        case Op."Operation Type" of
            Op."Operation Type"::ConsumeFromGeneral:
                begin
                    Op."Requires Final Consume" := true;
                    Op.Status := Op.Status::ReverseDone;
                    Op."Current Step" := Op."Current Step"::Physical;
                end;
            Op."Operation Type"::TransferConsumedBetweenJobs:
                begin
                    Op."Requires Final Consume" := true;
                    Op.Status := Op.Status::PendingReverse;
                    Op."Current Step" := Op."Current Step"::Reverse;
                end;
            Op."Operation Type"::ReturnConsumedToGeneral:
                begin
                    Op."Requires Final Consume" := false;
                    Op.Status := Op.Status::PendingReverse;
                    Op."Current Step" := Op."Current Step"::Reverse;
                end;
        end;

        Op."Last Error" := '';
        Op."Result JSON" := '';

        exit(StrSubstNo('Operation %1 iniciada en PendingReverse.', Op."Operation Id"));
    end;

    procedure ExecuteNextStep(OperationId: Guid): Text
    var
        Op: Record "GJW Material Operation";
    begin
        if not Op.Get(OperationId) then
            Error('Operation %1 no existe.', OperationId);

        case Op.Status of
            Op.Status::PendingReverse:
                exit(RunReverse(Op));
            Op.Status::ReverseDone:
                exit(RunPhysical(Op));
            Op.Status::PhysicalDone:
                if Op."Requires Final Consume" then
                    exit(RunFinalConsume(Op))
                else begin
                    CloseOp(Op);
                    exit('Operation cerrada sin consumo final.');
                end;
            Op.Status::FinalConsumeDone:
                begin
                    CloseOp(Op);
                    exit('Operation cerrada.');
                end;
            Op.Status::Closed:
                exit('Operation ya estaba cerrada.');
            Op.Status::Failed:
                exit('Operation en Failed. Use retryFailed.');
        end;
    end;

    procedure ExecuteUntilStop(OperationId: Guid; MaxSteps: Integer): Text
    var
        i: Integer;
        Msg: Text;
        Op: Record "GJW Material Operation";
    begin
        if MaxSteps <= 0 then
            MaxSteps := 5;

        for i := 1 to MaxSteps do begin
            Msg := ExecuteNextStep(OperationId);

            if not Op.Get(OperationId) then
                exit(Msg);

            if (Op.Status = Op.Status::Closed) or (Op.Status = Op.Status::Failed) then
                exit(Msg);
        end;

        exit('MaxSteps alcanzado.');
    end;

    procedure RetryFailedStep(OperationId: Guid): Text
    var
        Op: Record "GJW Material Operation";
    begin
        if not Op.Get(OperationId) then
            Error('Operation %1 no existe.', OperationId);

        if Op.Status <> Op.Status::Failed then
            exit('Operation no está en Failed.');

        if Op."Current Step" = Op."Current Step"::Reverse then
            Op.Status := Op.Status::PendingReverse
        else
            if Op."Current Step" = Op."Current Step"::Physical then
                Op.Status := Op.Status::ReverseDone
            else
                if Op."Current Step" = Op."Current Step"::FinalConsume then
                    Op.Status := Op.Status::PhysicalDone;

        Op."Last Error" := '';
        Op.Modify(true);

        exit(ExecuteNextStep(OperationId));
    end;

    procedure GetStatusJson(OperationId: Guid): Text
    var
        Op: Record "GJW Material Operation";
    begin
        if not Op.Get(OperationId) then
            Error('Operation %1 no existe.', OperationId);

        exit(StrSubstNo('{"operationId":"%1","documentNo":"%2","status":"%3","currentStep":"%4","lastError":"%5","updatedAt":"%6"}',
            Format(Op."Operation Id"),
            Op."Document No.",
            Format(Op.Status),
            Format(Op."Current Step"),
            Op."Last Error",
            Format(Op."Updated At", 0, 9)));
    end;

    local procedure ValidateStart(var Op: Record "GJW Material Operation")
    begin
        if Op."Item No." = '' then
            Error('Item No. es obligatorio.');

        if Op.Quantity <= 0 then
            Error('Quantity debe ser mayor que 0.');

        if Op."Source Location Code" = '' then
            Error('Source Location Code es obligatorio.');

        if Op."Operation Type" = Op."Operation Type"::ConsumeFromGeneral then begin
            if Op."Destination Job No." = '' then
                Error('Destination Job No. es obligatorio para ConsumeFromGeneral.');
            if Op."Destination Job Task No." = '' then
                Error('Destination Job Task No. es obligatorio para ConsumeFromGeneral.');
        end;

        if Op."Operation Type" <> Op."Operation Type"::ConsumeFromGeneral then begin
            if Op."Source Job No." = '' then
                Error('Source Job No. es obligatorio para operaciones con reversa.');
            if Op."Source Job Task No." = '' then
                Error('Source Job Task No. es obligatorio para operaciones con reversa.');
        end;

        if Op."Destination Location Code" = '' then
            Error('Destination Location Code es obligatorio.');

        if Op."Operation Type" = Op."Operation Type"::TransferConsumedBetweenJobs then begin
            if Op."Destination Job No." = '' then
                Error('Destination Job No. es obligatorio para traslado entre obras.');
            if Op."Destination Job Task No." = '' then
                Error('Destination Job Task No. es obligatorio para traslado entre obras.');
        end;

        if Op."Operation Type" = Op."Operation Type"::ReturnConsumedToGeneral then
            if Op."Destination Job No." <> '' then
                Error('Destination Job No. debe ir vacío para devolución a almacén general.');
    end;

    local procedure RunReverse(var Op: Record "GJW Material Operation"): Text
    var
        StatusBefore: Option PendingReverse,ReverseDone,PhysicalDone,FinalConsumeDone,Closed,Failed;
        ResultTxt: Text;
    begin
        StatusBefore := Op.Status;

        ClearLastError();
        if not TryRunReverseContable(Op, ResultTxt) then begin
            SetFailed(Op, GetLastErrorText());
            exit(StrSubstNo('Reverse failed: %1', Op."Last Error"));
        end;

        Op.Status := Op.Status::ReverseDone;
        Op."Current Step" := Op."Current Step"::Physical;
        Op."Last Error" := '';
        Op."Result JSON" := CopyStr(ResultTxt, 1, MaxStrLen(Op."Result JSON"));
        Op.Modify(true);

        AppendStepLog(Op."Operation Id", StepOptionFromName('Reverse'), StatusBefore, Op.Status, true, '', Op."Result JSON");
        exit('ReverseDone');
    end;

    local procedure RunPhysical(var Op: Record "GJW Material Operation"): Text
    var
        StatusBefore: Option PendingReverse,ReverseDone,PhysicalDone,FinalConsumeDone,Closed,Failed;
        ResultTxt: Text;
        JsonResults: Text;
        EntryNosText: Text;
    begin
        StatusBefore := Op.Status;

        ClearLastError();
        if not TryRunPhysicalTransfer(Op, ResultTxt, JsonResults) then begin
            SetFailed(Op, GetLastErrorText());
            exit(StrSubstNo('Physical failed: %1', Op."Last Error"));
        end;

        EntryNosText := ParseDestinationEntryNos(JsonResults);
        Op."Last BC Entry Nos" := CopyStr(EntryNosText, 1, MaxStrLen(Op."Last BC Entry Nos"));

        Op.Status := Op.Status::PhysicalDone;
        if Op."Requires Final Consume" then
            Op."Current Step" := Op."Current Step"::FinalConsume
        else
            Op."Current Step" := Op."Current Step"::Close;
        Op."Last Error" := '';
        Op."Result JSON" := CopyStr(JsonResults, 1, MaxStrLen(Op."Result JSON"));
        Op.Modify(true);

        AppendStepLog(Op."Operation Id", StepOptionFromName('Physical'), StatusBefore, Op.Status, true, '', Op."Result JSON");
        exit(ResultTxt);
    end;

    local procedure RunFinalConsume(var Op: Record "GJW Material Operation"): Text
    var
        StatusBefore: Option PendingReverse,ReverseDone,PhysicalDone,FinalConsumeDone,Closed,Failed;
        ResultTxt: Text;
        JobNo: Code[20];
        JobTaskNo: Code[20];
    begin
        StatusBefore := Op.Status;

        if Op."Last BC Entry Nos" = '' then begin
            SetFailed(Op, 'No hay Item Ledger Entries de destino para consumo final.');
            exit(StrSubstNo('Final consume failed: %1', Op."Last Error"));
        end;

        JobNo := Op."Destination Job No.";
        JobTaskNo := Op."Destination Job Task No.";
        if JobNo = '' then
            JobNo := Op."Source Job No.";
        if JobTaskNo = '' then
            JobTaskNo := Op."Source Job Task No.";

        ClearLastError();
        if not TryRunFinalConsume(Op, JobNo, JobTaskNo, ResultTxt) then begin
            SetFailed(Op, GetLastErrorText());
            exit(StrSubstNo('Final consume failed: %1', Op."Last Error"));
        end;

        Op.Status := Op.Status::FinalConsumeDone;
        Op."Current Step" := Op."Current Step"::Close;
        Op."Last Error" := '';
        Op."Result JSON" := CopyStr(ResultTxt, 1, MaxStrLen(Op."Result JSON"));
        Op.Modify(true);

        AppendStepLog(Op."Operation Id", StepOptionFromName('FinalConsume'), StatusBefore, Op.Status, true, '', Op."Result JSON");
        exit('FinalConsumeDone');
    end;

    local procedure CloseOp(var Op: Record "GJW Material Operation")
    var
        StatusBefore: Option PendingReverse,ReverseDone,PhysicalDone,FinalConsumeDone,Closed,Failed;
    begin
        StatusBefore := Op.Status;
        Op.Status := Op.Status::Closed;
        Op."Current Step" := Op."Current Step"::Close;
        Op."Last Error" := '';
        Op."Result JSON" := '{"closed":true}';
        Op.Modify(true);

        AppendStepLog(Op."Operation Id", StepOptionFromName('Close'), StatusBefore, Op.Status, true, '', Op."Result JSON");
    end;

    local procedure SetFailed(var Op: Record "GJW Material Operation"; ErrText: Text)
    var
        StatusBefore: Option PendingReverse,ReverseDone,PhysicalDone,FinalConsumeDone,Closed,Failed;
    begin
        if ErrText = '' then
            ErrText := 'Error no especificado';

        StatusBefore := Op.Status;
        Op.Status := Op.Status::Failed;
        Op."Last Error" := CopyStr(ErrText, 1, MaxStrLen(Op."Last Error"));
        Op.Modify(true);

        AppendStepLog(Op."Operation Id", Op."Current Step", StatusBefore, Op.Status, false, Op."Last Error", '{"ok":false}');
    end;

    local procedure AppendStepLog(OperationId: Guid; Step: Option Reverse,Physical,FinalConsume,Close; StatusBefore: Option PendingReverse,ReverseDone,PhysicalDone,FinalConsumeDone,Closed,Failed; StatusAfter: Option PendingReverse,ReverseDone,PhysicalDone,FinalConsumeDone,Closed,Failed; Success: Boolean; ErrorText: Text; ResponseJson: Text)
    var
        StepRec: Record "GJW Material Operation Step";
        NextAttemptNo: Integer;
    begin
        StepRec.Reset();
        StepRec.SetRange("Operation Id", OperationId);
        StepRec.SetCurrentKey("Operation Id", Step, "Attempt No.");
        StepRec.SetRange(StepRec.Step, Step);
        if StepRec.FindLast() then
            NextAttemptNo := StepRec."Attempt No." + 1
        else
            NextAttemptNo := 1;

        StepRec.Init();
        StepRec."Operation Id" := OperationId;
        StepRec.Step := Step;
        StepRec."Attempt No." := NextAttemptNo;
        StepRec."Status Before" := StatusBefore;
        StepRec."Status After" := StatusAfter;
        StepRec.Success := Success;
        StepRec."Started At" := CurrentDateTime;
        StepRec."Finished At" := CurrentDateTime;
        StepRec."Error Text" := CopyStr(ErrorText, 1, MaxStrLen(StepRec."Error Text"));
        StepRec."Response Json" := CopyStr(ResponseJson, 1, MaxStrLen(StepRec."Response Json"));
        StepRec.Insert(true);
    end;

    [TryFunction]
    local procedure TryRunReverseContable(var Op: Record "GJW Material Operation"; var ResultTxt: Text)
    var
        JobJnlLine: Record "Job Journal Line";
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        ItemRec: Record Item;
        TempBatchName: Code[20];
        ItemDescription: Text[100];
    begin
        TempBatchName := 'TMP' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 7);

        if not JobJnlBatch.Get('PROJECT', TempBatchName) then begin
            JobJnlBatch.Init();
            JobJnlBatch."Journal Template Name" := 'PROJECT';
            JobJnlBatch.Name := TempBatchName;
            JobJnlBatch.Description := 'Temp reverse operation batch';
            JobJnlBatch.Insert();
        end;

        JobJnlLine.Init();
        JobJnlLine."Journal Template Name" := 'PROJECT';
        JobJnlLine."Journal Batch Name" := TempBatchName;
        JobJnlLine."Line No." := 10000;
        JobJnlLine.Validate("Posting Date", Today());
        JobJnlLine.Validate("Job No.", Op."Source Job No.");
        JobJnlLine.Validate("Job Task No.", Op."Source Job Task No.");
        JobJnlLine.Validate(Type, JobJnlLine.Type::Item);
        JobJnlLine.Validate("No.", Op."Item No.");

        if Op."Variant Code" <> '' then
            JobJnlLine.Validate("Variant Code", Op."Variant Code");

        JobJnlLine.Validate(Quantity, -Abs(Op.Quantity));
        JobJnlLine.Validate("Location Code", Op."Source Location Code");
        JobJnlLine."Document No." := Op."Document No.";

        // Conservar la descripción del material (no "Reverse operation ...").
        ItemDescription := JobJnlLine.Description;
        if ItemDescription = '' then
            if ItemRec.Get(Op."Item No.") then
                ItemDescription := ItemRec.Description;
        JobJnlLine.Description := ItemDescription;

        // Las default dimensions de la ubicación/ítem (p.ej. CC=INV de ALM-GRAL) pisan
        // la dimensión obligatoria del proyecto al recombinarse en cada Validate.
        // Re-forzamos las dimensiones obligatorias del Job sobre la línea antes de postear.
        ForceJobDimensions(JobJnlLine, Op."Source Job No.");

        JobJnlLine.Insert(false);

        Commit();
        JobJnlPostLine.Run(JobJnlLine);

        if JobJnlBatch.Get('PROJECT', TempBatchName) then
            JobJnlBatch.Delete(true);

        ResultTxt := '{"reverse":"posted"}';
    end;

    // Fuerza sobre la Job Journal Line las dimensiones definidas como obligatorias en el
    // proyecto (Default Dimension del Job con valor fijo, p.ej. CC = "Igual al código").
    // Esto sobrescribe lo que la ubicación/ítem hubieran heredado (p.ej. CC=INV de ALM-GRAL).
    local procedure ForceJobDimensions(var JobJnlLine: Record "Job Journal Line"; JobNo: Code[20])
    var
        DefaultDim: Record "Default Dimension";
        DimValue: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        EntryExists: Boolean;
    begin
        // Cargar las dimensiones actuales de la línea (las heredadas por los Validate).
        if JobJnlLine."Dimension Set ID" <> 0 then begin
            DimSetEntry.SetRange("Dimension Set ID", JobJnlLine."Dimension Set ID");
            if DimSetEntry.FindSet() then
                repeat
                    TempDimSetEntry := DimSetEntry;
                    TempDimSetEntry.Insert();
                until DimSetEntry.Next() = 0;
        end;

        // Sobrescribir con las dimensiones obligatorias (valor fijo) del proyecto.
        DefaultDim.SetRange("Table ID", Database::Job);
        DefaultDim.SetRange("No.", JobNo);
        DefaultDim.SetFilter("Dimension Value Code", '<>%1', '');
        if DefaultDim.FindSet() then
            repeat
                TempDimSetEntry.Reset();
                TempDimSetEntry.SetRange("Dimension Code", DefaultDim."Dimension Code");
                EntryExists := TempDimSetEntry.FindFirst();
                TempDimSetEntry.Reset();

                if not EntryExists then begin
                    TempDimSetEntry.Init();
                    TempDimSetEntry."Dimension Code" := DefaultDim."Dimension Code";
                end;

                TempDimSetEntry."Dimension Value Code" := DefaultDim."Dimension Value Code";
                if DimValue.Get(DefaultDim."Dimension Code", DefaultDim."Dimension Value Code") then
                    TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";

                if EntryExists then
                    TempDimSetEntry.Modify()
                else
                    TempDimSetEntry.Insert();
            until DefaultDim.Next() = 0;

        JobJnlLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    [TryFunction]
    local procedure TryRunPhysicalTransfer(var Op: Record "GJW Material Operation"; var ResultTxt: Text; var JsonResults: Text)
    var
        TransferCU: Codeunit "GJW Item Transfer Bulk";
        Arr: JsonArray;
        Obj: JsonObject;
        TransfersJson: Text;
    begin
        Obj.Add('itemNo', Op."Item No.");
        Obj.Add('locationCode', Op."Source Location Code");
        Obj.Add('newLocationCode', Op."Destination Location Code");
        Obj.Add('quantity', Abs(Op.Quantity));
        Obj.Add('documentNo', Op."Document No.");

        if Op."Variant Code" <> '' then
            Obj.Add('variantCode', Op."Variant Code");

        if Op."Source Job Task No." <> '' then
            Obj.Add('taskNo', Op."Source Job Task No.");

        if Op."Destination Job No." <> '' then
            Obj.Add('newJobNo', Op."Destination Job No.");
        if Op."Destination Job Task No." <> '' then
            Obj.Add('newJobTaskNo', Op."Destination Job Task No.");

        Arr.Add(Obj);
        Arr.WriteTo(TransfersJson);

        ResultTxt := TransferCU.ProcessTransfersWithJson(TransfersJson, JsonResults);
        if StrPos(UpperCase(ResultTxt), 'ERROR') > 0 then
            Error(ResultTxt);
    end;

    [TryFunction]
    local procedure TryRunFinalConsume(var Op: Record "GJW Material Operation"; JobNo: Code[20]; JobTaskNo: Code[20]; var ResultTxt: Text)
    var
        ConsumptionCU: Codeunit "GJW Material Consumption";
    begin
        ResultTxt := ConsumptionCU.ConsumeWarehouseMaterials(Op."Last BC Entry Nos", JobNo, JobTaskNo, Op."Document No.");
    end;

    local procedure ParseDestinationEntryNos(JsonResults: Text): Text
    var
        Arr: JsonArray;
        Token: JsonToken;
        Obj: JsonObject;
        DestTok: JsonToken;
        DestObj: JsonObject;
        EntryTok: JsonToken;
        EntryNo: Integer;
        Acc: Text;
    begin
        if JsonResults = '' then
            exit('');

        if not Arr.ReadFrom(JsonResults) then
            exit('');

        foreach Token in Arr do begin
            if not Token.IsObject() then
                continue;

            Obj := Token.AsObject();
            if Obj.Get('destination', DestTok) and DestTok.IsObject() then begin
                DestObj := DestTok.AsObject();
                if DestObj.Get('entryNoALM', EntryTok) then begin
                    EntryNo := EntryTok.AsValue().AsInteger();
                    if EntryNo > 0 then begin
                        if Acc <> '' then
                            Acc += ',';
                        Acc += Format(EntryNo);
                    end;
                end;
            end;
        end;

        exit(Acc);
    end;

    local procedure StepOptionFromName(Name: Text): Option Reverse,Physical,FinalConsume,Close
    var
        StepOpt: Option Reverse,Physical,FinalConsume,Close;
    begin
        case UpperCase(Name) of
            'REVERSE':
                StepOpt := StepOpt::Reverse;
            'PHYSICAL':
                StepOpt := StepOpt::Physical;
            'FINALCONSUME':
                StepOpt := StepOpt::FinalConsume;
            else
                StepOpt := StepOpt::Close;
        end;

        exit(StepOpt);
    end;
}
