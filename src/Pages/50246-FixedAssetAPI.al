page 50246 "Adelante Fixed Asset API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'fixedAsset';
    EntitySetName = 'fixedAssets';

    SourceTable = "Fixed Asset";

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
                field(description; Rec.Description) { Caption = 'Description'; }
                field(blocked; Rec.Inactive) { Caption = 'Inactive'; }
            }
        }
    }
}