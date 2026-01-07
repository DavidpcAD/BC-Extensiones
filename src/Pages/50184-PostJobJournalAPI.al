page 50184 "GJW Post Job Journal API"
{
    PageType = API;
    Caption = 'Post Job Journal API';
    APIPublisher = 'adelante';
    APIGroup = 'returns';
    APIVersion = 'v1.0';
    EntityName = 'postJobJournal';
    EntitySetName = 'postJobJournals';
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
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostBatch: Codeunit "Job Jnl.-Post Batch";
        Job: Record Job;
        JobTask: Record "Job Task";
        Item: Record Item;
        Location: Record Location;
        LineCount: Integer;
        BatchName: Code[20];
        TemplateName: Code[10];
        ValidationErrors: Text[1000];
    begin
        // Validate batch name received
        if Rec."Command Data" = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: Batch name is required in Command Data.';
            exit(true);
        end;

        BatchName := CopyStr(Rec."Command Data", 1, 20);
        TemplateName := 'PROJECT';

        // Get lines from batch
        JobJnlLine.Reset();
        JobJnlLine.SetRange("Journal Template Name", TemplateName);
        JobJnlLine.SetRange("Journal Batch Name", BatchName);

        if not JobJnlLine.FindSet() then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR: No lines found in Template: %1, Batch: %2', TemplateName, BatchName);
            exit(true);
        end;

        // VALIDACIONES PREVIAS - Verificar PRIMERA línea
        ValidationErrors := '';

        if JobJnlLine."Job No." = '' then
            ValidationErrors += 'Job No. is blank. ';

        if JobJnlLine."Job Task No." = '' then
            ValidationErrors += 'Job Task No. is blank. ';

        if not Job.Get(JobJnlLine."Job No.") then
            ValidationErrors += 'Job ' + JobJnlLine."Job No." + ' does not exist. ';

        if not JobTask.Get(JobJnlLine."Job No.", JobJnlLine."Job Task No.") then
            ValidationErrors += 'Job Task ' + JobJnlLine."Job Task No." + ' does not exist. ';

        if JobJnlLine."No." = '' then
            ValidationErrors += 'Item No. is blank. ';

        if (JobJnlLine."No." <> '') and (not Item.Get(JobJnlLine."No.")) then
            ValidationErrors += 'Item ' + JobJnlLine."No." + ' does not exist. ';

        if JobJnlLine."Location Code" <> '' then begin
            if not Location.Get(JobJnlLine."Location Code") then
                ValidationErrors += 'Location ' + JobJnlLine."Location Code" + ' does not exist. ';
        end;

        if JobJnlLine."Posting Date" = 0D then
            ValidationErrors += 'Posting Date is blank. ';

        if JobJnlLine."Document Date" = 0D then
            ValidationErrors += 'Document Date is blank. ';

        if JobJnlLine."Document No." = '' then
            ValidationErrors += 'Document No. is blank. ';

        // Si hay errores de validación, retornar
        if ValidationErrors <> '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := CopyStr('VALIDATION ERROR: ' + ValidationErrors, 1, 250);
            exit(true);
        end;

        // Count lines BEFORE posting
        LineCount := JobJnlLine.Count();

        // Execute posting with error handling
        Commit();
        ClearLastError();

        if not JobJnlPostBatch.Run(JobJnlLine) then begin
            Rec."Lines Posted" := 0;
            if GetLastErrorText() <> '' then
                Rec."Success Message" := CopyStr('ERROR BC: ' + GetLastErrorText(), 1, 250)
            else
                Rec."Success Message" := 'ERROR: Posting failed. Check Job Journal for validation errors.';
            ClearLastError();
            exit(true);
        end;

        // Verify posting was successful
        JobJnlLine.Reset();
        JobJnlLine.SetRange("Journal Template Name", TemplateName);
        JobJnlLine.SetRange("Journal Batch Name", BatchName);

        if JobJnlLine.FindFirst() then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR: Posting failed. %1 lines remain unprocessed.', JobJnlLine.Count());
            exit(true);
        end;

        // Set success result
        Rec."Lines Posted" := LineCount;
        Rec."Success Message" := StrSubstNo('✅ %1 lines posted successfully (Job Journal - Negative Adjustment)', LineCount);

        exit(true);
    end;
}
