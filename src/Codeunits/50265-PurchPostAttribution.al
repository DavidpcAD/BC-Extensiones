// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50265 "GJW Purch Post Attribution"
// Copia la atribución humana de la app de proveeduría (quién creó el pedido / quién
// registra) desde el Purchase Header hacia los documentos REGISTRADOS, en el momento del
// registro. Así la info queda guardada aunque el pedido se borre al facturarse por completo.
//
//   - "GJW Pedido Creado Por" : lo estampó AdelantePO_SetPedidoCreadoPor al crear el pedido.
//   - "GJW Realizado Por"     : lo estampó AdelantePO_SetRealizadoPor antes de registrar.
//
// Si vienen vacíos (pedido hecho a mano en BC, o app vieja) no se toca nada: mejor vacío
// que inventado. Nombres de parámetros calcados de los eventos de codeunit 90 "Purch.-Post"
// (incluido PurchaseHeader vs PurchHeader, y CommitIsSupressed con esa grafía).
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50265 "GJW Purch Post Attribution"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchInvHeaderInsert', '', false, false)]
    local procedure StampInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header")
    begin
        PurchInvHeader."GJW Realizado Por" := PurchHeader."GJW Realizado Por";
        PurchInvHeader."GJW Pedido Creado Por" := PurchHeader."GJW Pedido Creado Por";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchRcptHeaderInsert', '', false, false)]
    local procedure StampReceiptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchaseHeader: Record "Purchase Header")
    begin
        PurchRcptHeader."GJW Realizado Por" := PurchaseHeader."GJW Realizado Por";
        PurchRcptHeader."GJW Pedido Creado Por" := PurchaseHeader."GJW Pedido Creado Por";
    end;
}
