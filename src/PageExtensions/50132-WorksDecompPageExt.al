pageextension 50132 "GJW Works Decomp Page Ext" extends "GomJob Works Decomposed Line"
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
            }
        }
    }
}
