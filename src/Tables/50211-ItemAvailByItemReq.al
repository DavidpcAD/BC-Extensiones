namespace Adelante.Inventory;

table 50211 "GJW Item Avail By Item Req"
{
    Caption = 'Item Availability By Item Request';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = CustomerContent;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }
        field(3; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(4; "Location Filter"; Text[250])
        {
            Caption = 'Location Filter';
            DataClassification = CustomerContent;
        }
        field(5; "Request Id"; Text[50])
        {
            Caption = 'Request Id';
            DataClassification = CustomerContent;
        }
        field(6; Status; Text[20])
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(7; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(8; "Requested At"; DateTime)
        {
            Caption = 'Requested At';
            DataClassification = CustomerContent;
        }
        field(9; "Result Json"; Text[2048])
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
