table 50163 "GJW Post Command"
{
    TableType = Temporary;

    fields
    {
        field(1; "Batch Name"; Code[20])
        {
            Caption = 'Batch Name';
        }
        field(2; "Template Name"; Code[10])
        {
            Caption = 'Template Name';
        }
        field(10; "Lines Posted"; Integer)
        {
            Caption = 'Lines Posted';
        }
        field(11; "Success Message"; Text[250])
        {
            Caption = 'Success Message';
        }
    }

    keys
    {
        key(PK; "Batch Name")
        {
            Clustered = true;
        }
    }
}
