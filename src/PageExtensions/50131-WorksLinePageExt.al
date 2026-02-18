pageextension 50131 "GJW Works Line Page Ext" extends "GomJob Works Sub"
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
