page 50128 "Adelante Item Variant API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'itemVariant';
    EntitySetName = 'itemVariants';

    SourceTable = "Item Variant";

    DelayedInsert = true;
    ODataKeyFields = "Item No.", Code;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(itemNumber; Rec."Item No.") { }
                field(code; Rec.Code) { }
                field(description; Rec.Description) { }
            }
        }
    }
}
