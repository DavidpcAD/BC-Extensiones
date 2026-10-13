// Guarda en la RECEPCIÓN REGISTRADA (documento permanente) quién creó el pedido y quién
// registró la recepción, traídos de la app de proveeduría. Mismos N.º y nombres que en
// Purchase Header. Lo copia el codeunit 50265 "GJW Purch Post Attribution" en el registro.
tableextension 50264 "GJW Purch Rcpt Header Ext" extends "Purch. Rcpt. Header"
{
    fields
    {
        field(50110; "GJW Realizado Por"; Text[50])
        {
            Caption = 'Recepción registrada por';
            DataClassification = CustomerContent;
        }
        field(50111; "GJW Pedido Creado Por"; Text[50])
        {
            Caption = 'Pedido creado por';
            DataClassification = CustomerContent;
        }
    }
}
