page 50165 "GJW Assembly Post Singleton"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'production';
    APIVersion = 'v1.0';
    EntityName = 'assemblyPostOperation';
    EntitySetName = 'assemblyPostOperations';
    SourceTable = Integer;
    SourceTableTemporary = true;
    DelayedInsert = true;
    InsertAllowed = true;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = Number;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(number; Rec.Number)
                {
                    Caption = 'Number';
                }
                field(documentNo; DocumentNo)
                {
                    Caption = 'Document No.';
                }
                field(autoRelease; AutoRelease)
                {
                    Caption = 'Auto Release';
                }
                field(resultMessage; ResultMessage)
                {
                    Caption = 'Result Message';
                }
            }
        }
    }

    var
        DocumentNo: Code[20];
        AutoRelease: Boolean;
        ResultMessage: Text[250];

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        AssemblyPostHandler: Codeunit "GJW Assembly Post Handler";
    begin
        if DocumentNo = '' then
            Error('Document No. is required');

        // Si AutoRelease = true, libera el pedido primero
        if AutoRelease then begin
            AssemblyPostHandler.ReleaseAssemblyOrder(DocumentNo);
            ResultMessage := 'Released and ';
        end;

        // Registra el pedido
        AssemblyPostHandler.PostAssemblyOrder(DocumentNo);

        ResultMessage := ResultMessage + 'Posted successfully';

        exit(true);
    end;
}
