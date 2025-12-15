page 50160 "Job Journal Template API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'project';
    APIVersion = 'v1.0';
    Caption = 'Job Journal Template API';
    SourceTable = "Job Journal Template";
    EntityName = 'jobJournalTemplate';
    EntitySetName = 'jobJournalTemplates';
    ODataKeyFields = "SystemId";
    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    Permissions =
        tabledata "Job Journal Template" = RIMD;

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

                field(name; Rec.Name)
                {
                    Caption = 'Name';
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

                field(postinNoSeries; Rec."Posting No. Series")
                {
                    Caption = 'Posting No. Series';
                    ApplicationArea = All;
                }

                field(sourceCode; Rec."Source Code")
                {
                    Caption = 'Source Code';
                    ApplicationArea = All;
                }

                field(reasonCode; Rec."Reason Code")
                {
                    Caption = 'Reason Code';
                    ApplicationArea = All;
                }

                field(Recurring; Rec.Recurring)
                {
                    Caption = 'Recurring';
                    ApplicationArea = All;
                }
            }
        }
    }
}
