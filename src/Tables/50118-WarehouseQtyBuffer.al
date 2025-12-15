table 50118 "GJW Warehouse Quantity Buffer"
{
    DataClassification = ToBeClassified;

    // tu siguiente versión 
    fields
    {
        field(1; "Temp Item Ledger Entry No."; Integer) { Caption = 'Temp Item Ledger Entry No.'; AutoIncrement = false; }
        field(2; "Temp Job Task No."; Code[20]) { Caption = 'Temp Job Task No.'; }
        field(3; Quantity; Decimal) { Caption = 'Quantity'; }
        field(4; "Item Ledger Entry No."; Integer) { Caption = 'Item Ledger Entry No.'; }
        field(5; "Job No."; Code[20]) { Caption = 'Job No.'; }
        field(6; "Job Task No."; Code[20]) { Caption = 'Job Task No.'; }
    }
    keys
    {
        key(PK; "Temp Item Ledger Entry No.", "Temp Job Task No.") { Clustered = true; }
    }
}