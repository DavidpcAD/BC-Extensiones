page 50161 "Job Journal Batch API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'project';
    APIVersion = 'v1.0';
    Caption = 'Job Journal Batch API';
    SourceTable = "Job Journal Batch";
    EntityName = 'jobJournalBatch';
    EntitySetName = 'jobJournalBatches';
    ODataKeyFields = "SystemId";
    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    Permissions =
        tabledata "Job Journal Batch" = RIMD,
        tabledata "Job Journal Template" = R;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'SystemId';
                    ApplicationArea = All;
                }

                field(journalTemplateName; Rec."Journal Template Name")
                {
                    Caption = 'Journal Template Name';
                    ApplicationArea = All;
                }

                field(name; Rec.Name)
                {
                    Caption = 'Batch Name';
                    ApplicationArea = All;
                }

                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    ApplicationArea = All;
                }

                field(noSeries; Rec."No. Series")
                {
                    Caption = 'No. Series';
                    ApplicationArea = All;
                }

                field(postingNoSeries; Rec."Posting No. Series")
                {
                    Caption = 'Posting No. Series';
                    ApplicationArea = All;
                }

                field(reasonCode; Rec."Reason Code")
                {
                    Caption = 'Reason Code';
                    ApplicationArea = All;
                }

                field(recurring; Rec.Recurring)
                {
                    Caption = 'Recurring';
                    ApplicationArea = All;
                }

                field(idColaborador; Rec."ADL ID Colaborador")
                {
                    Caption = 'ID Colaborador';
                    ApplicationArea = All;
                }
            }

        }
    }
}
