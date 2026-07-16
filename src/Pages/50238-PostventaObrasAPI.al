// ════════════════════════════════════════════════════════════════════════════════
// Page 50238 "Adelante Postventa Obras API"
// Lista las obras Postventa (GomJob Works cuyo No. empieza con "PV-") para que la app
// muestre el selector "¿a qué Postventa va la actividad?" al bloquear una obra.
//   GET api/adelante/project/v1.0/companies({id})/postventaObras
// ════════════════════════════════════════════════════════════════════════════════
page 50238 "Adelante Postventa Obras API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'project';
    APIVersion = 'v1.0';
    EntityName = 'postventaObra';
    EntitySetName = 'postventaObras';
    SourceTable = "GomJob Works";
    SourceTableView = where("No." = filter('PV-*'));
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(no; Rec."No.") { Caption = 'No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
            }
        }
    }
}
