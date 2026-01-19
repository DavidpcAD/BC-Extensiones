namespace Adelante.Inventory;

table 50172 ItemAvailLocationBuffer
{
    TableType = Temporary;

    fields
    {
        field(1; ItemNo; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(3; LocationCode; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = ToBeClassified;
        }
        field(4; TotalQuantity; Decimal)
        {
            Caption = 'Total Quantity';
            DataClassification = ToBeClassified;
        }
        field(5; RemainingQuantity; Decimal)
        {
            Caption = 'Remaining Quantity';
            DataClassification = ToBeClassified;
        }
        field(6; InvoicedQuantity; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DataClassification = ToBeClassified;
        }
        field(7; UnitOfMeasure; Code[10])
        {
            Caption = 'Unit of Measure';
            DataClassification = ToBeClassified;
        }
        field(8; VariantCode; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; ItemNo, VariantCode, LocationCode)
        {
            Clustered = true;
        }
    }
}
