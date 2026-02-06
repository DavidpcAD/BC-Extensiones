tableextension 50182 "ADL Job Jnl Batch Ext" extends "Job Journal Batch"
{
    fields
    {
        field(50099; "ADL ID Colaborador"; Code[20])
        {
            Caption = 'ID Colaborador';
            DataClassification = CustomerContent;
        }
    }
}
