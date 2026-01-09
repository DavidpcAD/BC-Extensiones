page 50184 "GJW Post Job Journal API"
{
    PageType = API;
    Caption = 'Post Job Journal API';
    APIPublisher = 'adelante';
    APIGroup = 'project';
    APIVersion = 'v1.0';
    EntityName = 'postJobJournal';
    EntitySetName = 'postJobJournals';



    SourceTable = "GJW Post Job Journal Cmd";
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
                field(commandId; Rec."Command ID")
                {
                    ApplicationArea = All;
                    Caption = 'Command ID';
                }
                field(batchName; Rec."Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Batch Name';
                }
                field(itemNo; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
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
                field(documentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
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
                field(unitCost; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost';
                }
                field(linesPosted; Rec."Lines Posted")
                {
                    ApplicationArea = All;
                    Caption = 'Lines Posted';
                    Editable = false;
                }
                field(successMessage; Rec."Success Message")
                {
                    ApplicationArea = All;
                    Caption = 'Success Message';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostBatch: Codeunit "Job Jnl.-Post";
        LineCount: Integer;
    begin
        // LEER desde DB con aislamiento correcto
        JobJnlLine.ReadIsolation := JobJnlLine.ReadIsolation::ReadUncommitted;
        JobJnlLine.Reset();
        JobJnlLine.SetRange("Journal Template Name", 'PROJECT');
        JobJnlLine.SetRange("Journal Batch Name", 'DEFAULT');

        // Verificar si existen líneas
        if not JobJnlLine.FindSet() then begin
            // Intentar sin filtros para debug
            JobJnlLine.Reset();
            JobJnlLine.ReadIsolation := JobJnlLine.ReadIsolation::ReadUncommitted;
            Rec."Success Message" := 'ERROR: No hay líneas en PROJECT/DEFAULT. Total en tabla: ' + Format(JobJnlLine.Count);
            exit(true);
        end;

        // Contar líneas
        repeat
            LineCount += 1;
        until JobJnlLine.Next() = 0;

        // REGISTRAR
        JobJnlLine.Reset();
        JobJnlLine.SetRange("Journal Template Name", 'PROJECT');
        JobJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if JobJnlLine.FindFirst() then begin
            Commit();
            JobJnlPostBatch.Run(JobJnlLine);
        end;

        Rec."Lines Posted" := LineCount;
        Rec."Success Message" := '✅ ' + Format(LineCount) + ' líneas registradas';
        exit(true);
    end;
}
