pageextension 50145 "GJW Works Sub 2 Ext" extends "GomJob Works Sub 2"
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
