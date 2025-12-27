namespace Adelante.Inventory;

table 50171 ItemAvailBuffer
{
    TableType = Temporary;

    fields
    {
        field(1; ItemNo; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
        }
        field(2; LocationCode; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = ToBeClassified;
        }
        field(3; LocationName; Text[100])
        {
            Caption = 'Location Name';
            DataClassification = ToBeClassified;
        }
        field(4; Inventory; Decimal)
        {
            Caption = 'Inventory';
            DataClassification = ToBeClassified;
        }
        field(5; QtyOnPurchOrder; Decimal)
        {
            Caption = 'Qty on Purch Order';
            DataClassification = ToBeClassified;
        }
        field(6; QtyOnSalesOrder; Decimal)
        {
            Caption = 'Qty on Sales Order';
            DataClassification = ToBeClassified;
        }
        field(7; QtyInTransit; Decimal)
        {
            Caption = 'Qty in Transit';
            DataClassification = ToBeClassified;
        }
        field(8; AvailableInventory; Decimal)
        {
            Caption = 'Available Inventory';
            DataClassification = ToBeClassified;
        }
        field(9; ProjectedAvailable; Decimal)
        {
            Caption = 'Projected Available';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; ItemNo, LocationCode)
        {
            Clustered = true;
        }
    }
}
