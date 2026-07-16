// ════════════════════════════════════════════════════════════════════════════════
// Page 50237 "Adelante Item Charge API"
// Lista los Cargos de producto (Item Charge, tabla 5800) para que la app de compras
// pueble el selector al crear una línea de tipo "Cargo (Prod.)" (Transporte, Servicio
// de corte, Impuestos Exterior, etc.). Solo lectura.
//   GET api/adelante/purchasing/v1.0/itemCharges
// ════════════════════════════════════════════════════════════════════════════════
page 50237 "Adelante Item Charge API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'purchasing';
    APIVersion = 'v1.0';
    EntityName = 'itemCharge';
    EntitySetName = 'itemCharges';
    SourceTable = "Item Charge";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
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
                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group") { Caption = 'Gen. Prod. Posting Group'; }
                field(vatProdPostingGroup; Rec."VAT Prod. Posting Group") { Caption = 'VAT Prod. Posting Group'; }
            }
        }
    }
}
