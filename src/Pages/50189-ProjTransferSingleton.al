page 50189 "GJW Proj Transfer Singleton"
{
    PageType = API;
    Caption = 'Project Material Transfer Singleton';
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'projectMaterialTransferOperation';
    EntitySetName = 'projectMaterialTransferOperations';
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
                field(sourceProjectNo; SourceProjectNo)
                {
                    ApplicationArea = All;
                    Caption = 'Source Project No.';
                }
                field(sourceLocationCode; SourceLocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Source Location Code';
                }
                field(destinationType; DestinationType)
                {
                    ApplicationArea = All;
                    Caption = 'Destination Type';
                    // Options: Project, GeneralWarehouse
                }
                field(destinationProjectNo; DestinationProjectNo)
                {
                    ApplicationArea = All;
                    Caption = 'Destination Project No.';
                }
                field(destinationTaskNo; DestinationTaskNo)
                {
                    ApplicationArea = All;
                    Caption = 'Destination Task No.';
                }
                field(destinationLocationCode; DestinationLocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Destination Location Code';
                }
                field(createTransfers; CreateTransfers)
                {
                    ApplicationArea = All;
                    Caption = 'Create Transfers';

                    trigger OnValidate()
                    begin
                        if CreateTransfers then
                            ExecuteCreateTransfers();
                    end;
                }
                field(getNegativeAdjustments; GetNegativeAdjustments)
                {
                    ApplicationArea = All;
                    Caption = 'Get Negative Adjustments';

                    trigger OnValidate()
                    begin
                        if GetNegativeAdjustments then
                            ExecuteGetNegativeAdjustments();
                    end;
                }
                field(result; ResultMessage)
                {
                    ApplicationArea = All;
                    Caption = 'Result';
                    Editable = false;
                }
                field(negativeAdjustmentsJson; NegativeAdjustmentsJson)
                {
                    ApplicationArea = All;
                    Caption = 'Negative Adjustments JSON';
                    Editable = false;
                }
            }
        }
    }

    var
        SourceProjectNo: Code[20];
        SourceLocationCode: Code[10];
        DestinationType: Text[30];
        DestinationProjectNo: Code[20];
        DestinationTaskNo: Code[20];
        DestinationLocationCode: Code[10];
        CreateTransfers: Boolean;
        GetNegativeAdjustments: Boolean;
        ResultMessage: Text;
        NegativeAdjustmentsJson: Text;

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.ID := 1;
        Rec.Insert();
    end;

    local procedure ExecuteCreateTransfers()
    var
        ProjMaterialTransfer: Codeunit "GJW Proj Material Transfer";
        DestTypeOption: Option Project,GeneralWarehouse;
    begin
        CreateTransfers := false;

        // Convertir texto a opción
        if UpperCase(DestinationType) = 'PROJECT' then
            DestTypeOption := DestTypeOption::Project
        else
            DestTypeOption := DestTypeOption::GeneralWarehouse;

        ResultMessage := ProjMaterialTransfer.CreateTransferFromNegativeAdjustments(
            SourceProjectNo,
            SourceLocationCode,
            DestTypeOption,
            DestinationProjectNo,
            DestinationTaskNo,
            DestinationLocationCode
        );
    end;

    local procedure ExecuteGetNegativeAdjustments()
    var
        ProjMaterialTransfer: Codeunit "GJW Proj Material Transfer";
    begin
        GetNegativeAdjustments := false;

        NegativeAdjustmentsJson := ProjMaterialTransfer.GetNegativeAdjustmentsByProject(
            SourceProjectNo,
            SourceLocationCode
        );

        ResultMessage := 'Negative adjustments retrieved successfully';
    end;
}
