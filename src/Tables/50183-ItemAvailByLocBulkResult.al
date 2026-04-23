namespace Adelante.Inventory;

table 50183 "GJW Item Avail Bulk Result"
{
    Caption = 'Item Availability Bulk Result';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = CustomerContent;
        }
        field(2; "Request Id"; Guid)
        {
            Caption = 'Request Id';
            DataClassification = CustomerContent;
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }
        field(4; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
        }
        field(6; "Available Quantity"; Decimal)
        {
            Caption = 'Available Quantity';
            DataClassification = CustomerContent;
        }
        field(7; "Requested At"; DateTime)
        {
            Caption = 'Requested At';
            DataClassification = CustomerContent;
        }
        field(8; "Request Id Text"; Text[50])
        {
            Caption = 'Request Id Text';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(RequestLookup; "Request Id", "Item No.", "Variant Code")
        {
        }
        key(RequestTextLookup; "Request Id Text")
        {
        }
    }
}
