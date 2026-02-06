pageextension 50148 "ADL Job Jnl Batch Page Ext" extends "Job Journal Batches"
{
    layout
    {
        addafter(Description)
        {
            field("ADL ID Colaborador"; Rec."ADL ID Colaborador")
            {
                ApplicationArea = All;
                Caption = 'ID Colaborador';
                ToolTip = 'Identificador del colaborador responsable del batch';
            }
        }
    }
}
