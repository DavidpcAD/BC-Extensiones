page 50195 "GJW Create Job Neg Adjust API"
{
    PageType = API;
    Caption = 'Create Job Negative Adjustment API';
    APIPublisher = 'adelante';
    APIGroup = 'returns';
    APIVersion = 'v1.0';
    EntityName = 'createJobNegativeAdjustment';
    EntitySetName = 'createJobNegativeAdjustments';
    SourceTable = "Item Journal Line";
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
                field(itemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field(unitCost; Rec."Unit Amount")
                {
                    ApplicationArea = All;
                }
                field(locationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field(variantCode; Rec."Variant Code")
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
                }
                field(message; ErrorMessage)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        Success: Boolean;
        ErrorMessage: Text[500];

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        LineNo: Integer;
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        Success := false;
        ErrorMessage := '';

        // Usar template de Item Journal, no Job Journal
        TemplateName := 'ITEM';
        BatchName := 'DEFAULT';

        // Validar template y batch
        if not ItemJnlTemplate.Get(TemplateName) then begin
            ErrorMessage := 'Template ITEM no existe';
            exit(false);
        end;

        if not ItemJnlBatch.Get(TemplateName, BatchName) then begin
            ErrorMessage := 'Batch DEFAULT no existe en template ITEM';
            exit(false);
        end;

        // Validar campos requeridos
        if Rec."Job No." = '' then begin
            ErrorMessage := 'Job No. es requerido';
            exit(false);
        end;

        if Rec."Job Task No." = '' then begin
            ErrorMessage := 'Job Task No. es requerido';
            exit(false);
        end;

        if Rec."Item No." = '' then begin
            ErrorMessage := 'Item No. es requerido';
            exit(false);
        end;

        if Rec.Quantity >= 0 then begin
            ErrorMessage := 'Quantity debe ser negativa para ajuste negativo';
            exit(false);
        end;

        // Obtener siguiente Line No.
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);
        if ItemJnlLine.FindLast() then
            LineNo := ItemJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        // Crear línea de ajuste negativo
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := TemplateName;
        ItemJnlLine."Journal Batch Name" := BatchName;
        ItemJnlLine."Line No." := LineNo;
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
        ItemJnlLine."Document No." := 'DEV-' + Format(WorkDate(), 0, '<Year4><Month,2><Day,2>') + '-' + Format(LineNo);
        ItemJnlLine."Posting Date" := WorkDate();
        ItemJnlLine."Item No." := Rec."Item No.";
        ItemJnlLine.Description := Rec.Description;
        ItemJnlLine.Quantity := Rec.Quantity; // Ya es negativo
        ItemJnlLine."Location Code" := Rec."Location Code";
        ItemJnlLine."Variant Code" := Rec."Variant Code";
        ItemJnlLine."Unit Amount" := Rec."Unit Amount";

        // CRÍTICO: Asignar Job para que se registre en Job Ledger
        ItemJnlLine."Job No." := Rec."Job No.";
        ItemJnlLine."Job Task No." := Rec."Job Task No.";
        ItemJnlLine."Shortcut Dimension 1 Code" := Rec."Job No.";

        // Insertar y postear directamente
        ItemJnlLine.Insert(false);

        Commit();
        ClearLastError();

        // Postear línea
        if not ItemJnlPostLine.Run(ItemJnlLine) then begin
            ErrorMessage := 'ERROR: ' + GetLastErrorText();
            ClearLastError();
            exit(false);
        end;

        Success := true;
        ErrorMessage := 'Ajuste negativo creado y posteado correctamente';

        exit(false); // No insertar en tabla temporal
    end;
}
