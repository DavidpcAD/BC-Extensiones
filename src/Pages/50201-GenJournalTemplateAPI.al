page 50201 "GJW Gen. Journal Template API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'finance';
    APIVersion = 'v1.0';
    EntityName = 'genJournalTemplate';
    EntitySetName = 'genJournalTemplates';

    SourceTable = "Gen. Journal Template";
    ODataKeyFields = Name;
    DelayedInsert = true;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Main)
            {
                field(name; Rec.Name) { Caption = 'Name'; ApplicationArea = All; }
                field(description; Rec.Description) { Caption = 'Description'; ApplicationArea = All; }
                field(templateType; Rec.Type) { Caption = 'Type'; ApplicationArea = All; }
                field(recurring; Rec.Recurring) { Caption = 'Recurring'; ApplicationArea = All; }
            }
        }
    }
}
