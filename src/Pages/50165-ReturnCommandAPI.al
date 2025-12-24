page 50165 "GJW Return Command API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'returnCommand';
    EntitySetName = 'returnCommands';

    SourceTable = "GJW Return Command";
    SourceTableTemporary = true;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(jobNo; Rec."Job No.")
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field(taskNo; Rec."Task No.")
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field(itemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field(returnType; Rec."Return Type")
                {
                    ApplicationArea = All;
                }
                field(destinationJobNo; Rec."Destination Job No.")
                {
                    ApplicationArea = All;
                }
                field(destinationTaskNo; Rec."Destination Task No.")
                {
                    ApplicationArea = All;
                }
                field(sourceLocationCode; Rec."Source Location Code")
                {
                    ApplicationArea = All;
                }
                field(destinationLocationCode; Rec."Destination Location Code")
                {
                    ApplicationArea = All;
                }
                field(postingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field(itemLedgerEntryNo; Rec."Item Ledger Entry No.")
                {
                    ApplicationArea = All;
                }
                field(linesPosted; Rec."Lines Posted")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(successMessage; Rec."Success Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(inputJobNo; Rec."Input Job No.")
                {
                    ApplicationArea = All;
                }
                field(inputTaskNo; Rec."Input Task No.")
                {
                    ApplicationArea = All;
                }
                field(inputItemNo; Rec."Input Item No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ProcessReturn: Codeunit "GJW Process Material Return";
    begin
        // Copiar campos Input a campos reales
        if Rec."Input Job No." <> '' then
            Rec."Job No." := Rec."Input Job No.";
        if Rec."Input Task No." <> '' then
            Rec."Task No." := Rec."Input Task No.";
        if Rec."Input Item No." <> '' then
            Rec."Item No." := Rec."Input Item No.";

        // Inferir jobNo del sourceLocationCode si aún está vacío
        if Rec."Job No." = '' then
            Rec."Job No." := Rec."Source Location Code";

        // Validar datos obligatorios
        if Rec."Job No." = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: Job No. es requerido';
            exit(true);
        end;

        if Rec."Task No." = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: Task No. es requerido';
            exit(true);
        end;

        if Rec."Item No." = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: Item No. es requerido';
            exit(true);
        end;

        if Rec.Quantity <= 0 then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: Quantity debe ser mayor a cero';
            exit(true);
        end;

        if Rec."Posting Date" = 0D then
            Rec."Posting Date" := Today();

        // Procesar la devolución
        ProcessReturn.ProcessReturn(Rec);

        // El codeunit ya estableció Success Message y Lines Posted
        exit(true);
    end;
}
