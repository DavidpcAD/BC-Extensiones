// ════════════════════════════════════════════════════════════════════════════════
// PageExtension 50254 "GJW Location Card Ext" extends "Location Card" (5703)
// Mismo campo Real / Virtual, editable también desde la ficha del almacén.
// ════════════════════════════════════════════════════════════════════════════════
pageextension 50254 "GJW Location Card Ext" extends "Location Card"
{
    layout
    {
        addafter(Name)
        {
            field("GJW Tipo Almacen"; Rec."GJW Tipo Almacen")
            {
                ApplicationArea = All;
                Caption = 'Tipo de almacén';
                ToolTip = 'Indica si el almacén es físico (Real) o lógico (Virtual).';
            }
        }
    }
}
