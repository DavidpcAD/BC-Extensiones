page 50125 "Adelante Item API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'item';
    EntitySetName = 'items';

    SourceTable = Item;

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
                field(No; Rec."No.") { }
                field(Description; Rec.Description) { }
                field(BaseUnitOfMeasure; Rec."Base Unit of Measure") { }
                field(ItemCategoryCode; Rec."Item Category Code") { }

                // 🔥 Permite filtrar existencia por almacén (igual que en BC)
                field(LocationFilter; Rec."Location Filter")
                {
                    Caption = 'Location Filter';
                    Editable = true;
                }

                field(Inventory; Rec.Inventory) { }
                field(UnitPrice; Rec."Unit Price") { }
                field(Blocked; Rec.Blocked) { }

                // Planificación: para faltantes / sugerencia de reorden en el dashboard.
                // Nota: "Minimum Inventory" no es campo estándar del Item; el mínimo lo
                // representa Safety Stock Quantity. Se agrega Reorder Quantity como extra útil.
                field(reorderPoint; Rec."Reorder Point") { Caption = 'Reorder Point'; }
                field(safetyStockQuantity; Rec."Safety Stock Quantity") { Caption = 'Safety Stock Quantity'; }
                field(reorderQuantity; Rec."Reorder Quantity") { Caption = 'Reorder Quantity'; }
            }

        }
    }
}
