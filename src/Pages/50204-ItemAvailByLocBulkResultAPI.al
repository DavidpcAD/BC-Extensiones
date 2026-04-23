namespace Adelante.Inventory;

page 50204 "GJW Item Avail Bulk Result API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'itemAvailByLocBulkResult';
    EntitySetName = 'itemAvailByLocBulkResults';

    SourceTable = "GJW Item Avail Bulk Result";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(requestId; Rec."Request Id")
                {
                    Caption = 'Request Id';
                    Editable = false;
                }
                field(requestIdText; Rec."Request Id Text")
                {
                    Caption = 'Request Id Text';
                    Editable = false;
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                    Editable = false;
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                    Editable = false;
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                    Editable = false;
                }
                field(availableQuantity; Rec."Available Quantity")
                {
                    Caption = 'Available Quantity';
                    Editable = false;
                }
                field(requestedAt; Rec."Requested At")
                {
                    Caption = 'Requested At';
                    Editable = false;
                }
            }
        }
    }
}
