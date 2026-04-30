table 50205 "GJW Sync Tasks Buffer"
{
    TableType = Temporary;
    Caption = 'Sync Tasks Buffer';

    fields
    {
        field(1; "Works No."; Code[20])
        {
            Caption = 'Works No.';
            DataClassification = CustomerContent;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            DataClassification = CustomerContent;
        }
        field(3; "Tasks Created"; Integer)
        {
            Caption = 'Tasks Created';
            DataClassification = SystemMetadata;
        }
        field(4; "Tasks Skipped"; Integer)
        {
            Caption = 'Tasks Skipped';
            DataClassification = SystemMetadata;
        }
        field(5; "Result Message"; Text[500])
        {
            Caption = 'Result Message';
            DataClassification = SystemMetadata;
        }
        field(6; "Error Message"; Text[500])
        {
            Caption = 'Error Message';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Works No.", "Job Task No.")
        {
            Clustered = true;
        }
    }
}
