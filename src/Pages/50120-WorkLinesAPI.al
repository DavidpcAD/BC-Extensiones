page 50120 "GJWWorkLines"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';

    EntityName = 'workLine';       // singular
    EntitySetName = 'workLines';      // plural

    SourceTable = "GomJob Works Line";   // 70720577
    ODataKeyFields = SystemId;            // clave única para OData
    DelayedInsert = true;

    // CRUD habilitado (ajusta si quieres restringir)
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                // --- Campos de sistema útiles (opcional pero recomendado)
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Caption = 'System Created At'; }
                field(systemCreatedBy; Rec.SystemCreatedBy) { Caption = 'System Created By'; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }
                field(systemModifiedBy; Rec.SystemModifiedBy) { Caption = 'System Modified By'; }

                // --- TODAS las columnas de la tabla 70720577 ---
                field(worksNo; Rec."Works No.") { Caption = 'Work No.'; }
                field(lineType; Rec."Line Type") { Caption = 'Line Type'; }
                field(versionCode; Rec."Version Code") { Caption = 'Version Code'; }
                field(jobNo; Rec."Job No.") { Caption = 'Job No.'; }
                field(codeOrder; Rec."Code Order") { Caption = 'Sorting Code'; }
                field(idEncargado; Rec."ID Encargado") { Caption = 'ID Encargado'; ObsoleteState = Pending; }
                field(idEncargadoText; Rec."ID Encargado Text") { Caption = 'ID Encargado'; }

                field(taskType; Rec."Task Type") { Caption = 'Task Type'; }
                field(taskNo; Rec."Task No.") { Caption = 'Task No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(unitAmount; Rec."Unit Amount") { Caption = 'Unit Amount'; }
                field(lineAmount; Rec."Line Amount") { Caption = 'Line Amount'; }
                field(purchQuantity; Rec."Purch. Quantity") { Caption = 'Purch. Quantity'; }
                field(purchAmount; Rec."Purch. Amount") { Caption = 'Purch. Amount'; }
                field(unitOfMeasure; Rec."Unit of Measure") { Caption = 'Unit of Measure'; }
                field(reStudy; Rec."Re-Study") { Caption = 'Re-Study or Basic'; }
                field(prestoTaskNo; Rec."Presto Task No.") { Caption = 'Presto Task No.'; }
                field(lineNo; Rec."Line No.") { Caption = 'Line No.'; }
                field(quantityToProduce; Rec."Quantity to Produce") { Caption = 'Quantity to Produce'; }
                field(longDescription; Rec."Long Description") { Caption = 'Long Description'; }
                field(IDVisibles; Rec."IDVisibles") { Caption = 'IDVisibles'; }
            }
        }
    }
}
