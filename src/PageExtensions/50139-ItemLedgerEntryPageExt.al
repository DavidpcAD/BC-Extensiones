pageextension 50139 "Adelante ILE Costo Unitario" extends "Item Ledger Entries"
{
    layout
    {
        // Personas del movimiento (1.2.28.0, ver codeunit 50270). El "User ID" estándar es la
        // cuenta de servicio de la app; estas columnas dicen quién lo hizo de verdad.
        //   Boletas    → Encargado (pidió/recibió), Bodega (despachó), Transportista.
        //   Digitación → Digitado por.
        addafter("Document No.")
        {
            field("GJW Origen"; Rec."GJW Origen")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'App que registró el movimiento: Boletas o Digitación.';
            }
            field("GJW Encargado"; Rec."GJW Encargado")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Boletas: encargado que solicitó y recibió el material.';
            }
            field("GJW Bodega"; Rec."GJW Bodega")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Boletas: bodeguero que despachó el material.';
            }
            field("GJW Transportista"; Rec."GJW Transportista")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Boletas: transportista que llevó el material a la obra.';
            }
            field("GJW Digitado Por"; Rec."GJW Digitado Por")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Digitación: persona que digitó la boleta.';
            }
        }
        addafter("Cost Amount (Actual)")
        {
            field(CostoUnitario; CostoUnitario)
            {
                ApplicationArea = All;
                Caption = 'Costo Unitario';
                ToolTip = 'Costo unitario calculado como Importe coste (Real) / Cantidad. Solo se calcula en movimientos de tipo Compra.';
                DecimalPlaces = 2 : 5;
                Editable = false;
                BlankZero = true;
            }
        }
    }

    var
        CostoUnitario: Decimal;

    trigger OnAfterGetRecord()
    begin
        CostoUnitario := 0;
        if Rec."Entry Type" = Rec."Entry Type"::Purchase then begin
            Rec.CalcFields("Cost Amount (Actual)");
            if Rec.Quantity <> 0 then
                CostoUnitario := Rec."Cost Amount (Actual)" / Rec.Quantity;
        end;

    end;
}
