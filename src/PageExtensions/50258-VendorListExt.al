// ════════════════════════════════════════════════════════════════════════════════
// PageExtension 50258 "GJW Vendor List Ext" extends "Vendor List" (27)
// La identificación también en la lista: es el dato con el que Contabilidad busca
// al proveedor, y así se ve de un vistazo a quién le falta.
// ════════════════════════════════════════════════════════════════════════════════
pageextension 50258 "GJW Vendor List Ext" extends "Vendor List"
{
    layout
    {
        addafter(Name)
        {
            field("GJW Tipo Identificacion"; Rec."GJW Tipo Identificacion")
            {
                ApplicationArea = All;
                Caption = 'Tipo de identificación';
                ToolTip = 'Indica si el proveedor es persona física o persona jurídica.';
            }
            field("GJW No. Identificacion"; Rec."GJW No. Identificacion")
            {
                ApplicationArea = All;
                Caption = 'Número de identificación';
                ToolTip = 'Especifica el número de cédula del proveedor, física o jurídica según el tipo de identificación.';
            }
        }
    }
}
