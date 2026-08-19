tableextension 50169 JobLedgerEntryExt extends "Job Ledger Entry"
{
    fields
    {
        field(50100; "ID Boleta Entrega"; Code[30])
        {
            DataClassification = CustomerContent;
            Caption = 'ID Boleta Entrega';
        }
        field(50110; "GJW Realizado Por"; Text[50])
        {
            Caption = 'Realizado por';
            DataClassification = CustomerContent;
        }
    }
}