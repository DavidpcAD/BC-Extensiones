page 50170 "GJW Job API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'project';
    APIVersion = 'v1.0';
    EntityName = 'job';
    EntitySetName = 'jobs';

    SourceTable = Job;
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(no; Rec."No.") { Caption = 'No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(idEncargado; Rec."ID Encargado") { Caption = 'ID Encargado'; ObsoleteState = Pending; }
                field(idEncargadoText; Rec."ID Encargado Text") { Caption = 'ID Encargado'; }
                field(personResponsible; Rec."Person Responsible") { Caption = 'Person Responsible'; }
                field(status; Rec.Status) { Caption = 'Status'; }
                field(creationDate; Rec."Creation Date") { Caption = 'Creation Date'; }
                field(startingDate; Rec."Starting Date") { Caption = 'Starting Date'; }
                field(endingDate; Rec."Ending Date") { Caption = 'Ending Date'; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }
            }
        }
    }
}
