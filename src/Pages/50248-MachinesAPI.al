// ════════════════════════════════════════════════════════════════════════════════
// Page 50248 "Adelante Machine API"
// El PARQUE DE MAQUINARIA (GomEqp Machine, tabla 71950576 de Goom Parque Maquinaria)
// para que la app de compras pueda elegir A QUÉ MÁQUINA va el repuesto en cada línea
// del pedido. El N.º que se escoge acá es el que termina en
// Purchase Line."GomEqp Machine No.", y es lo que le da dueño al gasto en BC.
//
// Por qué existiendo ya el web service OData "Tarjetas_Maquinaria": ese expone la
// PÁGINA de la tarjeta completa, con los FlowFields de costos y ventas (Machine Costs
// y Machine Sales son sum() sobre G/L Entry). BC los calcula fila por fila y la
// llamada tarda ~70 s — la app tuvo que cachearla para ser usable. Acá van SOLO los
// cinco campos que la app necesita para pintar el selector, ninguno calculado, y la
// respuesta es inmediata.
//
// Solo lectura: el parque lo mantiene Maquinaria en BC, no esta app.
//
//   GET api/adelante/inventory/v1.0/companies({id})/machines
//       ?$filter=blocked eq false
// ════════════════════════════════════════════════════════════════════════════════
page 50248 "Adelante Machine API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'machine';
    EntitySetName = 'machines';
    SourceTable = "GomEqp Machine";
    ODataKeyFields = "No.";
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
                field(no; Rec."No.") { Caption = 'No.'; }
                field(name; Rec.Name) { Caption = 'Name'; }
                // La placa es como el mecánico y el chofer llaman a la máquina: sin
                // ella el selector muestra códigos que en el taller nadie usa.
                field(licensePlate; Rec."License Plate") { Caption = 'License Plate'; }
                field(noSeries; Rec."No. Series") { Caption = 'No. Series'; }
                // Bloqueada = dada de baja o fuera de servicio. Se manda para que la
                // app la esconda del selector; no se filtra acá porque una orden vieja
                // sí puede apuntar a una máquina ya bloqueada y hay que poder leerla.
                field(blocked; Rec.Blocked) { Caption = 'Blocked'; }
            }
        }
    }
}
