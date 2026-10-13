// Columnas en la lista de Facturas de compra registradas para ver de un vistazo quién creó
// el pedido y quién registró la factura. Vienen ocultas: se agregan con Personalizar.
pageextension 50268 "GJW Posted Purch Inv List Ext" extends "Posted Purchase Invoices"
{
    layout
    {
        addlast(Control1)
        {
            field("GJW Pedido Creado Por"; Rec."GJW Pedido Creado Por")
            {
                ApplicationArea = All;
                Caption = 'Pedido creado por';
                Visible = false;
                ToolTip = 'Persona que creó el pedido desde la app de proveeduría.';
            }
            field("GJW Realizado Por"; Rec."GJW Realizado Por")
            {
                ApplicationArea = All;
                Caption = 'Factura registrada por';
                Visible = false;
                ToolTip = 'Persona que registró la factura desde la app de proveeduría.';
            }
        }
    }
}
