page 50154 "Job Task API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'project';
    APIVersion = 'v1.0';
    Caption = 'Job Task API';
    EntityName = 'jobTask';
    EntitySetName = 'jobTasks';
    SourceTable = "Job Task";

    ODataKeyFields = "Job No.", "Job Task No.";
    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(jobNo; Rec."Job No.") { Caption = 'Project No.'; }
                field(jobTaskNo; Rec."Job Task No.") { Caption = 'Project Task No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(jobTaskType; Rec."Job Task Type") { Caption = 'Task Type'; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code'; }
                field(globalDim1; Rec."Global Dimension 1 Code") { Caption = 'Global Dimension 1'; }
                field(globalDim2; Rec."Global Dimension 2 Code") { Caption = 'Global Dimension 2'; }
                field(startDate; Rec."Start Date") { Caption = 'Start Date'; }
                field(endDate; Rec."End Date") { Caption = 'End Date'; }

                field(systemId; Rec.SystemId)
                {
                    Caption = 'SystemId';
                    ApplicationArea = All;
                }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Caption = 'System Created At'; }
                field(systemCreatedBy; Rec.SystemCreatedBy) { Caption = 'System Created By'; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }
                field(systemModifiedBy; Rec.SystemModifiedBy) { Caption = 'System Modified By'; }
            }
        }
    }
}
