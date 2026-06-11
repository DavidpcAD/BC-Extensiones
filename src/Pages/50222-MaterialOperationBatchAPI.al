namespace Adelante.Inventory;

page 50222 "GJW Material Op Batch API"
{
    PageType = API;
    Caption = 'Material Operation Batch API';
    APIPublisher = 'adelante';
    APIGroup = 'operations';
    APIVersion = 'v1.0';
    EntityName = 'materialOperationBatch';
    EntitySetName = 'materialOperationBatches';

    SourceTable = "GJW Bulk Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = ID;
    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(requestJson; RequestJson)
                {
                    Caption = 'Request JSON';
                }
                field(execute; Execute)
                {
                    Caption = 'Execute';

                    trigger OnValidate()
                    begin
                        if not Execute then
                            exit;

                        ProcessRequest();
                        Execute := false;
                    end;
                }
                field(success; Success)
                {
                    Caption = 'Success';
                    Editable = false;
                }
                field(responseJson; ResponseJson)
                {
                    Caption = 'Response JSON';
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.ID := 1;
        Rec.Insert();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if RequestJson = '' then
            Error('requestJson es requerido.');

        ProcessRequest();
        exit(true);
    end;

    local procedure ProcessRequest()
    var
        Processor: Codeunit "GJW Material Op Bulk Proc";
        ErrorObj: JsonObject;
    begin
        Success := false;
        ResponseJson := '';

        if not TryProcessRequest(Processor) then begin
            ErrorObj.Add('ok', false);
            ErrorObj.Add('error', GetLastErrorText());
            ErrorObj.WriteTo(ResponseJson);
            exit;
        end;

        Success := true;
    end;

    [TryFunction]
    local procedure TryProcessRequest(var Processor: Codeunit "GJW Material Op Bulk Proc")
    begin
        ResponseJson := Processor.ProcessRequest(RequestJson);
    end;

    var
        RequestJson: Text;
        Execute: Boolean;
        Success: Boolean;
        ResponseJson: Text;
}
