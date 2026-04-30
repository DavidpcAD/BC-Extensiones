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

        field(50200; "GJW New Job No."; Code[20])
        {
            Caption = 'New Job No.';
            DataClassification = CustomerContent;
        }

        field(50201; "GJW New Job Task No."; Code[20])
        {
            Caption = 'New Job Task No.';
            DataClassification = CustomerContent;
        }
    }
}
