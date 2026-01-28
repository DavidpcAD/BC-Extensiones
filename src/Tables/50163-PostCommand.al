table 50163 "GJW Post Command"
{
    TableType = Temporary;
    Caption = 'Post Command';

    fields
    {
        field(1; "Command ID"; Guid)
        {
            Caption = 'Command ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Command Data"; Text[250])
        {
            Caption = 'Command Data';
            DataClassification = CustomerContent;
        }
        field(10; "Lines Posted"; Integer)
        {
            Caption = 'Lines Posted';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(11; "Success Message"; Text[2048])
        {
            Caption = 'Success Message';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(12; "JSON Results"; Text[2048])
        {
            Caption = 'JSON Results';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(20; "Posting Status"; Enum "GJW Posting Status")
        {
            Caption = 'Posting Status';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(21; "Error Details"; Text[2048])
        {
            Caption = 'Error Details';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(30; "Processing Started"; DateTime)
        {
            Caption = 'Processing Started';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(31; "Processing Completed"; DateTime)
        {
            Caption = 'Processing Completed';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(32; "Duration (ms)"; Integer)
        {
            Caption = 'Duration (ms)';
            Editable = false;
            DataClassification = SystemMetadata;
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
