// ════════════════════════════════════════════════════════════════════════════════
// PageExtension 50151 "GJW Job Ledger Entries Ext" extends "Job Ledger Entries" (92)
// Muestra "Realizado por" (username del login de la app) al lado de "Nº documento".
// El "User ID" estándar no se toca (sigue siendo la cuenta de servicio DIGITACION-APP).
// ════════════════════════════════════════════════════════════════════════════════
pageextension 50151 "GJW Job Ledger Entries Ext" extends "Job Ledger Entries"
{
    layout
    {
        addafter("Document No.")
        {
            field("GJW Realizado Por"; Rec."GJW Realizado Por")
            {
                ApplicationArea = All;
                Caption = 'Realizado por';
                ToolTip = 'Usuario del login de la app que originó el movimiento (distinto del User ID de la cuenta de servicio).';
            }
        }
    }
}
