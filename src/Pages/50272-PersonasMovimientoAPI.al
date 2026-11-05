// ════════════════════════════════════════════════════════════════════════════════
// Page 50272 "GJW Personas Movimiento API"
// Operación (singleton, mismo patrón que realizadoPorBackfillOperations) para estampar
// Origen / Encargado / Bodega / Transportista / Digitado por en Movs. producto ya
// registrados. Ver codeunit 50270.
//
// POST .../construction/v1.0/companies(..)/personasMovimientoOperations
//   { "personasJSON": "[{\"documentNo\":\"BE000123\",\"origen\":\"Boletas\",
//       \"encargado\":\"...\",\"bodega\":\"...\",\"transportista\":\"...\"}]",
//     "execute": true }
// → result = JSON por documento: { documentNo, encontrados, actualizados }
// ════════════════════════════════════════════════════════════════════════════════
page 50272 "GJW Personas Movimiento API"
{
    PageType = API;
    Caption = 'Personas Movimiento';
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'personasMovimientoOperation';
    EntitySetName = 'personasMovimientoOperations';
    DelayedInsert = true;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = ID;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                }
                field(personasJSON; PersonasJSON)
                {
                    ApplicationArea = All;
                    Caption = 'Personas JSON';
                    ToolTip = 'Arreglo de objetos { documentNo, entryNos?, itemNo?, postingDate?, origen?, encargado?, bodega?, transportista?, digitadoPor?, sobrescribir? }.';
                }
                field(execute; Ejecutar)
                {
                    ApplicationArea = All;
                    Caption = 'Execute';
                    ToolTip = 'Establecer en true (después de personasJSON) para estampar.';

                    trigger OnValidate()
                    begin
                        if Ejecutar then
                            Procesar();
                    end;
                }
                field(result; ResultMessage)
                {
                    ApplicationArea = All;
                    Caption = 'Result';
                    Editable = false;
                }
                field(success; Success)
                {
                    ApplicationArea = All;
                    Caption = 'Success';
                    Editable = false;
                }
            }
        }
    }

    var
        PersonasJSON: Text;
        Ejecutar: Boolean;
        ResultMessage: Text;
        Success: Boolean;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.ID := 1;
            Rec.Insert();
        end;
    end;

    local procedure Procesar()
    var
        Personas: Codeunit "GJW Personas Movimiento";
    begin
        Success := false;
        ResultMessage := '';
        if not TryEstampar(Personas) then
            ResultMessage := 'Error: ' + GetLastErrorText()
        else
            Success := true;
        Ejecutar := false;
    end;

    [TryFunction]
    local procedure TryEstampar(var Personas: Codeunit "GJW Personas Movimiento")
    begin
        ResultMessage := Personas.Estampar(PersonasJSON);
    end;
}
