pageextension 50142 "GJW Works Page Ext" extends "GomJob Works"
{
    layout
    {
        addlast(content)
        {
            field("ID Encargado Text"; Rec."ID Encargado Text")
            {
                ApplicationArea = All;
                Caption = 'ID Encargado';
                ToolTip = 'ID del encargado de la obra';
            }
        }
    }
}
