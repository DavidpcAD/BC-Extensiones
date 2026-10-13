// Muestra en la FACTURA REGISTRADA quién creó el pedido y quién registró la factura.
// Estos valores quedan guardados para siempre (los copió el codeunit 50265 al registrar).
pageextension 50267 "GJW Posted Purch Inv Page Ext" extends "Posted Purchase Invoice"
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
                ToolTip = 'Persona que creó el pedido desde la app de proveeduría.';
            }
            field("GJW Realizado Por"; Rec."GJW Realizado Por")
            {
                ApplicationArea = All;
                Caption = 'Factura registrada por';
                Editable = false;
                ToolTip = 'Persona que registró la factura desde la app de proveeduría.';
            }
        }
    }
}
