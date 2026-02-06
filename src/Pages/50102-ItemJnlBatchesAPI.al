page 50102 "GJW Item Journal Batches API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';

    EntityName = 'itemJournalBatch';
    EntitySetName = 'itemJournalBatches';

    SourceTable = "Item Journal Batch"; // 233
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // --- Campos de sistema ---
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(systemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'System Created At';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(systemCreatedBy; Rec.SystemCreatedBy)
                {
                    Caption = 'System Created By';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(systemModifiedBy; Rec.SystemModifiedBy)
                {
                    Caption = 'System Modified By';
                    ApplicationArea = All;
                    Editable = false;
                }

                // --- Campos principales de la tabla 233 ---
                field(journalTemplateName; Rec."Journal Template Name")
                {
                    ApplicationArea = All;
                }
                field(name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(reasonCode; Rec."Reason Code")
                {
                    ApplicationArea = All;
                }
                field(noSeries; Rec."No. Series")
                {
                    ApplicationArea = All;
                }
                field(postingNoSeries; Rec."Posting No. Series")
                {
                    ApplicationArea = All;
                }

                // --- FlowFields / solo lectura ---
                field(templateType; Rec."Template Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(recurring; Rec.Recurring)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(itemTrackingOnLines; Rec."Item Tracking on Lines")
                {
                    ApplicationArea = All;
                }

                // --- Campo ID Colaborador ---
                field(idColaborador; Rec."GJW ID Colaborador")
                {
                    ApplicationArea = All;
                    Caption = 'ID Colaborador';
                }

                // --- Campo para forzar SetupNewBatch ---
                field(runSetup; RunSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Run Setup';
                }

                // --- Campo debug para verificar SetupNewBatch ---
                field(setupExecuted; SetupExecuted)
                {
                    ApplicationArea = All;
                    Caption = 'Setup Executed';
                    Editable = false;
                }

                // --- ✅ CAMPO PARA REGISTRAR DESDE POWER APPS ---
                field(triggerPost; Rec."GJW Trigger Post")
                {
                    ApplicationArea = All;
                    Caption = 'Trigger Post';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        SetupExecuted := false;

        // Si desde Power Apps mandan runSetup=true, ejecuta SetupNewBatch
        if RunSetup then begin
            Rec.SetupNewBatch();
            SetupExecuted := true;
        end;

        exit(true); // Dejar que BC continúe la inserción normal
    end;

    var
        SetupExecuted: Boolean;
        RunSetup: Boolean;
}
