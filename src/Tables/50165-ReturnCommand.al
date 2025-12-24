table 50165 "GJW Return Command"
{
    TableType = Temporary;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = CustomerContent;
        }
        field(2; "Task No."; Code[20])
        {
            Caption = 'Task No.';
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
        field(5; "Quantity"; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
        }
        field(6; "Return Type"; Option)
        {
            Caption = 'Return Type';
            OptionMembers = "To General Warehouse","To Another Job";
            OptionCaption = 'To General Warehouse,To Another Job';
            DataClassification = CustomerContent;
        }
        field(7; "Destination Job No."; Code[20])
        {
            Caption = 'Destination Job No.';
            DataClassification = CustomerContent;
        }
        field(12; "Destination Task No."; Code[20])
        {
            Caption = 'Destination Task No.';
            DataClassification = CustomerContent;
        }
        field(8; "Source Location Code"; Code[10])
        {
            Caption = 'Source Location Code';
            DataClassification = CustomerContent;
        }
        field(9; "Destination Location Code"; Code[10])
        {
            Caption = 'Destination Location Code';
            DataClassification = CustomerContent;
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(11; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            DataClassification = CustomerContent;
        }
        field(20; "Lines Posted"; Integer)
        {
            Caption = 'Lines Posted';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(21; "Success Message"; Text[250])
        {
            Caption = 'Success Message';
            Editable = false;
            DataClassification = CustomerContent;
        }
        // Campos auxiliares para recibir desde Power Apps (no son parte de la clave)
        field(30; "Input Job No."; Code[20])
        {
            Caption = 'Input Job No.';
            DataClassification = CustomerContent;
        }
        field(31; "Input Task No."; Code[20])
        {
            Caption = 'Input Task No.';
            DataClassification = CustomerContent;
        }
        field(32; "Input Item No."; Code[20])
        {
            Caption = 'Input Item No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Job No.", "Task No.", "Item No.", "Variant Code")
        {
            Clustered = true;
        }
    }
}
