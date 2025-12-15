page 50112 "GJW Works Decomposed Line API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';

    EntityName = 'workDecomposedLine';
    EntitySetName = 'workDecomposedLines';

    SourceTable = "GomJob Works Decomposed Lines";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(worksNo; Rec."Works No.") { Caption = 'Work No.'; }
                field(lineNo; Rec."Line No.") { Caption = 'Line No.'; }
                field(taskNo; Rec."Task No.") { Caption = 'Task No.'; }
                field(codeOrder; Rec."Code Order") { Caption = 'Code Order'; }
                field(sourceCode; Rec."Source Code") { Caption = 'Source Code'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(unitAmount; Rec."Unit Amount") { Caption = 'Unit Amount'; }
                field(lineAmount; Rec."Line Amount") { Caption = 'Line Amount'; }
                field(isPosted; Rec."Is Posted") { Caption = 'Is Posted'; }
                field(importDateTime; Rec."Import Date Time") { Caption = 'Import Date Time'; }
                field(jobNo; Rec."Job No.") { Caption = 'Job No.'; }
                field(postedDateTime; Rec."Posted Date Time") { Caption = 'Posted Date Time'; }
                field(postedUser; Rec."Posted User") { Caption = 'Posted User'; }
                field(originCode; Rec."Origin Code") { Caption = 'Origin Code'; }
                field(unitOfMeasure; Rec."Unit of Measure") { Caption = 'Unit of Measure'; }
                field(taskType; Rec."Task Type") { Caption = 'Task Type'; }
                field(prestoTaskNo; Rec."Presto Task No.") { Caption = 'Presto Task No.'; }
                field(type; Rec.Type) { Caption = 'Type'; }
                field(no; Rec."No.") { Caption = 'No.'; }
                field(performance; Rec.Performance) { Caption = 'Performance'; }
                field(unitCost; Rec."Unit Cost") { Caption = 'Unit Cost'; }
                field(variantCode; Rec."Variant Code") { Caption = 'Variant Code'; }
                field(expectedDate; Rec."Expected Date") { Caption = 'Expected Date'; }
                field(idEncargado; Rec."ID Encargado") { Caption = 'ID Encargado'; }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Line: Record "GomJob Works Decomposed Lines";
    begin
        if Rec."Line No." = 0 then begin
            Line.SetRange("Works No.", Rec."Works No.");
            if Line.FindLast() then
                Rec."Line No." := Line."Line No." + 10000
            else
                Rec."Line No." := 10000;
        end;

        exit(true); // ← IMPORTANTE: evita que se intente insertar 2 veces
    end;

}
