page 50188 "GJW Proj Material Transfer API"
{
    PageType = API;
    Caption = 'Project Material Transfer API';
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'projectMaterialTransfer';
    EntitySetName = 'projectMaterialTransfers';
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
                field(sourceEntryNo; SourceEntryNo)
                {
                    ApplicationArea = All;
                    Caption = 'Source Item Ledger Entry No.';

                    trigger OnValidate()
                    begin
                        LoadFromItemLedgerEntry();
                    end;
                }
                field(sourceProjectNo; SourceProjectNo)
                {
                    ApplicationArea = All;
                    Caption = 'Source Project No.';
                    Editable = false;
                }
                field(sourceLocationCode; SourceLocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Source Location Code';
                    Editable = false;
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
                    Editable = false;
                }
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
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
                field(destinationType; DestinationType)
                {
                    ApplicationArea = All;
                    Caption = 'Destination Type';
                    // Options: Project, GeneralWarehouse

                    trigger OnValidate()
                    begin
                        if DestinationType = DestinationType::GeneralWarehouse then begin
                            Rec."New Shortcut Dimension 1 Code" := '';
                            Rec."New Shortcut Dimension 2 Code" := '';
                        end;
                    end;
                }
                field(destinationProjectNo; Rec."New Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Destination Project No.';
                }
                field(destinationTaskNo; Rec."New Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Destination Task No.';
                }
                field(destinationLocationCode; Rec."New Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Destination Location Code';
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
            }
        }
    }

    var
        SourceEntryNo: Integer;
        SourceProjectNo: Code[20];
        SourceLocationCode: Code[10];
        DestinationType: Option Project,GeneralWarehouse;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // Establecer Entry Type como Transfer
        Rec."Entry Type" := Rec."Entry Type"::Transfer;

        // Establecer Template y Batch
        if Rec."Journal Template Name" = '' then
            Rec."Journal Template Name" := 'TRANSFEREN';

        if Rec."Journal Batch Name" = '' then
            Rec."Journal Batch Name" := 'GENERICO';

        if Rec."Posting Date" = 0D then
            Rec."Posting Date" := WorkDate();

        exit(true);
    end;

    local procedure LoadFromItemLedgerEntry()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if SourceEntryNo = 0 then
            exit;

        if not ItemLedgerEntry.Get(SourceEntryNo) then
            Error('Item Ledger Entry %1 not found.', SourceEntryNo);

        // Cargar datos del movimiento origen
        Rec."Item No." := ItemLedgerEntry."Item No.";
        Rec.Description := ItemLedgerEntry.Description;
        Rec."Variant Code" := ItemLedgerEntry."Variant Code";
        Rec."Unit of Measure Code" := ItemLedgerEntry."Unit of Measure Code";
        Rec.Quantity := Abs(ItemLedgerEntry.Quantity); // Cantidad positiva para el traslado
        Rec."Location Code" := ItemLedgerEntry."Location Code";
        Rec."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
        Rec."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";
        Rec."Applies-from Entry" := ItemLedgerEntry."Entry No.";

        // Guardar datos para mostrar
        SourceProjectNo := ItemLedgerEntry."Global Dimension 1 Code";
        SourceLocationCode := ItemLedgerEntry."Location Code";

        // Si tiene costo unitario, copiarlo
        if ItemLedgerEntry."GomJob Cost per Unit" <> 0 then
            Rec."Unit Amount" := ItemLedgerEntry."GomJob Cost per Unit";
    end;
}
