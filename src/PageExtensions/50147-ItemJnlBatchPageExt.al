pageextension 50147 "ADL Item Jnl Batch Page Ext" extends "Item Journal Batches"
{
    layout
    {
        addafter(Description)
        {
            field("ADL ID Colaborador"; Rec."GJW ID Colaborador")
            {
                ApplicationArea = All;
                Caption = 'ID Colaborador';
                ToolTip = 'Identificador del colaborador responsable del batch';
            }
        }
    }
}
