page 50182 "GJW Item Reclass Jnl API"
{
    PageType = API;
    Caption = 'Item Reclassification Journal API';
    APIPublisher = 'adelante';
    APIGroup = 'returns';
    APIVersion = 'v1.0';
    EntityName = 'itemReclassJournalLine';
    EntitySetName = 'itemReclassJournalLines';
    SourceTable = "Item Journal Line";
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
                field(postingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date';
                }
                field(documentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                }
                field(itemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code (From)';
                }
                field(newLocationCode; Rec."New Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'New Location Code (To)';
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
                field(unitAmount; Rec."Unit Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Amount';
                }
                field(appliesFromEntry; Rec."Applies-from Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-from Entry';
                }
                field(entryType; Rec."Entry Type")
                {
                    ApplicationArea = All;
                    Caption = 'Entry Type';
                    Editable = false;
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(newShortcutDimension1Code; Rec."New Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Caption = 'New Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(newShortcutDimension2Code; Rec."New Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Caption = 'New Shortcut Dimension 2 Code';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        JobTask: Record "Job Task";
    begin
        // PRIMERO: Forzar Entry Type a Transfer
        Rec."Entry Type" := Rec."Entry Type"::Transfer;

        // SEGUNDO: Establecer Template y Batch
        if Rec."Journal Template Name" = '' then
            Rec."Journal Template Name" := 'TRANSFEREN';

        if Rec."Journal Batch Name" = '' then
            Rec."Journal Batch Name" := 'GENERICO';

        if Rec."Posting Date" = 0D then
            Rec."Posting Date" := WorkDate();

        // CRÍTICO: Si vienen dimensiones en origen, copiarlas a destino para devoluciones
        if (Rec."Shortcut Dimension 1 Code" <> '') and (Rec."New Shortcut Dimension 1 Code" = '') then
            Rec."New Shortcut Dimension 1 Code" := Rec."Shortcut Dimension 1 Code";

        if (Rec."Shortcut Dimension 2 Code" <> '') and (Rec."New Shortcut Dimension 2 Code" = '') then
            Rec."New Shortcut Dimension 2 Code" := Rec."Shortcut Dimension 2 Code";

        // CRÍTICO: Si NO vienen dimensiones pero viene Location Code, obtenerlas del Job Task
        if (Rec."Shortcut Dimension 1 Code" = '') and (Rec."Location Code" <> '') then begin
            JobTask.Reset();
            JobTask.SetRange("Location Code", Rec."Location Code");
            if JobTask.FindFirst() then begin
                Rec."Shortcut Dimension 1 Code" := JobTask."Job No.";
                Rec."New Shortcut Dimension 1 Code" := JobTask."Job No.";
            end;
        end;

        exit(true);
    end;
}
