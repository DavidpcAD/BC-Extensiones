page 50150 "Adelante Job Journal Line API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'project';
    APIVersion = 'v1.0';

    EntityName = 'jobJournalLine';
    EntitySetName = 'jobJournalLines';

    SourceTable = "Job Journal Line";

    // ⬇⬇⬇ CAMBIO IMPORTANTE: sin GUID
    ODataKeyFields = SystemId;
    // ⬆⬆⬆

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
                field(systemId; Rec.SystemId) { Caption = 'System Id'; }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Caption = 'System Created At'; }
                field(systemCreatedBy; Rec.SystemCreatedBy) { Caption = 'System Created By'; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }
                field(systemModifiedBy; Rec.SystemModifiedBy) { Caption = 'System Modified By'; }

                field(journalTemplateName; Rec."Journal Template Name")
                {
                    ApplicationArea = All;
                }
                field(journalBatchName; Rec."Journal Batch Name")
                {
                    ApplicationArea = All;
                }
                field(lineNo; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false; // lo genera el AutoNo (CU 50155)
                }
                field(documentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field(postingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }

                // Proyecto / tarea
                field(jobNo; Rec."Job No.")
                {
                    ApplicationArea = All;
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                }

                // Item
                field(type; Rec.Type)
                {
                    ApplicationArea = All;
                }
                field(no; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                }

                // Cantidades / importes
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field(unitCost; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                }
                field(unitPrice; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
                field(lineAmount; Rec."Line Amount")
                {
                    ApplicationArea = All;
                }

                // Almacén
                field(locationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field(appliesToEntry; Rec."Applies-to Entry")
                {
                    ApplicationArea = All;
                }

                // Dimensiones
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                }

                // Ledger
                field(ledgerEntryType; Rec."Ledger Entry Type")
                {
                    ApplicationArea = All;
                }
                field(ledgerEntryNo; Rec."Ledger Entry No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
