table 50163 "GJW Post Command"
{
    TableType = Temporary;

    fields
    {
        field(1; "Command Data"; Text[250])
        {
            Caption = 'Command Data';
        }
        field(10; "Lines Posted"; Integer)
        {
            Caption = 'Lines Posted';
            Editable = false;
        }
        field(11; "Success Message"; Text[250])
        {
            Caption = 'Success Message';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Command Data")
        {
            Clustered = true;
        }
    }
}
