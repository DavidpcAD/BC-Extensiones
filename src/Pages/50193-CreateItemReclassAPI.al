page 50193 "GJW Create Item Reclass API"
{
    PageType = API;
    Caption = 'Create Item Reclass Line API';
    APIPublisher = 'adelante';
    APIGroup = 'returns';
    APIVersion = 'v1.0';
    EntityName = 'createItemReclassLine';
    EntitySetName = 'createItemReclassLines';
    SourceTable = "Integer";
    SourceTableTemporary = true;
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
                field(itemNo; ItemNo)
                {
                    ApplicationArea = All;
                }
                field(quantity; Qty)
                {
                    ApplicationArea = All;
                }
                field(locationCode; FromLocation)
                {
                    ApplicationArea = All;
                }
                field(newLocationCode; ToLocation)
                {
                    ApplicationArea = All;
                }
                field(success; Success)
                {
                    ApplicationArea = All;
                    Caption = 'Success';
                }
                field(message; Message)
                {
                    ApplicationArea = All;
                    Caption = 'Message';
                }
            }
        }
    }

    var
        ItemNo: Code[20];
        Qty: Decimal;
        FromLocation: Code[10];
        ToLocation: Code[10];
        Success: Boolean;
        Message: Text[250];

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        CreateItemReclass: Codeunit "GJW Create Item Reclass Line";
    begin
        Success := false;
        Message := '';

        if CreateItemReclass.CreateLine(ItemNo, Qty, FromLocation, ToLocation) then begin
            Success := true;
            Message := 'Línea creada correctamente';
        end else begin
            Success := false;
            Message := 'Error al crear línea';
        end;

        exit(false);
    end;
}
