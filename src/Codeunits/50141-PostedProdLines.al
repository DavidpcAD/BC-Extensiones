page 50141 "GJW Posted Work Prod Lines"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';

    EntityName = 'postedWorkProductionLine';       // singular, sin espacios
    EntitySetName = 'postedWorkProductionLines';      // plural, sin espacios

    SourceTable = "GomJob Posted Works Prod. Line"; // 70720583
    ODataKeyFields = SystemId;                         // clave única OData
    DelayedInsert = true;

    // CRUD (ajusta si quieres solo lectura)
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                // --- Sistema ---
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Caption = 'System Created At'; }
                field(systemCreatedBy; Rec.SystemCreatedBy) { Caption = 'System Created By'; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }
                field(systemModifiedBy; Rec.SystemModifiedBy) { Caption = 'System Modified By'; }

                // --- 1:1 con la tabla 70720583 ---
                field(worksNo; Rec."Works No.") { Caption = 'Work No.'; }
                field(versionNo; Rec."Version No.") { Caption = 'Version No.'; }
                field(postingDate; Rec."Posting Date") { Caption = 'Posting Date'; }
                field(codeOrder; Rec."Code Order") { Caption = 'Sorting Code'; }
                field(taskType; Rec."Task Type") { Caption = 'Task Type'; }
                field(taskNo; Rec."Task No.") { Caption = 'Task No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(unitAmount; Rec."Unit Amount") { Caption = 'Unit Amount'; }
                field(lineAmount; Rec."Line Amount") { Caption = 'Line Amount'; }
                field(unitOfMeasure; Rec."Unit of Measure") { Caption = 'Unit of Measure'; }
                field(importDateTime; Rec."Import Date Time") { Caption = 'Import Date Time'; }
                field(jobNo; Rec."Job No.") { Caption = 'Job No.'; }
                field(outstandingAmount; Rec."Outstanding Amount") { Caption = 'Outstanding Amount'; }
                field(outstandingQuantity; Rec."Outstanding Quantity") { Caption = 'Outstanding Quantity'; }
                field(registeredAmount; Rec."Registered Amount") { Caption = 'Posted Amount'; }
                field(registeredQuantity; Rec."Registered Quantity") { Caption = 'Posted Quantity'; }
                field(versionFilter; Rec."Version Filter") { Caption = 'Version Filter'; }
                field(accumulatedLineAmount; Rec."Accumulated Line Amount") { Caption = 'Accumulated Line Amount'; }
            }
        }
    }
}
