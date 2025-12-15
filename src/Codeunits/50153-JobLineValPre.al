codeunit 50153 "GJW Job Journal Line ValPre"
{
    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertJobJournalLine(var Rec: Record "Job Journal Line"; RunTrigger: Boolean)
    begin
        exit; // 🔥 Desactivado completamente
    end;
}
