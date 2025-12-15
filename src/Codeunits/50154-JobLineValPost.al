codeunit 50154 "GJW Job Journal Line ValPost"
{
    [EventSubscriber(ObjectType::Page, Page::"Adelante Job Journal Line API", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnAfterInsertJobJournalLine(var Rec: Record "Job Journal Line")
    begin
        exit; // 🔥 Desactivado completamente
    end;
}
