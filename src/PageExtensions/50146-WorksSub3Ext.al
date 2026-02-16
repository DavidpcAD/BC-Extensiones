pageextension 50146 "GJW Works Sub 3 Ext" extends "GomJob Works Sub 3"
{
    layout
    {
        addafter(Description)
        {
            field("ID Visibles Text"; Rec."ID Visibles Text")
            {
                ApplicationArea = All;
                Caption = 'ID Visibles';
                ToolTip = 'Identificador visible asociado a esta línea';
                Visible = true;
                Enabled = true;
            }
        }
    }
}
