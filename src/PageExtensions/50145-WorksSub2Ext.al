pageextension 50145 "GJW Works Sub 2 Ext" extends "GomJob Works Sub 2"
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
