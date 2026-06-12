// ════════════════════════════════════════════════════════════════════════════════
// Page 50177 "GJW Purchase Quote Lines API"
// Propósito: API REST para consultar líneas de Ofertas de Compra (Purchase Quotes)
// Endpoint: /adelante_purchasing_v1.0_purchaseQuoteLines
// Uso: filtrar por documentNo para traer las líneas de una oferta seleccionada
//      ej: ?$filter=documentNo eq 'CCT-000864'
// ════════════════════════════════════════════════════════════════════════════════
page 50177 "GJW Purchase Quote Lines API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'purchasing';
    APIVersion = 'v1.0';
    EntityName = 'purchaseQuoteLine';
    EntitySetName = 'purchaseQuoteLines';
    SourceTable = "Purchase Line";
    SourceTableView = where("Document Type" = const(Quote));
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    // Solo lectura
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // ═══ Campos de sistema ═══
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }

                // ═══ Campos de relación con el documento ═══
                field(documentType; Rec."Document Type")
                {
                    Caption = 'Document Type';
                    Editable = false;
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    Editable = false;
                }

                // ═══ Campos del producto/servicio ═══
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                    Editable = false;
                }
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';
                    Editable = false;
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                    Editable = false;
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                    Editable = false;
                }

                // ═══ Cantidades ═══
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                    Editable = false;
                }
                field(outstandingQuantity; Rec."Outstanding Quantity")
                {
                    Caption = 'Outstanding Quantity';
                    Editable = false;
                }

                // ═══ Precios y costos ═══
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                    Editable = false;
                }
                field(unitCostLCY; Rec."Unit Cost (LCY)")
                {
                    Caption = 'Unit Cost (LCY)';
                    Editable = false;
                }
                field(lineDiscountPercent; Rec."Line Discount %")
                {
                    Caption = 'Line Discount %';
                    Editable = false;
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Line Amount';
                    Editable = false;
                }
                field(amountIncludingVAT; Rec."Amount Including VAT")
                {
                    Caption = 'Amount Including VAT';
                    Editable = false;
                }

                // ═══ IVA ═══
                field(vatPercent; Rec."VAT %")
                {
                    Caption = 'VAT %';
                    Editable = false;
                }
                field(vatBaseAmount; Rec."VAT Base Amount")
                {
                    Caption = 'VAT Base Amount';
                    Editable = false;
                }

                // ═══ Ubicación y dimensiones ═══
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                    Editable = false;
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                    Editable = false;
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                    Editable = false;
                }

                // ═══ Fechas ═══
                field(expectedReceiptDate; Rec."Expected Receipt Date")
                {
                    Caption = 'Expected Receipt Date';
                    Editable = false;
                }
            }
        }
    }
}
