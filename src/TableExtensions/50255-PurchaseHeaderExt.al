tableextension 50255 "GJW Purchase Header Ext" extends "Purchase Header"
{
    fields
    {
        // Quién está haciendo el movimiento DESDE LA APP (no la cuenta de servicio con
        // la que la app entra a BC, que siempre es la misma). El pedido de compra es el
        // único lugar donde ese dato puede esperar: cuando se registra la factura, BC
        // arma la Job Journal Line del consumo a partir de la línea del pedido, y de ahí
        // sale el "Realizado por" del Mov. proyecto. Lo estampa AdelantePO_SetRealizadoPor
        // y lo copia el codeunit 50245 "GJW Realizado Por Handler".
        // Mismo N.º de campo (50110) y mismo nombre que en Job Journal Line / Job Ledger
        // Entry a propósito: es el mismo dato viajando.
        field(50110; "GJW Realizado Por"; Text[50])
        {
            Caption = 'Realizado por';
            DataClassification = CustomerContent;
        }
    }
}
