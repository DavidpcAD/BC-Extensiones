pageextension 50146 "GJW Works Sub 3 Ext" extends "GomJob Works Sub 3"
{
    layout
    {
        addafter(Description)
        {
            field("ID Encargado"; Rec."ID Encargado")
            {
                ApplicationArea = All;
                Caption = 'ID Encargado';
                ToolTip = 'ID del encargado de esta línea';
                Visible = true;
                Enabled = true;
            }
        }
    }
}
