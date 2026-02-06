pageextension 50143 "GJW Job Task Lines Ext" extends "Job Task Lines"
{
    layout
    {
        addafter(Description)
        {
            field("ID Encargado Text"; Rec."ID Encargado Text")
            {
                ApplicationArea = All;
                Caption = 'ID Encargado';
                ToolTip = 'ID del encargado de la tarea';
                Visible = true;
                Enabled = true;
            }
        }
    }
}
