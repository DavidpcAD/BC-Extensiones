pageextension 50134 "GJW Item Journal Line Page" extends "Item Reclass. Journal"
{
    layout
    {
        addafter(Description)
        {
            field("Task No."; Rec."Task No.")
            {
                ApplicationArea = All;
                Caption = 'Task No.';
                ToolTip = 'Número de tarea asociada a esta línea';
            }
        }
    }
}
