page 50203 "GJW Post Gen Journal Singleton"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'finance';
    APIVersion = 'v1.0';
    EntityName = 'postGenJournal';
    EntitySetName = 'postGenJournals';

    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = ID;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID) { Caption = 'Id'; }
                field(templateName; TemplateName) { Caption = 'Template Name'; }
                field(batchName; BatchName) { Caption = 'Batch Name'; }
                field(ejecutar; Ejecutar)
                {
                    Caption = 'Ejecutar';
                    trigger OnValidate()
                    begin
                        if Ejecutar then
                            Resultado := PostCU.PostBatch(TemplateName, BatchName);
                    end;
                }
                field(resultado; Resultado) { Caption = 'Resultado'; Editable = false; }
            }
        }
    }

    var
        PostCU: Codeunit "GJW Post Gen. Journal API";
        TemplateName: Code[10];
        BatchName: Code[20];
        Ejecutar: Boolean;
        Resultado: Text;

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.ID := 1;
        Rec.Insert();
    end;
}
