pageextension 50132 "GJW Works Decomp Page Ext" extends "GomJob Works Decomposed Line"
{
    layout
    {
        addafter(Description)
        {
            field("ID Visibles Text"; Rec."ID Visibles Text")
            {
                ApplicationArea = All;
                Caption = 'ID Visibles';
                ToolTip = 'Identificador visible asociado a esta línea';
                Visible = true;
                Enabled = true;
            }
        }
    }
}
