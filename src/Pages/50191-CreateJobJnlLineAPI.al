page 50191 "GJW Create Job Jnl Line API"
{
    PageType = API;
    Caption = 'Create Job Journal Line API';
    APIPublisher = 'adelante';
    APIGroup = 'returns';
    APIVersion = 'v1.0';
    EntityName = 'createJobJournalLine';
    EntitySetName = 'createJobJournalLines';
    SourceTable = "Job Journal Line";
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
                field(jobNo; Rec."Job No.")
                {
                    ApplicationArea = All;
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                }
                field(no; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field(unitPrice; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(success; Success)
                {
                    ApplicationArea = All;
                    Caption = 'Success';
                }
                field(message; Message)
                {
                    ApplicationArea = All;
                    Caption = 'Message';
                }
            }
        }
    }

    var
        Success: Boolean;
        Message: Text[250];

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        CreateJobJnlLine: Codeunit "GJW Create Job Journal Line";
    begin
        Success := false;
        Message := '';

        if CreateJobJnlLine.CreateLine(
            Rec."Job No.",
            Rec."Job Task No.",
            Rec."No.",
            Rec.Quantity,
            Rec."Unit Price",
            Rec.Description
        ) then begin
            Success := true;
            Message := 'Línea creada correctamente';
        end else begin
            Success := false;
            Message := 'Error al crear línea';
        end;

        exit(false); // No insertar en tabla temporal, solo ejecutar lógica
    end;
}
