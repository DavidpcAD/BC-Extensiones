// ════════════════════════════════════════════════════════════════════════════════
// Page 50242 "Adelante No Series API"
// Propósito: Deja LEER en qué número va una serie de numeración de BC (No. Series
//            Line). La app de Órdenes de Compra necesita saber por dónde va el
//            contador de las órdenes para no arrancar un conteo propio.
// Endpoint : /api/adelante/purchasing/v1.0/companies(<id>)/noSeriesLines
// Uso      : la serie que usa cada documento sale de purchasesSetups (page 50243).
//   ?$filter=seriesCode eq 'P-ORD'
//   lastNoUsed = el último número que BC entregó de esa serie.
// OJO      : es SOLO LECTURA. Leer no reserva ni consume el número: el que asigna
//            es BC cuando se crea el documento. Dos series avanzando por su cuenta
//            (la de BC y una copia en la app) terminarían pisándose.
// ════════════════════════════════════════════════════════════════════════════════
page 50242 "Adelante No Series API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'purchasing';
    APIVersion = 'v1.0';
    EntityName = 'noSeriesLine';
    EntitySetName = 'noSeriesLines';
    SourceTable = "No. Series Line";
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(seriesCode; Rec."Series Code")
                {
                    Caption = 'Series Code';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    Editable = false;
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                    Editable = false;
                }
                field(startingNo; Rec."Starting No.")
                {
                    Caption = 'Starting No.';
                    Editable = false;
                }
                field(endingNo; Rec."Ending No.")
                {
                    Caption = 'Ending No.';
                    Editable = false;
                }
                field(lastNoUsed; Rec."Last No. Used")
                {
                    Caption = 'Last No. Used';
                    Editable = false;
                }
                field(incrementByNo; Rec."Increment-by No.")
                {
                    Caption = 'Increment-by No.';
                    Editable = false;
                }
                field(lastDateUsed; Rec."Last Date Used")
                {
                    Caption = 'Last Date Used';
                    Editable = false;
                }
                field(warningNo; Rec."Warning No.")
                {
                    Caption = 'Warning No.';
                    Editable = false;
                }
                field(open; Rec.Open)
                {
                    Caption = 'Open';
                    Editable = false;
                }
            }
        }
    }
}
