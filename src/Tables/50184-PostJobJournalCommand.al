namespace Adelante.Tables.JobJournalLine;
table 50184 "GJW Post Job Journal Cmd"
{
    Caption = 'Post Job Journal Command';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Command ID"; Guid)
        {
            Caption = 'Command ID';
            DataClassification = CustomerContent;
        }
        field(2; "Batch Name"; Code[20])
        {
            Caption = 'Batch Name';
            DataClassification = CustomerContent;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(4; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(8; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = CustomerContent;
        }
        field(9; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            DataClassification = CustomerContent;
        }
        field(10; "Lines Posted"; Integer)
        {
            Caption = 'Lines Posted';
            DataClassification = CustomerContent;
        }
        field(11; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DataClassification = CustomerContent;
        }
        field(12; "Success Message"; Text[250])
        {
            Caption = 'Success Message';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Command ID")
        {
            Clustered = true;
        }
    }
}
