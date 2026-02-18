pageextension 50146 "GJW Works Sub 3 Ext" extends "GomJob Works Sub 3"
{
    layout
    {
        addafter(Description)
        {
            field("IDVisibles"; Rec."IDVisibles")
            {
                ApplicationArea = All;
                Caption = 'IDVisibles';
                ToolTip = 'Identificador visible asociado a esta línea';
                Visible = true;
                Enabled = true;
            }
        }
    }
}
