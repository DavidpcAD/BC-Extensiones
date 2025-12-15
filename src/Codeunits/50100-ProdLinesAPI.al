page 50100 "GJW Production Lines API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'productionLine';
    EntitySetName = 'productionLines';

    SourceTable = "GomJob Works Production Line"; // 70720578
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    // Habilitado CRUD
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // --- System fields útiles en apps ---
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Caption = 'System Created At'; }
                field(systemCreatedBy; Rec.SystemCreatedBy) { Caption = 'System Created By'; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }
                field(systemModifiedBy; Rec.SystemModifiedBy) { Caption = 'System Modified By'; }

                // --- Campos 1:1 con la tabla 70720578 ---
                field(worksNo; Rec."Works No.") { Caption = 'Work No.'; }
                field(codeOrder; Rec."Code Order") { Caption = 'Sorting Code'; }
                field(taskType; Rec."Task Type") { Caption = 'Task Type'; }
                field(taskNo; Rec."Task No.") { Caption = 'Task No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(unitAmount; Rec."Unit Amount") { Caption = 'Unit Price'; }          // <- igual que tabla
                field(lineAmount; Rec."Line Amount") { Caption = 'Line Amount'; }
                field(unitOfMeasure; Rec."Unit of Measure") { Caption = 'Unit of Measure'; }
                field(importDateTime; Rec."Import Date Time") { Caption = 'Import Date Time'; }
                field(jobNo; Rec."Job No.") { Caption = 'Job No.'; }
                field(outstandingAmount; Rec."Outstanding Amount") { Caption = 'Outstanding Amount'; }
                field(outstandingQuantity; Rec."Outstanding Quantity") { Caption = 'Outstanding Quantity'; }
                field(registeredAmount; Rec."Registered Amount") { Caption = 'Posted Amount'; }       // <- igual que tabla
                field(registeredQuantity; Rec."Registered Quantity") { Caption = 'Posted Quantity'; }  // <- igual que tabla
                field(prestoTaskNo; Rec."Presto Task No.") { Caption = 'Presto Task No.'; }
                field(maximumQuantity; Rec."Maximum Quantity") { Caption = 'Maximum Quantity'; }
            }
        }
    }
}
