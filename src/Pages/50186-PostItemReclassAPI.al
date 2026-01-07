page 50186 "GJW Post Item Reclass API"
{
    PageType = API;
    Caption = 'Post Item Reclassification API';
    APIPublisher = 'adelante';
    APIGroup = 'returns';
    APIVersion = 'v1.0';
    EntityName = 'postItemReclass';
    EntitySetName = 'postItemReclasses';
    SourceTable = "GJW Post Command";
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
                field(commandData; Rec."Command Data")
                {
                    ApplicationArea = All;
                    Caption = 'Batch Name';
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
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        LineCount: Integer;
        BatchName: Code[20];
        TemplateName: Code[10];
    begin
        // Validate batch name received
        if Rec."Command Data" = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: Batch name is required in Command Data.';
            exit(true);
        end;

        BatchName := CopyStr(Rec."Command Data", 1, 20);
        TemplateName := 'TRANSFEREN';

        // Get lines from batch
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if not ItemJnlLine.FindSet() then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR: No lines found in Template: %1, Batch: %2', TemplateName, BatchName);
            exit(true);
        end;

        // Count lines BEFORE posting
        LineCount := ItemJnlLine.Count();

        // Execute posting with error handling
        Commit();

        if not ItemJnlPostBatch.Run(ItemJnlLine) then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := CopyStr('ERROR BC: ' + GetLastErrorText(), 1, 250);
            ClearLastError();
            exit(true);
        end;

        // Verify posting was successful
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if ItemJnlLine.FindFirst() then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR: Posting failed. %1 lines remain unprocessed.', ItemJnlLine.Count());
            exit(true);
        end;

        // Set success result
        Rec."Lines Posted" := LineCount;
        Rec."Success Message" := StrSubstNo('✅ %1 lines posted successfully (Item Reclassification)', LineCount);

        exit(true);
    end;
}
