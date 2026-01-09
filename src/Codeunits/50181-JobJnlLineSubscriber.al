codeunit 50181 "GJW Job Jnl Line Subscriber"
{
    var
        PreservedUnitCost: Decimal;
        SkipCostUpdate: Boolean;

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnBeforeValidateEvent', 'No.', false, false)]
    local procedure OnBeforeValidateNo(var Rec: Record "Job Journal Line"; var xRec: Record "Job Journal Line"; CurrFieldNo: Integer)
    begin
        // Guardar el Unit Cost ANTES de que BC lo valide y recalcule
        if Rec."GJW Preserve Unit Cost" <> 0 then begin
            PreservedUnitCost := Rec."GJW Preserve Unit Cost";
            SkipCostUpdate := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure OnAfterValidateNo(var Rec: Record "Job Journal Line"; var xRec: Record "Job Journal Line"; CurrFieldNo: Integer)
    begin
        // Restaurar el Unit Cost DESPUÉS de que BC lo haya validado
        if SkipCostUpdate and (PreservedUnitCost <> 0) then begin
            Rec."Unit Cost" := PreservedUnitCost;
            Rec."Unit Cost (LCY)" := PreservedUnitCost;
            Rec."Total Cost" := Rec."Unit Cost" * Rec.Quantity;
            Rec."Total Cost (LCY)" := Rec."Unit Cost (LCY)" * Rec.Quantity;
            SkipCostUpdate := false;
            PreservedUnitCost := 0;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertJobJnlLine(var Rec: Record "Job Journal Line"; RunTrigger: Boolean)
    var
        JobJnlLine: Record "Job Journal Line";
    begin
        // Restaurar el Unit Cost DESPUÉS del insert también
        if Rec."GJW Preserve Unit Cost" <> 0 then begin
            if JobJnlLine.Get(Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Line No.") then begin
                JobJnlLine."Unit Cost" := Rec."GJW Preserve Unit Cost";
                JobJnlLine."Unit Cost (LCY)" := Rec."GJW Preserve Unit Cost";
                JobJnlLine."Total Cost" := JobJnlLine."Unit Cost" * JobJnlLine.Quantity;
                JobJnlLine."Total Cost (LCY)" := JobJnlLine."Unit Cost (LCY)" * JobJnlLine.Quantity;
                JobJnlLine."GJW Preserve Unit Cost" := 0;
                JobJnlLine.Modify(false);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyJobJnlLine(var Rec: Record "Job Journal Line"; var xRec: Record "Job Journal Line"; RunTrigger: Boolean)
    var
        JobJnlLine: Record "Job Journal Line";
    begin
        // Con DelayedInsert, BC puede modificar después de insertar
        if Rec."GJW Preserve Unit Cost" <> 0 then begin
            if JobJnlLine.Get(Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Line No.") then begin
                JobJnlLine."Unit Cost" := Rec."GJW Preserve Unit Cost";
                JobJnlLine."Unit Cost (LCY)" := Rec."GJW Preserve Unit Cost";
                JobJnlLine."Total Cost" := JobJnlLine."Unit Cost" * JobJnlLine.Quantity;
                JobJnlLine."Total Cost (LCY)" := JobJnlLine."Unit Cost (LCY)" * JobJnlLine.Quantity;
                JobJnlLine."GJW Preserve Unit Cost" := 0;
                JobJnlLine.Modify(false);
            end;
        end;
    end;
}
