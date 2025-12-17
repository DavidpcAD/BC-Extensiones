table 50160 "GJW Post Journal Command"
{
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(10; "Template Name"; Code[10])
        {
            Caption = 'Template Name';
        }
        field(11; "Batch Name"; Code[20])
        {
            Caption = 'Batch Name';
        }
        field(20; "Result Message"; Text[250])
        {
            Caption = 'Result Message';
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
