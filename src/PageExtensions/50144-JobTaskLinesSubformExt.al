pageextension 50144 "GJW Job Task Lines Subform Ext" extends "Job Task Lines Subform"
{
    layout
    {
        addafter(Description)
        {
            field("ID Encargado"; Rec."ID Encargado")
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
