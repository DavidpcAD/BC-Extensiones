pageextension 50145 "GJW Works Sub 2 Ext" extends "GomJob Works Sub 2"
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
