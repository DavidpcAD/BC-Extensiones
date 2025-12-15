page 50140 "GJW Posted Prod Buffer"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';

    EntityName = 'postedProductionBuffer';       // singular, sin espacios
    EntitySetName = 'postedProductionBuffers';   // plural, sin espacios

    SourceTable = "GomJob Posted Prod. Buffer";  // 70720586
    ODataKeyFields = SystemId;                   // clave única para OData
    DelayedInsert = true;

    // Habilitar CRUD (ajústalo si quieres solo lectura)
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                // --- Campos de sistema (útiles para integraciones) ---
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Caption = 'System Created At'; }
                field(systemCreatedBy; Rec.SystemCreatedBy) { Caption = 'System Created By'; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }
                field(systemModifiedBy; Rec.SystemModifiedBy) { Caption = 'System Modified By'; }

                // --- Campos 1:1 con la tabla 70720586 ---
                field(worksNo; Rec."Works No.") { Caption = 'Work No.'; }
                field(jobNo; Rec."Job No.") { Caption = 'Job No.'; }
                field(codeOrder; Rec."Code Order") { Caption = 'Sorting Code'; }
                field(taskType; Rec."Task Type") { Caption = 'Task Type'; }
                field(taskNo; Rec."Task No.") { Caption = 'Task No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(month; Rec.Month) { Caption = 'Month'; }
                field(origin; Rec.Origin) { Caption = 'Origin'; }
                field(contracts; Rec.Contracts) { Caption = 'Contracts'; }
                field(monthPcntProduction; Rec."Month Pcnt. (Production)") { Caption = 'Month % (reg./production)'; }
                field(originPcntProduction; Rec."Origin Pcnt. (Production)") { Caption = 'Origin % (reg./production)'; }
                field(contractsPcntProduction; Rec."Contracts Pcnt. (Production)") { Caption = 'Contracts % (reg./production)'; }
            }
        }
    }
}
