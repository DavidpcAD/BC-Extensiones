tableextension 50181 "GJW Job Jnl Line Ext" extends "Job Journal Line"
{
    fields
    {
        field(50180; "GJW Preserve Unit Cost"; Decimal)
        {
            Caption = 'Preserve Unit Cost';
            DataClassification = CustomerContent;
        }
        field(50110; "GJW Realizado Por"; Text[50])
        {
            Caption = 'Realizado por';
            DataClassification = CustomerContent;
        }
    }
}
