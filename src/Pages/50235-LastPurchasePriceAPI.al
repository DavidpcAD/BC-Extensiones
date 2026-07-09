// ════════════════════════════════════════════════════════════════════════════════
// Page 50235 "Adelante Last Purch Price API"
// Propósito: Devuelve el costo unitario de los movimientos de tipo Compra por ítem.
//            Pensado para que la app de Órdenes de Compra obtenga el ÚLTIMO precio
//            de compra de un material.
// Endpoint : /api/adelante/purchasing/v1.0/companies(<id>)/lastPurchasePrices
// Uso      : filtrar por ítem y pedir el más reciente:
//   ?$filter=itemNo eq 'M01-0001'&$orderby=postingDate desc,entryNo desc&$top=1
// unitCost = Cost Amount (Actual) / Quantity  (solo movimientos de tipo Compra)
// ════════════════════════════════════════════════════════════════════════════════
page 50235 "Adelante Last Purch Price API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'purchasing';
    APIVersion = 'v1.0';
    EntityName = 'lastPurchasePrice';
    EntitySetName = 'lastPurchasePrices';
    SourceTable = "Item Ledger Entry";
    SourceTableView = where("Entry Type" = const(Purchase), Quantity = filter(> 0));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    Editable = false;
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                    Editable = false;
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                    Editable = false;
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                    Editable = false;
                }
                field(vendorNo; Rec."Source No.")
                {
                    Caption = 'Vendor No.';
                    Editable = false;
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                    Editable = false;
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                    Editable = false;
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                    Editable = false;
                }
                field(costAmountActual; Rec."Cost Amount (Actual)")
                {
                    Caption = 'Cost Amount (Actual)';
                    Editable = false;
                }
                field(unitCost; UnitCost)
                {
                    Caption = 'Unit Cost';
                    Editable = false;
                }
            }
        }
    }

    var
        UnitCost: Decimal;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Cost Amount (Actual)");
        UnitCost := 0;
        if Rec.Quantity <> 0 then
            UnitCost := Rec."Cost Amount (Actual)" / Rec.Quantity;
    end;
}
