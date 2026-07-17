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
                field(directUnitCost; Rec."Direct Unit Cost") { Caption = 'Direct Unit Cost'; }
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
