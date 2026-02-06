page 50130 "GJW Decomposed Lines API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';

    EntityName = 'decomposedLine';
    EntitySetName = 'decomposedLines';

    SourceTable = "GomJob Works Decomposed Lines";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    // CRUD habilitado
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                // Identificación
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(worksNo; Rec."Works No.") { Caption = 'Work No.'; }
                field(lineNo; Rec."Line No.") { Caption = 'Line No.'; }
                field(taskNo; Rec."Task No.") { Caption = 'Task No.'; }
                field(codeOrder; Rec."Code Order") { Caption = 'Sorting Code'; }
                field(idEncargado; Rec."ID Encargado") { Caption = 'ID Encargado'; ObsoleteState = Pending; }
                field(idEncargadoText; Rec."ID Encargado Text") { Caption = 'ID Encargado'; }

                // Info de origen
                field(sourceCode; Rec."Source Code") { Caption = 'Source Code'; }
                field(originCode; Rec."Origin Code") { Caption = 'Origin Code'; }

                // Descripción y cantidades
                field(description; Rec.Description) { Caption = 'Description'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(unitAmount; Rec."Unit Amount") { Caption = 'Unit Amount'; }
                field(lineAmount; Rec."Line Amount") { Caption = 'Line Amount'; }
                field(unitCost; Rec."Unit Cost") { Caption = 'Unit Cost'; }
                field(performance; Rec.Performance) { Caption = 'Performance'; }

                // Clasificación
                field(taskType; Rec."Task Type") { Caption = 'Task Type'; }
                field(type; Rec.Type) { Caption = 'Type'; }
                field(no; Rec."No.") { Caption = 'No.'; }
                field(prestoTaskNo; Rec."Presto Task No.") { Caption = 'Presto Task No.'; }
                field(variantCode; Rec."Variant Code") { Caption = 'Variant Code'; }
                field(unitOfMeasure; Rec."Unit of Measure") { Caption = 'Unit of Measure'; }

                // Fechas y estado
                field(expectedDate; Rec."Expected Date") { Caption = 'Expected Date'; }
                field(importDateTime; Rec."Import Date Time") { Caption = 'Import Date Time'; }
                field(isPosted; Rec."Is Posted") { Caption = 'Is Posted'; }
                field(postedDateTime; Rec."Posted Date Time") { Caption = 'Posted Date Time'; }
                field(postedUser; Rec."Posted User") { Caption = 'Posted User'; }
            }

            // --- Campos de solo lectura (como pie de página) ---
            field(expectedTaskLineAmount; WorksLine."Line Amount")
            {
                Caption = 'Expected Line Amount';
                Editable = false;
            }
            field(totalLineAmount; TotalLineAmount)
            {
                Caption = 'Decomposed Total Cost Amount';
                Editable = false;
            }
        }
    }

    var
        WorksLine: Record "GomJob Works Line";
        TotalLineAmount: Decimal;
}
