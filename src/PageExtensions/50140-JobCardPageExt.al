pageextension 50140 "GJW Job Card Ext" extends "Job Card"
{
    layout
    {
        addafter("Person Responsible")
        {
            field("ID Encargado Text"; Rec."ID Encargado Text")
            {
                ApplicationArea = All;
                Caption = 'ID Encargado';
                ToolTip = 'ID del encargado del proyecto';
            }
            field("Area Prorrateada"; Rec."Area Prorrateada")
            {
                ApplicationArea = All;
                Caption = 'Area Prorrateada';
                ToolTip = 'Area prorrateada del proyecto';
            }
        }
    }
}
