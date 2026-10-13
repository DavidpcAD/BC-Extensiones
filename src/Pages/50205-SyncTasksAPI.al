page 50205 "GJW Sync Tasks API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'syncTaskToWorks';
    EntitySetName = 'syncTasksToWorks';

    SourceTable = "GJW Sync Tasks Buffer";
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
                field(worksNo; Rec."Works No.")
                {
                    Caption = 'Works No.';
                    ApplicationArea = All;
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                    ApplicationArea = All;
                }
                field(tasksCreated; Rec."Tasks Created")
                {
                    Caption = 'Tasks Created';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(tasksSkipped; Rec."Tasks Skipped")
                {
                    Caption = 'Tasks Skipped';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(resultMessage; Rec."Result Message")
                {
                    Caption = 'Result Message';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'Error Message';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        SyncTasksToWorks: Codeunit "GJW Sync Tasks To Works";
        TasksCreated: Integer;
        TasksSkipped: Integer;
        ResultMessage: Text;
        ErrorMessage: Text;
    begin
        if SyncTasksToWorks.SyncTasks(Rec."Works No.", Rec."Job Task No.", TasksCreated, TasksSkipped, ResultMessage, ErrorMessage) then begin
            Rec."Tasks Created" := TasksCreated;
            Rec."Tasks Skipped" := TasksSkipped;
            Rec."Result Message" := CopyStr(ResultMessage, 1, MaxStrLen(Rec."Result Message"));
        end else
            Rec."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(Rec."Error Message"));
        exit(true);
    end;
}
