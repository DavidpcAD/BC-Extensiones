namespace Adelante.Inventory;

page 50220 "GJW Material Operation API"
{
    PageType = API;
    Caption = 'Material Operation API';
    APIPublisher = 'adelante';
    APIGroup = 'operations';
    APIVersion = 'v1.0';
    EntityName = 'materialOperation';
    EntitySetName = 'materialOperations';

    SourceTable = "GJW Material Operation";
    ODataKeyFields = "Operation Id";
    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(operationId; Rec."Operation Id")
                {
                    Caption = 'Operation Id';
                    Editable = false;
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(operationType; Rec."Operation Type")
                {
                    Caption = 'Operation Type';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(currentStep; Rec."Current Step")
                {
                    Caption = 'Current Step';
                    Editable = false;
                }
                field(sourceJobNo; Rec."Source Job No.")
                {
                    Caption = 'Source Job No.';
                }
                field(sourceJobTaskNo; Rec."Source Job Task No.")
                {
                    Caption = 'Source Job Task No.';
                }
                field(sourceLocationCode; Rec."Source Location Code")
                {
                    Caption = 'Source Location Code';
                }
                field(destinationJobNo; Rec."Destination Job No.")
                {
                    Caption = 'Destination Job No.';
                }
                field(destinationJobTaskNo; Rec."Destination Job Task No.")
                {
                    Caption = 'Destination Job Task No.';
                }
                field(destinationLocationCode; Rec."Destination Location Code")
                {
                    Caption = 'Destination Location Code';
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(requiresFinalConsume; Rec."Requires Final Consume")
                {
                    Caption = 'Requires Final Consume';
                }
                field(lastError; Rec."Last Error")
                {
                    Caption = 'Last Error';
                    Editable = false;
                }
                field(lastBCEntryNos; Rec."Last BC Entry Nos")
                {
                    Caption = 'Last BC Entry Nos';
                    Editable = false;
                }
                field(lastActionMessage; Rec."Last Action Message")
                {
                    Caption = 'Last Action Message';
                    Editable = false;
                }
                field(executeNext; Rec."Execute Next")
                {
                    Caption = 'Execute Next';

                    trigger OnValidate()
                    begin
                        if not Rec."Execute Next" then
                            exit;

                        Rec."Last Action Message" := CopyStr(Orchestrator.ExecuteNextStep(Rec."Operation Id"), 1, MaxStrLen(Rec."Last Action Message"));
                        RefreshRec();
                        Rec."Execute Next" := false;
                    end;
                }
                field(executeUntilStop; Rec."Execute Until Stop")
                {
                    Caption = 'Execute Until Stop';

                    trigger OnValidate()
                    begin
                        if not Rec."Execute Until Stop" then
                            exit;

                        Rec."Last Action Message" := CopyStr(Orchestrator.ExecuteUntilStop(Rec."Operation Id", 5), 1, MaxStrLen(Rec."Last Action Message"));
                        RefreshRec();
                        Rec."Execute Until Stop" := false;
                    end;
                }
                field(retryFailed; Rec."Retry Failed")
                {
                    Caption = 'Retry Failed';

                    trigger OnValidate()
                    begin
                        if not Rec."Retry Failed" then
                            exit;

                        Rec."Last Action Message" := CopyStr(Orchestrator.RetryFailedStep(Rec."Operation Id"), 1, MaxStrLen(Rec."Last Action Message"));
                        RefreshRec();
                        Rec."Retry Failed" := false;
                    end;
                }
                field(statusJson; StatusJson)
                {
                    Caption = 'Status Json';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        StatusJson := Orchestrator.GetStatusJson(Rec."Operation Id");
                    end;
                }
            }
        }
    }

    var
        Orchestrator: Codeunit "GJW Material Op Orchestrator";
        StatusJson: Text;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Last Action Message" := CopyStr(Orchestrator.StartOperation(Rec), 1, MaxStrLen(Rec."Last Action Message"));
        exit(true);
    end;

    local procedure RefreshRec()
    begin
        if Rec.Get(Rec."Operation Id") then;
    end;
}
