page 50183 "GJW Job Journal Batch API"
{
    PageType = API;
    Caption = 'Job Journal Batches API';
    APIPublisher = 'adelante';
    APIGroup = 'returns';
    APIVersion = 'v1.0';
    EntityName = 'jobJournalBatch';
    EntitySetName = 'jobJournalBatches';
    SourceTable = "Job Journal Batch";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(journalTemplateName; Rec."Journal Template Name")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Template Name';
                }
                field(name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field(reasonCode; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Reason Code';
                }
                field(noSeries; Rec."No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'No. Series';
                }
                field(postingNoSeries; Rec."Posting No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No. Series';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // Set default template for returns
        if Rec."Journal Template Name" = '' then
            Rec."Journal Template Name" := 'PROJECT';
    end;
}
