pageextension 50141 "GJW Job List Ext" extends "Job List"
{
    layout
    {
        addafter("Person Responsible")
        {
            field("ID Encargado Text"; Rec."ID Encargado Text")
            {
                ApplicationArea = All;
                Caption = 'ID Encargado';
                ToolTip = 'Identificador del encargado responsable del proyecto';
            }
        }
    }
}
