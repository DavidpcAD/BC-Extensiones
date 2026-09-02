// ════════════════════════════════════════════════════════════════════════════════
// Page 50247 "Adelante Posted Inv Line API"
// Líneas de FACTURAS DE COMPRA REGISTRADAS (Purch. Inv. Line, tabla 123).
//
// Para qué: cuando una orden se recibe y factura por completo, BC BORRA el pedido de
// compra. A partir de ahí no hay contra qué cotejar la orden de la app… salvo esto.
// Es la única forma de mirar hacia atrás y contestar "¿lo que la app dice que compró
// es lo que BC registró?".
//
// Caso que la motivó (2/09/2026): la orden CP-005172 tenía 7 líneas y la factura
// registrada CFR-009599 tenía 6. Faltaban ₡22.820 + IVA de tornillos que el proveedor
// facturó, que entraron a la bodega y que el inventario de BC nunca vio. La app decía
// "recibido 100%".
//
// El campo CLAVE es `orderNo` ("Order No."): es lo que permite ir de una orden de la
// app a lo que BC registró sin depender de que la app haya guardado el N.º del
// documento. Sin él, las facturas viejas quedan fuera de toda verificación.
//
//   GET api/adelante/purchasing/v1.0/companies({id})/postedInvoiceLines
//       ?$filter=orderNo eq 'CP-005172'
// ════════════════════════════════════════════════════════════════════════════════
page 50247 "Adelante Posted Inv Line API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'purchasing';
    APIVersion = 'v1.0';
    EntityName = 'postedInvoiceLine';
    EntitySetName = 'postedInvoiceLines';
    SourceTable = "Purch. Inv. Line";
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
                // El pedido de origen: la llave para cotejar contra la orden de la app.
                field(orderNo; Rec."Order No.") { Caption = 'Order No.'; }
                field(orderLineNo; Rec."Order Line No.") { Caption = 'Order Line No.'; }
                field(buyFromVendorNo; Rec."Buy-from Vendor No.") { Caption = 'Buy-from Vendor No.'; }
                field(type; Rec.Type) { Caption = 'Type'; }
                field(no; Rec."No.") { Caption = 'No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(variantCode; Rec."Variant Code") { Caption = 'Variant Code'; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code'; }
                // Cantidad y precio van en la unidad de la LÍNEA (puede no ser la base
                // del artículo): sin la unidad, el número no significa nada.
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { Caption = 'Unit of Measure Code'; }
                field(qtyPerUnitOfMeasure; Rec."Qty. per Unit of Measure") { Caption = 'Qty. per Unit of Measure'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(directUnitCost; Rec."Direct Unit Cost") { Caption = 'Direct Unit Cost'; }
                field(lineAmount; Rec."Line Amount") { Caption = 'Line Amount'; }
                field(lineDiscountPct; Rec."Line Discount %") { Caption = 'Line Discount %'; }
                field(currencyCode; CurrencyCode) { Caption = 'Currency Code'; }
                field(jobNo; Rec."Job No.") { Caption = 'Job No.'; }
                field(postingDate; Rec."Posting Date") { Caption = 'Posting Date'; }
            }
        }
    }

    var
        CurrencyCode: Code[10];

    trigger OnAfterGetRecord()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // La moneda vive en el encabezado; sin ella un importe en dólares se leería
        // como colones y la conciliación diría que falta plata donde no falta.
        CurrencyCode := '';
        if PurchInvHeader.Get(Rec."Document No.") then
            CurrencyCode := PurchInvHeader."Currency Code";
    end;
}
