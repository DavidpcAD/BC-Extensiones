page 50126 "GJW Warehouse"
{
    Caption = 'GJW Warehouse';
    PageType = API;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Item Ledger Entry";

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'warehouse';
    EntitySetName = 'warehouses';

    ODataKeyFields = SystemId;
    DelayedInsert = true;

    // Habilitado CRUD
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    ApplicationArea = All;
                }
                field(documentDate; Rec."Document Date")
                {
                    ApplicationArea = All;
                }
                field(entryType; Rec."Entry Type")
                {
                    ApplicationArea = All;
                }
                field(documentType; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field(documentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field(sourceNo; Rec."Source No.")
                {
                    ApplicationArea = All;
                }
                field(vendorName; VendorName)
                {
                    Caption = 'Vendor Name';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(itemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(globalDimension1Code; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = All;
                }
                field(locationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field(stock; Rec."Remaining Quantity")
                {
                    Caption = 'Stock';
                    ApplicationArea = All;
                }
                field(remainingQuantity; Rec."Remaining Quantity")
                {
                    ApplicationArea = All;
                }
                field(costPerUnit; Rec."GomJob Cost per Unit")
                {
                    ApplicationArea = All;
                }
                field(warehouseQuantity; Rec."GomJob Warehouse Quantity")
                {
                    ApplicationArea = All;
                }
                field(entryNo; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GenerateJobJournalLines)
            {
                Caption = 'Generate Job Journal Lines';
                ApplicationArea = All;
                Image = CreateJobSalesInvoice;

                trigger OnAction()
                begin
                    // TODO: Implementar lógica para generar líneas de diario de proyecto
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetVendorName();
    end;

    local procedure GetVendorName()
    var
        Vendor: Record Vendor;
    begin
        Clear(VendorName);
        if Rec."Source Type" = Rec."Source Type"::Vendor then
            if Vendor.Get(Rec."Source No.") then
                VendorName := Vendor.Name;
    end;

    var
        VendorName: Text[100];
}
