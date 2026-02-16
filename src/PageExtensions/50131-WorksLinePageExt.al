pageextension 50131 "GJW Works Line Page Ext" extends "GomJob Works Sub"
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
