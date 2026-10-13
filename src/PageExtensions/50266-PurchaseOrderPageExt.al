// Muestra en la ficha del Pedido de compra quién lo creó y quién lo registra (datos de la
// app de proveeduría). "Pedido creado por" se llena al crear; "Realizado por" al registrar.
pageextension 50266 "GJW Purchase Order Page Ext" extends "Purchase Order"
{
    layout
    {
        addlast(General)
        {
            field("GJW Pedido Creado Por"; Rec."GJW Pedido Creado Por")
            {
                ApplicationArea = All;
                Caption = 'Pedido creado por';
                Editable = false;
                ToolTip = 'Persona que creó el pedido desde la app de proveeduría (no la cuenta de servicio de la integración).';
            }
            field("GJW Realizado Por"; Rec."GJW Realizado Por")
            {
                ApplicationArea = All;
                Caption = 'Registrado por';
                Editable = false;
                ToolTip = 'Persona que registra la factura/recepción desde la app. Se llena al registrar.';
            }
        }
    }
}
