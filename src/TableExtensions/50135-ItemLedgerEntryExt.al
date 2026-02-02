tableextension 50135 "GJW Item Ledger Entry Ext" extends "Item Ledger Entry"
{
    fields
    {
        field(50100; "Task No."; Code[20])
        {
            Caption = 'Task No.';
            DataClassification = CustomerContent;
        }

        field(50101; "ID Boleta Entrega"; Code[30])
        {
            Caption = 'ID Boleta Entrega';
            DataClassification = ToBeClassified;
        }
    }
}
