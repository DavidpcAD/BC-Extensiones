page 50202 "GJW Gen. Journal Line API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'finance';
    APIVersion = 'v1.0';
    EntityName = 'genJournalLine';
    EntitySetName = 'genJournalLines';

    SourceTable = "Gen. Journal Line";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Main)
            {
                field(systemId; Rec.SystemId) { Caption = 'System Id'; ApplicationArea = All; }
                field(journalTemplateName; Rec."Journal Template Name") { Caption = 'Journal Template Name'; ApplicationArea = All; }
                field(journalBatchName; Rec."Journal Batch Name") { Caption = 'Journal Batch Name'; ApplicationArea = All; }
                field(lineNo; Rec."Line No.") { Caption = 'Line No.'; ApplicationArea = All; }

                field(postingDate; Rec."Posting Date") { Caption = 'Posting Date'; ApplicationArea = All; }
                field(documentType; Rec."Document Type") { Caption = 'Document Type'; ApplicationArea = All; }
                field(documentNo; Rec."Document No.") { Caption = 'Document No.'; ApplicationArea = All; }

                field(accountType; Rec."Account Type") { Caption = 'Account Type'; ApplicationArea = All; }
                field(accountNo; Rec."Account No.") { Caption = 'Account No.'; ApplicationArea = All; }
                field(accountName; AccountName) { Caption = 'Account Name'; ApplicationArea = All; Editable = false; }

                field(description; Rec.Description) { Caption = 'Description'; ApplicationArea = All; }

                field(amount; Rec.Amount) { Caption = 'Amount'; ApplicationArea = All; }
                field(debitAmount; Rec."Debit Amount") { Caption = 'Debit Amount'; ApplicationArea = All; }
                field(creditAmount; Rec."Credit Amount") { Caption = 'Credit Amount'; ApplicationArea = All; }

                field(balAccountType; Rec."Bal. Account Type") { Caption = 'Bal. Account Type'; ApplicationArea = All; }
                field(balAccountNo; Rec."Bal. Account No.") { Caption = 'Bal. Account No.'; ApplicationArea = All; }

                field(jobNo; Rec."Job No.") { Caption = 'Job No.'; ApplicationArea = All; }
                field(jobTaskNo; Rec."Job Task No.") { Caption = 'Job Task No.'; ApplicationArea = All; }

                field(genPostingType; Rec."Gen. Posting Type") { Caption = 'Gen. Posting Type'; ApplicationArea = All; }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group") { Caption = 'Gen. Bus. Posting Group'; ApplicationArea = All; }
                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group") { Caption = 'Gen. Prod. Posting Group'; ApplicationArea = All; }

                field(dimensionSetId; Rec."Dimension Set ID") { Caption = 'Dimension Set ID'; ApplicationArea = All; }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code") { Caption = 'Shortcut Dimension 1 Code'; ApplicationArea = All; }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code") { Caption = 'Shortcut Dimension 2 Code'; ApplicationArea = All; }

                // --- Dimensiones calculadas (CC / AC) ---
                field(centroCosto; CentroCosto) { Caption = 'Centro de Costo'; ApplicationArea = All; Editable = false; }
                field(areaCosto; AreaCosto) { Caption = 'Area de Costo'; ApplicationArea = All; Editable = false; }
            }
        }
    }

    var
        CentroCosto: Code[20];
        AreaCosto: Code[20];
        AccountName: Text[100];
        GLAccount: Record "G/L Account";
        DimSetEntry: Record "Dimension Set Entry";
        LastGenJnlLine: Record "Gen. Journal Line";

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // Calcular el siguiente Line No. dentro del mismo Template + Batch
        if Rec."Line No." = 0 then begin
            LastGenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            LastGenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
            if LastGenJnlLine.FindLast() then
                Rec."Line No." := LastGenJnlLine."Line No." + 10000
            else
                Rec."Line No." := 10000;
        end;
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        // Nombre cuenta contable
        if (Rec."Account Type" = Rec."Account Type"::"G/L Account") and GLAccount.Get(Rec."Account No.") then
            AccountName := GLAccount.Name
        else
            AccountName := '';

        CentroCosto := '';
        AreaCosto := '';

        if Rec."Dimension Set ID" <> 0 then begin
            DimSetEntry.SetRange("Dimension Set ID", Rec."Dimension Set ID");
            if DimSetEntry.FindSet() then
                repeat
                    case DimSetEntry."Dimension Code" of
                        'CC':
                            CentroCosto := DimSetEntry."Dimension Value Code";
                        'AC':
                            AreaCosto := DimSetEntry."Dimension Value Code";
                    end;
                until DimSetEntry.Next() = 0;
        end;
    end;
}
