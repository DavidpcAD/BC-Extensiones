// ════════════════════════════════════════════════════════════════════════════════
// Page 50175 "GJW Post Purchase Order API"
// Propósito: API Singleton para Vista Previa y Registro (Receive + Invoice) de
//            Pedidos de Compra.
// Endpoint: /adelante_purchasing_v1.0_postPurchaseOrders
//
// El campo requestJSON acepta un campo "action":
//   - "preview"        -> devuelve los asientos que se generarían + previewToken (no graba)
//   - "post" u omitido -> registra. Enviar "previewToken" para confirmar que el
//                         documento no cambió desde la vista previa.
//
// Ejemplo requestJSON (preview):
//   {"action":"preview","purchaseOrderNo":"CP-000515","vendorInvoiceNo":"5706",
//    "documentDate":"2025-12-04","postingDate":"2025-12-04",
//    "lines":[{"lineSystemId":"<guid>","qtyToReceive":1}]}
// Ejemplo requestJSON (post tras preview):
//   {"action":"post","purchaseOrderNo":"CP-000515","vendorInvoiceNo":"5706",
//    "documentDate":"2025-12-04","postingDate":"2025-12-04","previewToken":"123-456",
//    "lines":[{"lineSystemId":"<guid>","qtyToReceive":1}]}
// ════════════════════════════════════════════════════════════════════════════════
page 50175 "GJW Post Purchase Order API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'purchasing';
    APIVersion = 'v1.0';
    EntityName = 'postPurchaseOrder';
    EntitySetName = 'postPurchaseOrders';
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = ID;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // ═══ Campo ID (clave primaria del singleton) ═══
                field(id; Rec.ID)
                {
                    Caption = 'Id';
                }

                // ═══ Campo para recibir el JSON con los datos del pedido ═══
                field(requestJSON; RequestJSON)
                {
                    Caption = 'Request JSON';
                }

                // ═══ Campo trigger para ejecutar el posting ═══
                field(execute; Execute)
                {
                    Caption = 'Execute';

                    trigger OnValidate()
                    begin
                        if Execute then
                            ProcessPosting();
                    end;
                }

                // ═══ Campo de respuesta (solo lectura) ═══
                field(responseJSON; ResponseJSON)
                {
                    Caption = 'Response JSON';
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.ID := 1;
        Rec.Name := 'PostPurchaseOrder';
        Rec.Insert();
    end;

    local procedure ProcessPosting()
    var
        PurchPostProc: Codeunit "GJW Purchase Post Processor";
    begin
        if RequestJSON = '' then begin
            ResponseJSON := '{"posted":false,"error":"RequestJSON is empty"}';
            exit;
        end;

        // Enruta a preview o post según el campo "action" del JSON.
        ResponseJSON := PurchPostProc.Process(RequestJSON);
    end;

    var
        RequestJSON: Text;
        Execute: Boolean;
        ResponseJSON: Text;
}
