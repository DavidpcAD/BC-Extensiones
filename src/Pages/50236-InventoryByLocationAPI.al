namespace Adelante.Inventory;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Item;

// ════════════════════════════════════════════════════════════════════════════════
// Page 50236 "Adelante Inventory by Location API"
// Existencias NETAS por ítem + variante + ubicación (SUM de TODOS los movimientos del
// Item Ledger = inventario físico actual). Pensada para LISTAR (no chequeo de celda):
//   - todos los ítems de una obra  -> filtrar solo por locationCode
//   - todas las ubicaciones de un ítem -> filtrar solo por itemNo
// Filtros opcionales, pero se exige al menos uno (itemNo y/o locationCode) para no
// barrer todo el catálogo.
//   GET api/adelante/inventory/v1.0/inventoryByLocation?$filter=locationCode eq 'OR-4321'
//   GET api/adelante/inventory/v1.0/inventoryByLocation?$filter=itemNo eq 'M01-0001'
// ════════════════════════════════════════════════════════════════════════════════
page 50236 "Adelante Inventory by Location"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'inventoryByLocation';
    EntitySetName = 'inventoryByLocation';
    SourceTable = ItemAvailLocationBuffer;
    SourceTableTemporary = true;
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
                field(itemNo; Rec.ItemNo) { Caption = 'Item No.'; }
                field(variantCode; Rec.VariantCode) { Caption = 'Variant Code'; }
                field(locationCode; Rec.LocationCode) { Caption = 'Location Code'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(quantityOnHand; Rec.TotalQuantity) { Caption = 'Quantity On Hand'; }
                field(unitOfMeasure; Rec.UnitOfMeasure) { Caption = 'Unit of Measure'; }
            }
        }
    }

    var
        ItemNoFilter: Text;
        VariantCodeFilter: Text;
        LocationCodeFilter: Text;

    trigger OnOpenPage()
    begin
        ItemNoFilter := Rec.GetFilter(ItemNo);
        VariantCodeFilter := Rec.GetFilter(VariantCode);
        LocationCodeFilter := Rec.GetFilter(LocationCode);
        PopulateBuffer();
    end;

    local procedure PopulateBuffer()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        // Se exige al menos un filtro (ítem y/o ubicación) para no barrer todo el catálogo.
        if (ItemNoFilter = '') and (LocationCodeFilter = '') then
            exit;

        if ItemNoFilter <> '' then
            ItemLedgerEntry.SetFilter("Item No.", ItemNoFilter);
        if VariantCodeFilter <> '' then
            ItemLedgerEntry.SetFilter("Variant Code", VariantCodeFilter);
        if LocationCodeFilter <> '' then
            ItemLedgerEntry.SetFilter("Location Code", LocationCodeFilter);
        ItemLedgerEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code");

        if ItemLedgerEntry.FindSet() then
            repeat
                if not Rec.Get(ItemLedgerEntry."Item No.", ItemLedgerEntry."Variant Code", ItemLedgerEntry."Location Code") then begin
                    Rec.Init();
                    Rec.ItemNo := ItemLedgerEntry."Item No.";
                    Rec.VariantCode := ItemLedgerEntry."Variant Code";
                    Rec.LocationCode := ItemLedgerEntry."Location Code";
                    if Item.Get(ItemLedgerEntry."Item No.") then begin
                        Rec.Description := Item.Description;
                        Rec.UnitOfMeasure := Item."Base Unit of Measure";
                    end;
                    Rec.TotalQuantity := 0;
                    Rec.Insert();
                end;
                Rec.TotalQuantity += ItemLedgerEntry.Quantity; // neto físico = suma de todos los movimientos
                Rec.Modify();
            until ItemLedgerEntry.Next() = 0;
    end;
}
