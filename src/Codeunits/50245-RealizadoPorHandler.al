// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50245 "GJW Realizado Por Handler"
// Copia el username del login de la app ("GJW Realizado Por") desde la Job Journal Line
// hacia el Job Ledger Entry en el momento en que BC lo crea.
//
// Es el choke point UNIVERSAL: todo Job Ledger Entry se crea desde una Job Journal Line
// vía codeunit 1012 "Job Jnl.-Post Line", que dispara OnBeforeJobLedgEntryInsert con
// (var JobLedgerEntry; JobJournalLine). Con esto, cualquier endpoint que estampe el campo
// en la Job Journal Line antes de postear lo verá reflejado en Job Ledger Entries (pág. 92),
// sin tocar el "User ID" estándar (que sigue siendo la cuenta de servicio, DIGITACION-APP).
//
// Falta un eslabón cuando el consumo NO viene de un diario, sino de una FACTURA DE COMPRA
// con obra/tarea en la línea (consumo directo: lo que la app de Compras registra al recibir).
// Ahí la Job Journal Line no la arma nadie de este lado: la construye BC dentro de
// codeunit 1002 "Job Post-Line".PostJobOnPurchaseLine a partir de la línea del pedido, así
// que no hay dónde estampar el nombre antes. Por eso el segundo subscriber: el pedido de
// compra CARGA el dato (campo "GJW Realizado Por" del Purchase Header, que estampa
// AdelantePO_SetRealizadoPor antes de registrar) y acá se pasa a la Job Journal Line recién
// armada, justo antes de que se postee. El primer subscriber hace el resto del viaje.
// Sin esto, los Movs. proyecto de una factura de compra salían con "Realizado por" vacío
// (caso real: CFR-009900 del 01/09/2026, obra INF-HDAII).
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50245 "GJW Realizado Por Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", 'OnBeforeJobLedgEntryInsert', '', false, false)]
    local procedure CopyRealizadoPorToJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."GJW Realizado Por" := JobJournalLine."GJW Realizado Por";
    end;

    // Consumo directo de una FACTURA DE COMPRA: la Job Journal Line ya viene armada de la
    // línea del pedido (JobTransferLine.FromPurchaseLineToJnlLine) y todavía no se posteó.
    // El nombre lo trae el encabezado del pedido. Si viene vacío (pedido registrado a mano
    // en BC, o app vieja que no lo estampa) no se toca nada: mejor vacío que inventado.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Post-Line", 'OnPostJobOnPurchaseLineOnAfterJobTransferLineFromPurchaseLineToJnlLine', '', false, false)]
    local procedure CopyRealizadoPorFromPurchaseHeader(var PurchHeader: Record "Purchase Header"; var JobJnlLine: Record "Job Journal Line")
    begin
        if PurchHeader."GJW Realizado Por" <> '' then
            JobJnlLine."GJW Realizado Por" := PurchHeader."GJW Realizado Por";
    end;
}
