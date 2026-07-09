pageextension 50139 "Adelante ILE Costo Unitario" extends "Item Ledger Entries"
{
    layout
    {
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
