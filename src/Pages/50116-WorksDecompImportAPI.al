page 50116 "GJW WorksDecompImportV2 API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';

    EntityName = 'workDecomposedImportV2';
    EntitySetName = 'workDecomposedImportsV2';
    SourceTable = "GomJob Works Decomposed Lines";
    ODataKeyFields = SystemId; // ✅ usar GUID como clave
    DelayedInsert = true;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            field(id; Rec.SystemId)
            {
                Caption = 'Id';
                ApplicationArea = All;
            }

            field(description; Rec.Description)
            {
                Caption = 'Description';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ImportBatchV2)
            {
                Caption = 'Import Batch V2';
                ApplicationArea = All;

                trigger OnAction();
                begin
                    Message('Este método se usa mediante API, no manualmente.');
                end;
            }
        }
    }

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure ImportBatchV3(var ActionContext: WebServiceActionContext; jsonNuevos: Text; jsonEditados: Text; jsonEliminados: Text): Text;
    var
        Bulk: Codeunit "GJW WorksDecomp Bulk";
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"GJW WorksDecompImportV2 API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
        exit(Bulk.Import(jsonNuevos, jsonEditados, jsonEliminados));
    end;
}
