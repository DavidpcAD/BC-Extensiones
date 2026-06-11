namespace Adelante.Inventory;

table 50221 "GJW Material Operation Step"
{
    Caption = 'Material Operation Step';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Operation Id"; Guid)
        {
            Caption = 'Operation Id';
            DataClassification = SystemMetadata;
        }
        field(3; Step; Option)
        {
            Caption = 'Step';
            OptionMembers = Reverse,Physical,FinalConsume,Close;
            DataClassification = CustomerContent;
        }
        field(4; "Attempt No."; Integer)
        {
            Caption = 'Attempt No.';
            DataClassification = CustomerContent;
        }
        field(5; "Status Before"; Option)
        {
            Caption = 'Status Before';
            OptionMembers = PendingReverse,ReverseDone,PhysicalDone,FinalConsumeDone,Closed,Failed;
            DataClassification = CustomerContent;
        }
        field(6; "Status After"; Option)
        {
            Caption = 'Status After';
            OptionMembers = PendingReverse,ReverseDone,PhysicalDone,FinalConsumeDone,Closed,Failed;
            DataClassification = CustomerContent;
        }
        field(7; Success; Boolean)
        {
            Caption = 'Success';
            DataClassification = CustomerContent;
        }
        field(8; "Started At"; DateTime)
        {
            Caption = 'Started At';
            DataClassification = SystemMetadata;
        }
        field(9; "Finished At"; DateTime)
        {
            Caption = 'Finished At';
            DataClassification = SystemMetadata;
        }
        field(10; "Request Json"; Text[2048])
        {
            Caption = 'Request Json';
            DataClassification = CustomerContent;
        }
        field(11; "Response Json"; Text[2048])
        {
            Caption = 'Response Json';
            DataClassification = CustomerContent;
        }
        field(12; "Error Text"; Text[2048])
        {
            Caption = 'Error Text';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(K1; "Operation Id", Step, "Attempt No.")
        {
        }
        key(K2; "Operation Id", "Started At")
        {
        }
    }
}
