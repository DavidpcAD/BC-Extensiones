pageextension 50144 "GJW Job Task Lines Subform Ext" extends "Job Task Lines Subform"
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
