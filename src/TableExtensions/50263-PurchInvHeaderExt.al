// Guarda en la FACTURA REGISTRADA (documento permanente) quién creó el pedido y quién
// registró la factura, traídos de la app de proveeduría. El pedido se borra al facturarse
// por completo, así que este es el lugar donde la atribución queda de verdad.
// Mismos N.º y nombres que en Purchase Header a propósito: es el mismo dato viajando.
// Lo copia el codeunit 50265 "GJW Purch Post Attribution" en el registro.
tableextension 50263 "GJW Purch Inv Header Ext" extends "Purch. Inv. Header"
{
    fields
    {
        field(50110; "GJW Realizado Por"; Text[50])
        {
            Caption = 'Factura registrada por';
            DataClassification = CustomerContent;
        }
        field(50111; "GJW Pedido Creado Por"; Text[50])
        {
            Caption = 'Pedido creado por';
            DataClassification = CustomerContent;
        }
    }
}
