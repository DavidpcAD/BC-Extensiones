page 50199 "GJW G/L Entry API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'finance';
    APIVersion = 'v1.0';
    EntityName = 'glEntry';
    EntitySetName = 'glEntries';

    SourceTable = "G/L Entry";
    ODataKeyFields = "Entry No.";
    DelayedInsert = true;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Main)
            {
                // --- Trazabilidad ---
                field(entryNo; Rec."Entry No.") { Caption = 'Entry No.'; ApplicationArea = All; }
                field(transactionNo; Rec."Transaction No.") { Caption = 'Transaction No.'; ApplicationArea = All; }

                // --- Fecha y documento ---
                field(postingDate; Rec."Posting Date") { Caption = 'Posting Date'; ApplicationArea = All; }
                field(documentType; Rec."Document Type") { Caption = 'Document Type'; ApplicationArea = All; }
                field(documentNo; Rec."Document No.") { Caption = 'Document No.'; ApplicationArea = All; }

                // --- Cuenta ---
                field(glAccountNo; Rec."G/L Account No.") { Caption = 'G/L Account No.'; ApplicationArea = All; }
                field(glAccountName; Rec."G/L Account Name") { Caption = 'G/L Account Name'; ApplicationArea = All; Editable = false; }

                // --- Importes ---
                field(amount; Rec.Amount) { Caption = 'Amount'; ApplicationArea = All; }
                field(debitAmount; Rec."Debit Amount") { Caption = 'Debit Amount'; ApplicationArea = All; }
                field(creditAmount; Rec."Credit Amount") { Caption = 'Credit Amount'; ApplicationArea = All; }

                // --- Descripcion ---
                field(description; Rec.Description) { Caption = 'Description'; ApplicationArea = All; }

                // --- Grupos contables ---
                field(genPostingType; Rec."Gen. Posting Type") { Caption = 'Gen. Posting Type'; ApplicationArea = All; }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group") { Caption = 'Gen. Bus. Posting Group'; ApplicationArea = All; }
                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group") { Caption = 'Gen. Prod. Posting Group'; ApplicationArea = All; }

                // --- Contrapartida ---
                field(balAccountType; Rec."Bal. Account Type") { Caption = 'Bal. Account Type'; ApplicationArea = All; }
                field(balAccountNo; Rec."Bal. Account No.") { Caption = 'Bal. Account No.'; ApplicationArea = All; }

                // --- Origen ---
                field(sourceType; Rec."Source Type") { Caption = 'Source Type'; ApplicationArea = All; }
                field(sourceCode; Rec."Source Code") { Caption = 'Source Code'; ApplicationArea = All; }
                field(sourceNo; Rec."Source No.") { Caption = 'Source No.'; ApplicationArea = All; }

                // --- Proyecto ---
                field(jobNo; Rec."Job No.") { Caption = 'N.º proyecto'; ApplicationArea = All; }
                field(gomJobDimensionCode; Rec."GomJob Job Dimension Code") { Caption = 'GomJob Job Dimension Code'; ApplicationArea = All; }
                field(globalDimension1Code; Rec."Global Dimension 1 Code") { Caption = 'Global Dimension 1 Code'; ApplicationArea = All; }
                field(globalDimension2Code; Rec."Global Dimension 2 Code") { Caption = 'Global Dimension 2 Code'; ApplicationArea = All; }

                // --- Dimensiones (CC = Centro Costo, AC = Area Costo) ---
                field(centroCosto; CentroCosto) { Caption = 'Centro de Costo'; ApplicationArea = All; Editable = false; }
                field(areaCosto; AreaCosto) { Caption = 'Area de Costo'; ApplicationArea = All; Editable = false; }

                // --- Dimension Set ID (para consultas adicionales) ---
                field(dimensionSetID; Rec."Dimension Set ID") { Caption = 'Dimension Set ID'; ApplicationArea = All; }
            }
        }
    }

    var
        CentroCosto: Code[20];
        AreaCosto: Code[20];
        DimSetEntry: Record "Dimension Set Entry";

    trigger OnAfterGetRecord()
    begin
        // Dimensiones desde Dimension Set Entry
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
