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
                field(postingDate; Rec."Posting Date") { }
                field(sourceNo; Rec."Source No.") { }

                field(vendorName; VendorName) { Caption = 'Vendor Name'; }

                field(itemNo; Rec."Item No.") { }
                field(variantCode; Rec."Variant Code") { }
                field(description; Rec.Description) { }
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { }
                field(lotNo; Rec."Lot No.") { }
                field(serialNo; Rec."Serial No.") { }
                field(globalDimension1Code; Rec."Global Dimension 1 Code") { }
                field(locationCode; Rec."Location Code") { }

                field(stock; Rec."Remaining Quantity") { Caption = 'Stock'; }
                field(stockTxt; StockTxt) { Caption = 'Stock Text'; }
                field(open; Rec.Open) { }
                field(costAmountActual; Rec."Cost Amount (Actual)") { }
                field(gomJobCostPerUnit; Rec."GomJob Cost per Unit") { }
                field(gomJobWarehouseQuantity; Rec."GomJob Warehouse Quantity") { }

                field(jobTaskNo; JobTaskNo)
                {
                    Caption = 'Job Task No.';
                    Editable = false;
                }

                field(idBoletaEntrega; Rec."ID Boleta Entrega")
                {
                    Caption = 'ID Boleta Entrega';
                }
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
        JobTaskNo: Code[20];
        StockTxt: Text[50];

    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
        GomJobWarehouseQty: Record "GomJob Warehouse Quantity";
    begin
        if Rec."Source No." <> '' then
            if Vendor.Get(Rec."Source No.") then
                VendorName := Vendor.Name
            else
                VendorName := '';

        // Convertir stock a texto
        StockTxt := Format(Rec."Remaining Quantity");

        // Obtener todas las Job Task No. relacionadas
        Clear(JobTaskNo);
        GomJobWarehouseQty.SetRange("Item Ledger Entry No.", Rec."Entry No.");
        if GomJobWarehouseQty.FindSet() then
            repeat
                if JobTaskNo <> '' then
                    JobTaskNo += ',' + GomJobWarehouseQty."Job Task No."
                else
                    JobTaskNo := GomJobWarehouseQty."Job Task No.";
            until GomJobWarehouseQty.Next() = 0;
    end;
}
