// API de Almacenes (tabla Location 14) para que la app de Compras liste los
// almacenes/ubicaciones REALES de BC (la API estándar v2.0 no expone Location).
// Solo lectura — es dato maestro para elegir el almacén de recepción.
page 50234 "Adelante Location API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'location';
    EntitySetName = 'locations';

    SourceTable = Location;

    ODataKeyFields = "Code";
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
                field(Code; Rec.Code) { }
                field(Name; Rec.Name) { }
            }
        }
    }
}
