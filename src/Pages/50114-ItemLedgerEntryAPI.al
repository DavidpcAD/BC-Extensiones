page 50114 "GJW Item Ledger Entry API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';

    EntityName = 'itemLedgerEntryWithTasks';
    EntitySetName = 'itemLedgerEntriesWithTasks';

    SourceTable = "Item Ledger Entry";
    ODataKeyFields = "Entry No.";
    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Main)
            {
                field(entryNo; Rec."Entry No.") { }

                field(entryType; Rec."Entry Type") { }
                field(documentType; Rec."Document Type") { }
                field(documentNo; Rec."Document No.") { }
                field(sourceNo; Rec."Source No.") { }

                field(vendorName; VendorName) { Caption = 'Vendor Name'; }

                field(itemNo; Rec."Item No.") { }
                field(variantCode; Rec."Variant Code") { }
                field(description; Rec.Description) { }
                field(globalDimension1Code; Rec."Global Dimension 1 Code") { }
                field(locationCode; Rec."Location Code") { }

                field(stock; Rec."Remaining Quantity") { Caption = 'Stock'; }
                field(gomJobCostPerUnit; Rec."GomJob Cost per Unit") { }
                field(gomJobWarehouseQuantity; Rec."GomJob Warehouse Quantity") { }
            }

            // 🔸 Esta parte la eliminamos por ahora
            // part(tasks; "GJW Warehouse Quantity API")
            // {
            //     SubPageLink = "Item Ledger Entry No." = FIELD("Entry No."),
            //                   "Job No." = FIELD("Global Dimension 1 Code");
            // }
        }
    }

    var
        VendorName: Text[100];

    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
    begin
        if Rec."Source No." <> '' then
            if Vendor.Get(Rec."Source No.") then
                VendorName := Vendor.Name
            else
                VendorName := '';
    end;
}
