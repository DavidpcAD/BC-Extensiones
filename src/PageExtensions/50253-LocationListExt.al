// ════════════════════════════════════════════════════════════════════════════════
// PageExtension 50253 "GJW Location List Ext" extends "Location List" (15)
// Permite marcar desde la lista de Almacenes si cada uno es Real o Virtual.
// ════════════════════════════════════════════════════════════════════════════════
pageextension 50253 "GJW Location List Ext" extends "Location List"
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
