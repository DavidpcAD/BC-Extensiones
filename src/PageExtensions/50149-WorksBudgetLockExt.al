pageextension 50149 "GJW Works Budget Lock Ext" extends "GomJob Works Card"
{
    // 🔒 Bloquea edición en BC cuando el presupuesto fue enviado desde Power Apps.
    // Power Apps puede seguir enviando presupuestos (el codeunit ignora este flag).

    layout
    {
        addafter(Blocked)
        {
            field("Budget Locked"; Rec."Budget Locked")
            {
                ApplicationArea = All;
                Caption = 'Presupuesto Bloqueado';
                ToolTip = 'Activo cuando el presupuesto fue enviado desde Power Apps. La ficha queda en solo lectura desde Business Central.';
                Editable = false;
                Style = Unfavorable;
                StyleExpr = Rec."Budget Locked";
            }
            field("En Ejecucion"; Rec."En Ejecucion")
            {
                ApplicationArea = All;
                Caption = 'En Ejecución';
                ToolTip = 'Indica si la obra está actualmente en construcción (activa) o ya fue terminada.';
            }
        }
    }

}
