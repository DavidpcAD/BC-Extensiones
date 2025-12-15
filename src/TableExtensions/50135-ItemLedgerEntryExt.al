tableextension 50135 "GJW Item Ledger Entry Ext" extends "Item Ledger Entry"
{
    fields
    {
        field(50100; "Task No."; Code[20])
        {
            Caption = 'Task No.';
            DataClassification = CustomerContent;
        }
    }
}
