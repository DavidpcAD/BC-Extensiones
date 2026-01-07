page 50185 "GJW Item Reclass Batch API"
{
    PageType = API;
    Caption = 'Item Reclass Batch API';
    APIPublisher = 'adelante';
    APIGroup = 'returns';
    APIVersion = 'v1.0';
    EntityName = 'itemReclassBatch';
    EntitySetName = 'itemReclassBatches';
    SourceTable = "Item Journal Batch";
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
        // Set default template for reclassification
        if Rec."Journal Template Name" = '' then
            Rec."Journal Template Name" := 'RECLASIF';
    end;
}
