pageextension 50131 "GJW Works Line Page Ext" extends "GomJob Works Sub"
{
    layout
    {
        addafter(Description)
        {
            field("ID Encargado"; Rec."ID Encargado")
            {
                ApplicationArea = All;
                Caption = 'ID Encargado';
                ToolTip = 'Identificador del encargado responsable de esta línea';
                Visible = true;
                Enabled = true;
            }
        }
    }
}
