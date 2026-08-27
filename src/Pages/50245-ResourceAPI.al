page 50245 "Adelante Resource API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'resource';
    EntitySetName = 'resources';

    SourceTable = Resource;

    DelayedInsert = true;
    ODataKeyFields = "No.";

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(no; Rec."No.") { Caption = 'No.'; }
                field(name; Rec.Name) { Caption = 'Name'; }
                field(baseUnitOfMeasure; Rec."Base Unit of Measure") { Caption = 'Base Unit of Measure'; }
                field(directUnitCost; Rec."Direct Unit Cost") { Caption = 'Direct Unit Cost'; }
                field(unitCost; Rec."Unit Cost") { Caption = 'Unit Cost'; }
                field(blocked; Rec.Blocked) { Caption = 'Blocked'; }
            }
        }
    }
}