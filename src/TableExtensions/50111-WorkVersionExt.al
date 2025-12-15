page 50111 "GJW Works Version"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';

    EntityName = 'workVersion';       // singular
    EntitySetName = 'workVersions';   // plural

    SourceTable = "GomJob Works Version"; // 70720582
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    // CRUD
    InsertAllowed = true;
    ModifyAllowed = true;      // ponlo en false si NO quieres permitir cambios
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                // --- Campos de sistema (útiles para trazabilidad)
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Caption = 'System Created At'; Editable = false; }
                field(systemCreatedBy; Rec.SystemCreatedBy) { Caption = 'System Created By'; Editable = false; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; Editable = false; }
                field(systemModifiedBy; Rec.SystemModifiedBy) { Caption = 'System Modified By'; Editable = false; }

                // --- TODAS las columnas de la tabla 70720582 ---
                field(worksNo; Rec."Works No.") { Caption = 'Work No.'; }
                field(versionCode; Rec."Version Code") { Caption = 'Version Code'; }
                field(createDateTime; Rec."Create Date Time") { Caption = 'Creation Date Time'; }
                field(quantityLines; Rec."Quantity Lines") { Caption = 'Count of Lines'; }
                field(reStudy; Rec."Re-Study") { Caption = 'Re-Study or Basic'; }
            }
        }
    }
}
