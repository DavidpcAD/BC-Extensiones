// ════════════════════════════════════════════════════════════════════════════════
// Page 50239 "Adelante Posted Rcpt Line API"
// Líneas de recepciones de compra registradas (Purch. Rcpt. Line, tabla 121), para
// asignarles un cargo de producto (flete de un tercero) ya recibido/facturado aparte.
// Filtrable por buyFromVendorNo, no (artículo) y documentNo (Nº recepción).
//   GET api/adelante/purchasing/v1.0/companies({id})/postedReceiptLines
//       ?$filter=documentNo eq 'CR-000003'
// ════════════════════════════════════════════════════════════════════════════════
page 50239 "Adelante Posted Rcpt Line API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'purchasing';
    APIVersion = 'v1.0';
    EntityName = 'postedReceiptLine';
    EntitySetName = 'postedReceiptLines';
    SourceTable = "Purch. Rcpt. Line";
    ODataKeyFields = SystemId;
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
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(documentNo; Rec."Document No.") { Caption = 'Document No.'; }
                field(lineNo; Rec."Line No.") { Caption = 'Line No.'; }
                field(buyFromVendorNo; Rec."Buy-from Vendor No.") { Caption = 'Buy-from Vendor No.'; }
                field(no; Rec."No.") { Caption = 'No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                // Quantity y Direct Unit Cost están en la unidad de la LÍNEA (p.ej. ESTAÑON),
                // no en la base del ítem. Sin estos tres campos no se puede saber en qué
                // unidad se compró ni a cuánto equivale en la unidad base.
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { Caption = 'Unit of Measure Code'; }
                field(qtyPerUnitOfMeasure; Rec."Qty. per Unit of Measure") { Caption = 'Qty. per Unit of Measure'; }
                field(quantityBase; Rec."Quantity (Base)") { Caption = 'Quantity (Base)'; }
                field(directUnitCost; Rec."Direct Unit Cost") { Caption = 'Direct Unit Cost'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'Currency Code'; }
                field(lineAmount; LineAmount) { Caption = 'Line Amount'; }
                field(grossWeight; Rec."Gross Weight") { Caption = 'Gross Weight'; }
                field(unitVolume; Rec."Unit Volume") { Caption = 'Unit Volume'; }
                field(postingDate; Rec."Posting Date") { Caption = 'Posting Date'; }
            }
        }
    }

    var
        LineAmount: Decimal;

    trigger OnAfterGetRecord()
    begin
        LineAmount := Rec.Quantity * Rec."Direct Unit Cost";
    end;
}
