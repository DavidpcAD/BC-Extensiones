page 50115 "GJW Warehouse Quantity API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'warehouseQuantity';
    EntitySetName = 'warehouseQuantities';

    SourceTable = "GomJob Warehouse Quantity";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    // CRUD (ajusta si quieres solo lectura)
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Details)
            {
                field(systemId; Rec.SystemId) { Caption = 'System Id'; ApplicationArea = All; }
                field(ItemLedgerEntryNo; Rec."Item Ledger Entry No.") { }
                field(JobNo; Rec."Job No.") { }
                field(JobTaskNo; Rec."Job Task No.") { }
                field(JobTaskDescription; Rec."Job Task Description") { }
                field(quantity; Rec.Quantity) { ApplicationArea = All; }
            }
        }
    }
}