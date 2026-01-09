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
        field(3; "Template Name"; Code[10])
        {
            Caption = 'Template Name';
            DataClassification = CustomerContent;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(6; "Project No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = CustomerContent;
        }
        field(7; "Project Task No."; Text[20])
        {
            Caption = 'Project Task No.';
            DataClassification = CustomerContent;
        }
        field(8; Type; Text[20])
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
        }
        field(9; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(12; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
        }
        field(13; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DataClassification = CustomerContent;
        }
        field(14; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = CustomerContent;
        }
        field(15; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
        }
        field(16; "Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
            DataClassification = CustomerContent;
        }
        field(17; "Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
        }
        field(100; "Lines Posted"; Integer)
        {
            Caption = 'Lines Posted';
            DataClassification = CustomerContent;
        }
        field(101; "Success Message"; Text[250])
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
