// Columna "Pedido creado por" en la lista de Pedidos de compra, junto al proveedor.
// Solo el creador: en pedidos abiertos el "Realizado por" sale vacío.
pageextension 50269 "GJW Purchase Order List Ext" extends "Purchase Order List"
{
    layout
    {
        addafter("Buy-from Vendor Name")
        {
            field(PedidoCreadoPor; Rec."GJW Pedido Creado Por")
            {
                ApplicationArea = All;
                Caption = 'Pedido creado por';
                Editable = false;
                ToolTip = 'Persona que creó el pedido desde la app de proveeduría.';
            }
        }
    }
}
