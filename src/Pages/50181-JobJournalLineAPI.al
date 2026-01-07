page 50181 "GJW Job Journal Line API"
{
    PageType = API;
    Caption = 'Job Journal Lines API';
    APIPublisher = 'adelante';
    APIGroup = 'returns';
    APIVersion = 'v1.0';
    EntityName = 'jobJournalLine';
    EntitySetName = 'jobJournalLines';
    SourceTable = "Job Journal Line";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(lineNo; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.';
                }
                field(journalTemplateName; Rec."Journal Template Name")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Template Name';
                    Editable = false;
                }
                field(journalBatchName; Rec."Journal Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Batch Name';
                    Editable = false;
                }
                field(jobNo; Rec."Job No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job No.';
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Task No.';
                }
                field(lineType; Rec."Line Type")
                {
                    ApplicationArea = All;
                    Caption = 'Line Type';
                }
                field(type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                }
                field(no; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Unit of Measure Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code';
                }
                field(postingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date';
                }
                field(documentDate; Rec."Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'Document Date';
                }
                field(documentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                }
                field(unitCost; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost';
                }
                field(totalCost; Rec."Total Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Total Cost';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price';
                }
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shortcut Dimension 2 Code';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // PASO 1: Establecer Template y Batch si no vienen informados
        if Rec."Journal Template Name" = '' then
            Rec."Journal Template Name" := 'PROJECT';

        if Rec."Journal Batch Name" = '' then
            Rec."Journal Batch Name" := 'DEFAULT';

        // PASO 2: Posting Date por defecto
        if Rec."Posting Date" = 0D then
            Rec."Posting Date" := WorkDate();

        // PASO 3: Document Date por defecto (CRÍTICO para BC)
        if Rec."Document Date" = 0D then
            Rec."Document Date" := Rec."Posting Date";

        // PASO 4: Document No. por defecto si no viene
        if Rec."Document No." = '' then
            Rec."Document No." := Rec."Job No." + '-' + Format(Rec."Posting Date", 0, '<Year4><Month,2><Day,2>');

        // PASO 5: Asegurar que Shortcut Dimension 1 = Job No.
        if (Rec."Shortcut Dimension 1 Code" = '') and (Rec."Job No." <> '') then
            Rec."Shortcut Dimension 1 Code" := Rec."Job No.";

        exit(true);
    end;
}
