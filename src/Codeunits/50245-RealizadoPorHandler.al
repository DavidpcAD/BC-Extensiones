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
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50245 "GJW Realizado Por Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", 'OnBeforeJobLedgEntryInsert', '', false, false)]
    local procedure CopyRealizadoPorToJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."GJW Realizado Por" := JobJournalLine."GJW Realizado Por";
    end;
}
