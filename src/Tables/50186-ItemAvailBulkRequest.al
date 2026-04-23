namespace Adelante.Inventory;

table 50186 "GJW Item Avail Bulk Request"
{
    Caption = 'Item Availability Bulk Request';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = CustomerContent;
        }
        field(2; "Items Json"; Text[2048])
        {
            Caption = 'Items JSON';
            DataClassification = CustomerContent;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
        }
        field(4; "Request Id"; Text[50])
        {
            Caption = 'Request Id';
            DataClassification = CustomerContent;
        }
        field(5; Status; Text[20])
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(6; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(7; "Requested At"; DateTime)
        {
            Caption = 'Requested At';
            DataClassification = CustomerContent;
        }
        field(8; "Result Json"; Text[2048])
        {
            Caption = 'Result JSON';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
