// ════════════════════════════════════════════════════════════════════════════════
// Page 50249 "GJW Realizado Por Backfill API"
// Operación (singleton, mismo patrón que materialConsumptionOperations) para completar
// "Realizado por" en Movs. proyecto ya registrados. Ver codeunit 50246.
//
// POST .../construction/v1.0/companies(..)/realizadoPorBackfillOperations
//   { "jobLedgerEntryNos": "148741,148743", "documentNo": "BE000016",
//     "realizadoPor": "Yoanni Bonilla Torres", "execute": true }
// → result = JSON por movimiento: actualizado | ya tenía | otro documento | no existe
// ════════════════════════════════════════════════════════════════════════════════
page 50249 "GJW Realizado Por Backfill API"
{
    PageType = API;
    Caption = 'Realizado Por Backfill';
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'realizadoPorBackfillOperation';
    EntitySetName = 'realizadoPorBackfillOperations';
    DelayedInsert = true;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = ID;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                }
                field(jobLedgerEntryNos; JobLedgerEntryNos)
                {
                    ApplicationArea = All;
                    Caption = 'Job Ledger Entry Nos (comma separated)';
                    ToolTip = 'Entry No. de los Movs. proyecto, separados por comas. Ejemplo: 148741,148743';
                }
                field(documentNo; DocumentNo)
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                    ToolTip = 'Document No. que deben tener los movimientos (ej: BE000016). Si no coincide, no se tocan.';
                }
                field(realizadoPor; RealizadoPor)
                {
                    ApplicationArea = All;
                    Caption = 'Realizado por';
                    ToolTip = 'Persona de la app que originó el movimiento (en Boletas, el encargado que pidió el material).';
                }
                field(execute; ExecuteBackfill)
                {
                    ApplicationArea = All;
                    Caption = 'Execute';
                    ToolTip = 'Establecer en true (después de los demás campos) para completar el campo.';

                    trigger OnValidate()
                    begin
                        if ExecuteBackfill then
                            ProcessBackfill();
                    end;
                }
                field(result; ResultMessage)
                {
                    ApplicationArea = All;
                    Caption = 'Result';
                    Editable = false;
                }
                field(success; Success)
                {
                    ApplicationArea = All;
                    Caption = 'Success';
                    Editable = false;
                }
            }
        }
    }

    var
        JobLedgerEntryNos: Text;
        DocumentNo: Code[20];
        RealizadoPor: Text[50];
        ExecuteBackfill: Boolean;
        ResultMessage: Text;
        Success: Boolean;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.ID := 1;
            Rec.Insert();
        end;
    end;

    local procedure ProcessBackfill()
    var
        Backfill: Codeunit "GJW Realizado Por Backfill";
    begin
        Success := false;
        ResultMessage := '';
        if not TryBackfill(Backfill) then
            ResultMessage := 'Error: ' + GetLastErrorText()
        else
            Success := true;
        ExecuteBackfill := false;
    end;

    [TryFunction]
    local procedure TryBackfill(var Backfill: Codeunit "GJW Realizado Por Backfill")
    begin
        ResultMessage := Backfill.Backfill(JobLedgerEntryNos, DocumentNo, RealizadoPor);
    end;
}
