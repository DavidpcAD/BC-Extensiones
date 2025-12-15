page 50103 "GJW Item Journal Templates API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'itemJournalTemplate';
    EntitySetName = 'itemJournalTemplates';

    SourceTable = "Item Journal Template"; // 82
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    // Normalmente estas se mantienen de solo lectura; habilito CRUD por si las necesitas
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // --- System fields ---
                field(systemId; Rec.SystemId) { Caption = 'System Id'; }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Caption = 'System Created At'; }
                field(systemCreatedBy; Rec.SystemCreatedBy) { Caption = 'System Created By'; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }
                field(systemModifiedBy; Rec.SystemModifiedBy) { Caption = 'System Modified By'; }

                // --- Campos tabla 82 ---
                field(name; Rec.Name) { ApplicationArea = All; }
                field(description; Rec.Description) { ApplicationArea = All; }
                field(testReportId; Rec."Test Report ID") { ApplicationArea = All; }
                field(pageId; Rec."Page ID") { ApplicationArea = All; }
                field(postingReportId; Rec."Posting Report ID") { ApplicationArea = All; }
                field(forcePostingReport; Rec."Force Posting Report") { ApplicationArea = All; }
                field(type; Rec.Type) { ApplicationArea = All; }
                field(sourceCode; Rec."Source Code") { ApplicationArea = All; }
                field(reasonCode; Rec."Reason Code") { ApplicationArea = All; }
                field(recurring; Rec.Recurring) { ApplicationArea = All; }

                // FlowFields (solo lectura)
                field(testReportCaption; Rec."Test Report Caption")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(pageCaption; Rec."Page Caption")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(postingReportCaption; Rec."Posting Report Caption")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(noSeries; Rec."No. Series") { ApplicationArea = All; }
                field(postingNoSeries; Rec."Posting No. Series") { ApplicationArea = All; }
                field(whseRegisterReportId; Rec."Whse. Register Report ID") { ApplicationArea = All; }

                // FlowField
                field(whseRegisterReportCaption; Rec."Whse. Register Report Caption")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(incrementBatchName; Rec."Increment Batch Name") { ApplicationArea = All; }
            }
        }
    }
}
