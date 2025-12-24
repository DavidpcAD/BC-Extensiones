pageextension 50140 "GJW Job Card Ext" extends "Job Card"
{
    layout
    {
        addafter("Person Responsible")
        {
            field("ID Encargado"; Rec."ID Encargado")
            {
                ApplicationArea = All;
                Caption = 'ID Encargado';
                ToolTip = 'ID del encargado del proyecto';
            }
        }
    }
}
