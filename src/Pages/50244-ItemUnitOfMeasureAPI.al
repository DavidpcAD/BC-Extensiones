// ════════════════════════════════════════════════════════════════════════════════
// Page 50244 "Adelante Item UoM API"
// Propósito: Las unidades de medida de cada ítem con su FACTOR de conversión a la
//            unidad base. Un mismo material se consume en una unidad y se compra en
//            otra: el adhesivo M06-0009 tiene base GR (la fórmula lo usa en gramos)
//            pero se compra por ESTAÑON, y 1 ESTAÑON son 255.000 GR.
//            Sin este factor la app no puede pasar un precio por gramo a precio por
//            estañón, y termina cotizando 255.000 veces más barato.
// Endpoint : /api/adelante/inventory/v1.0/companies(<id>)/itemUnitsOfMeasure
// Uso      : ?$filter=itemNo eq 'M06-0009'
//            qtyPerUnitOfMeasure = cuántas unidades BASE trae una unidad de estas.
// ════════════════════════════════════════════════════════════════════════════════
page 50244 "Adelante Item UoM API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'itemUnitOfMeasure';
    EntitySetName = 'itemUnitsOfMeasure';
    SourceTable = "Item Unit of Measure";
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;

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
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                    Editable = false;
                }
                field(code; Rec.Code)
                {
                    Caption = 'Code';
                    Editable = false;
                }
                field(qtyPerUnitOfMeasure; Rec."Qty. per Unit of Measure")
                {
                    Caption = 'Qty. per Unit of Measure';
                    Editable = false;
                }
            }
        }
    }
}
