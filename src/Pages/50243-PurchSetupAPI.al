// ════════════════════════════════════════════════════════════════════════════════
// Page 50243 "Adelante Purch Setup API"
// Propósito: Dice QUÉ serie de numeración usa cada documento de compras, según la
//            Configuración de Compras de BC. Así la app no tiene que traer el
//            código de la serie escrito a mano: lo pregunta.
// Endpoint : /api/adelante/purchasing/v1.0/companies(<id>)/purchasesSetups
// Uso      : una sola fila por empresa.
//   1) GET purchasesSetups            -> orderNos = 'P-ORD' (por ejemplo)
//   2) GET noSeriesLines?$filter=seriesCode eq 'P-ORD'  (page 50242) -> lastNoUsed
// ════════════════════════════════════════════════════════════════════════════════
page 50243 "Adelante Purch Setup API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'purchasing';
    APIVersion = 'v1.0';
    EntityName = 'purchasesSetup';
    EntitySetName = 'purchasesSetups';
    SourceTable = "Purchases & Payables Setup";
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
                field(quoteNos; Rec."Quote Nos.")
                {
                    Caption = 'Quote Nos.';
                    Editable = false;
                }
                field(orderNos; Rec."Order Nos.")
                {
                    Caption = 'Order Nos.';
                    Editable = false;
                }
                field(invoiceNos; Rec."Invoice Nos.")
                {
                    Caption = 'Invoice Nos.';
                    Editable = false;
                }
                field(postedInvoiceNos; Rec."Posted Invoice Nos.")
                {
                    Caption = 'Posted Invoice Nos.';
                    Editable = false;
                }
                field(creditMemoNos; Rec."Credit Memo Nos.")
                {
                    Caption = 'Credit Memo Nos.';
                    Editable = false;
                }
                field(postedCreditMemoNos; Rec."Posted Credit Memo Nos.")
                {
                    Caption = 'Posted Credit Memo Nos.';
                    Editable = false;
                }
                field(postedReceiptNos; Rec."Posted Receipt Nos.")
                {
                    Caption = 'Posted Receipt Nos.';
                    Editable = false;
                }
            }
        }
    }
}
