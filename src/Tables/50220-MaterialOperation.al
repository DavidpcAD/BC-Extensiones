namespace Adelante.Inventory;

table 50220 "GJW Material Operation"
{
    Caption = 'Material Operation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Operation Id"; Guid)
        {
            Caption = 'Operation Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(3; "Operation Type"; Option)
        {
            Caption = 'Operation Type';
            OptionMembers = ConsumeFromGeneral,TransferConsumedBetweenJobs,ReturnConsumedToGeneral;
            DataClassification = CustomerContent;
        }
        field(4; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = PendingReverse,ReverseDone,PhysicalDone,FinalConsumeDone,Closed,Failed;
            DataClassification = CustomerContent;
        }
        field(5; "Current Step"; Option)
        {
            Caption = 'Current Step';
            OptionMembers = Reverse,Physical,FinalConsume,Close;
            DataClassification = CustomerContent;
        }
        field(6; "Source Job No."; Code[20])
        {
            Caption = 'Source Job No.';
            DataClassification = CustomerContent;
        }
        field(7; "Source Job Task No."; Code[20])
        {
            Caption = 'Source Job Task No.';
            DataClassification = CustomerContent;
        }
        field(8; "Source Location Code"; Code[10])
        {
            Caption = 'Source Location Code';
            DataClassification = CustomerContent;
        }
        field(9; "Destination Job No."; Code[20])
        {
            Caption = 'Destination Job No.';
            DataClassification = CustomerContent;
        }
        field(10; "Destination Job Task No."; Code[20])
        {
            Caption = 'Destination Job Task No.';
            DataClassification = CustomerContent;
        }
        field(11; "Destination Location Code"; Code[10])
        {
            Caption = 'Destination Location Code';
            DataClassification = CustomerContent;
        }
        field(12; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }
        field(13; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
        }
        field(15; "Requires Final Consume"; Boolean)
        {
            Caption = 'Requires Final Consume';
            DataClassification = CustomerContent;
        }
        field(16; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
            DataClassification = CustomerContent;
        }
        field(17; "Last BC Entry Nos"; Text[2048])
        {
            Caption = 'Last BC Entry Nos';
            DataClassification = CustomerContent;
        }
        field(18; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(19; "Updated At"; DateTime)
        {
            Caption = 'Updated At';
            DataClassification = SystemMetadata;
        }
        field(20; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = SystemMetadata;
        }
        field(21; "Correlation Id"; Guid)
        {
            Caption = 'Correlation Id';
            DataClassification = SystemMetadata;
        }
        field(22; "Payload JSON"; Text[2048])
        {
            Caption = 'Payload JSON';
            DataClassification = CustomerContent;
        }
        field(23; "Result JSON"; Text[2048])
        {
            Caption = 'Result JSON';
            DataClassification = CustomerContent;
        }
        field(30; "Execute Next"; Boolean)
        {
            Caption = 'Execute Next';
            DataClassification = CustomerContent;
        }
        field(31; "Execute Until Stop"; Boolean)
        {
            Caption = 'Execute Until Stop';
            DataClassification = CustomerContent;
        }
        field(32; "Retry Failed"; Boolean)
        {
            Caption = 'Retry Failed';
            DataClassification = CustomerContent;
        }
        field(33; "Last Action Message"; Text[250])
        {
            Caption = 'Last Action Message';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Operation Id")
        {
            Clustered = true;
        }
        key(K1; "Document No.")
        {
        }
        key(K2; Status, "Updated At")
        {
        }
    }

    trigger OnInsert()
    begin
        if IsNullGuid("Operation Id") then
            "Operation Id" := CreateGuid();

        if "Document No." = '' then
            "Document No." := CopyStr('OP-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'), 1, 20);

        if IsNullGuid("Correlation Id") then
            "Correlation Id" := CreateGuid();

        Status := Status::PendingReverse;
        "Current Step" := "Current Step"::Reverse;

        "Created At" := CurrentDateTime;
        "Updated At" := CurrentDateTime;
        "Created By" := CopyStr(UserId, 1, MaxStrLen("Created By"));
    end;

    trigger OnModify()
    begin
        "Updated At" := CurrentDateTime;
    end;
}
