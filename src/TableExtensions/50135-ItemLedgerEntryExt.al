tableextension 50135 "GJW Item Ledger Entry Ext" extends "Item Ledger Entry"
{
    fields
    {
        field(50100; "Task No."; Code[20])
        {
            Caption = 'Task No.';
            DataClassification = CustomerContent;
        }

        field(50101; "ID Boleta Entrega"; Code[30])
        {
            Caption = 'ID Boleta Entrega';
            DataClassification = ToBeClassified;
        }

        field(50200; "GJW New Job No."; Code[20])
        {
            Caption = 'New Job No.';
            DataClassification = CustomerContent;
        }

        field(50201; "GJW New Job Task No."; Code[20])
        {
            Caption = 'New Job Task No.';
            DataClassification = CustomerContent;
        }

        // ─── Personas del movimiento (1.2.28.0) ───────────────────────────────────────
        // El "User ID" estándar es siempre la cuenta de servicio (DIGITACION-APP o
        // BUSINESSCENTRAL_API_ADELANTE), así que no dice quién hizo el movimiento.
        // Origen se pone solo al registrar (codeunit 50157). Digitado por sale del
        // realizadoPor que manda Digitación. Encargado, Bodega y Transportista los estampa
        // la app de Boletas después de registrar (codeunit 50270).
        field(50110; "GJW Origen"; Text[20])
        {
            Caption = 'Origen';
            DataClassification = CustomerContent;
        }
        field(50111; "GJW Encargado"; Text[100])
        {
            Caption = 'Encargado';
            DataClassification = CustomerContent;
        }
        field(50112; "GJW Bodega"; Text[100])
        {
            Caption = 'Bodega';
            DataClassification = CustomerContent;
        }
        field(50113; "GJW Transportista"; Text[100])
        {
            Caption = 'Transportista';
            DataClassification = CustomerContent;
        }
        field(50114; "GJW Digitado Por"; Text[100])
        {
            Caption = 'Digitado por';
            DataClassification = CustomerContent;
        }
    }
}
