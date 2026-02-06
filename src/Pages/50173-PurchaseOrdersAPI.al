// ════════════════════════════════════════════════════════════════════════════════
// Page 50173 "GJW Purchase Orders API"
// Propósito: API REST para consultar Pedidos de Compra abiertos
// Endpoint: /adelante_purchasing_v1.0_purchaseOrders
// ════════════════════════════════════════════════════════════════════════════════
page 50173 "GJW Purchase Orders API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'purchasing';
    APIVersion = 'v1.0';
    EntityName = 'purchaseOrder';
    EntitySetName = 'purchaseOrders';
    SourceTable = "Purchase Header";
    SourceTableView = where("Document Type" = const(Order));
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    // Solo lectura para consultas, modificación vía endpoint de posting
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
                field(systemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'System Created At';
                    Editable = false;
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                    Editable = false;
                }

                // ═══ Campos principales ═══
                field(documentType; Rec."Document Type")
                {
                    Caption = 'Document Type';
                    Editable = false;
                }
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false;
                }
                field(buyFromVendorNo; Rec."Buy-from Vendor No.")
                {
                    Caption = 'Buy-from Vendor No.';
                    Editable = false;
                }
                field(buyFromVendorName; Rec."Buy-from Vendor Name")
                {
                    Caption = 'Buy-from Vendor Name';
                    Editable = false;
                }
                field(orderDate; Rec."Order Date")
                {
                    Caption = 'Order Date';
                    Editable = false;
                }
                field(documentDate; Rec."Document Date")
                {
                    Caption = 'Document Date';
                    Editable = false;
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                    Editable = false;
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(vendorInvoiceNo; Rec."Vendor Invoice No.")
                {
                    Caption = 'Vendor Invoice No.';
                    Editable = false;
                }
                field(vendorShipmentNo; Rec."Vendor Shipment No.")
                {
                    Caption = 'Vendor Shipment No.';
                    Editable = false;
                }

                // ═══ Importes (FlowFields - requieren CalcFields) ═══
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                    Editable = false;
                }
                field(amountIncludingVAT; Rec."Amount Including VAT")
                {
                    Caption = 'Amount Including VAT';
                    Editable = false;
                }

                // ═══ Campos de ubicación y dimensiones ═══
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

                // ═══ Estado de recepción/facturación ═══
                field(completelyReceived; Rec."Completely Received")
                {
                    Caption = 'Completely Received';
                    Editable = false;
                }
                field(pendingInvoice; Rec.Invoice)
                {
                    Caption = 'Invoice';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        // Calcular FlowFields para mostrar importes
        Rec.CalcFields(Amount, "Amount Including VAT");
    end;
}
