// Columnas en la lista de Facturas de compra registradas: quién recibió/registró la factura
// y quién creó el pedido. Visibles, junto al proveedor.
pageextension 50268 "GJW Posted Purch Inv List Ext" extends "Posted Purchase Invoices"
{
    layout
    {
        addafter("Buy-from Vendor Name")
        {
            field(RecibidoPor; Rec."GJW Realizado Por")
            {
                ApplicationArea = All;
                Caption = 'Recibido por';
                Visible = true;
                ToolTip = 'Persona que registró/recibió la factura desde la app.';
            }
            field(PedidoCreadoPor; Rec."GJW Pedido Creado Por")
            {
                ApplicationArea = All;
                Caption = 'Pedido creado por';
                Visible = true;
                ToolTip = 'Persona que creó el pedido desde la app de proveeduría.';
            }
        }
    }
}
