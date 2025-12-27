namespace Adelante.Inventory;

using Microsoft.Inventory.Ledger;

page 50104 "Item Avail by Location API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'itemAvailbyLocation';
    EntitySetName = 'itemsAvailbyLocation';
    SourceTable = ItemAvailLocationBuffer;
    SourceTableTemporary = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(items)
            {
                field(itemNo; Rec.ItemNo)
                {
                    Caption = 'Item No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(locationCode; Rec.LocationCode)
                {
                    Caption = 'Location Code';
                }
                field(totalQuantity; Rec.TotalQuantity)
                {
                    Caption = 'Total Quantity';
                }
                field(remainingQuantity; Rec.RemainingQuantity)
                {
                    Caption = 'Remaining Quantity';
                }
                field(invoicedQuantity; Rec.InvoicedQuantity)
                {
                    Caption = 'Invoiced Quantity';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        PopulateBuffer();
    end;

    local procedure PopulateBuffer()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        Rec.DeleteAll();

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetCurrentKey("Item No.", "Location Code");

        if ItemLedgerEntry.FindSet() then begin
            repeat
                // Buscar si ya existe esta combinación en el buffer
                if not Rec.Get(ItemLedgerEntry."Item No.", ItemLedgerEntry."Location Code") then begin
                    // No existe, crear nuevo
                    Rec.Init();
                    Rec.ItemNo := ItemLedgerEntry."Item No.";
                    Rec.Description := ItemLedgerEntry.Description;
                    Rec.LocationCode := ItemLedgerEntry."Location Code";
                    Rec.TotalQuantity := 0;
                    Rec.RemainingQuantity := 0;
                    Rec.InvoicedQuantity := 0;
                    Rec.Insert();
                end else begin
                    // Existe, actualizar
                    Rec.Modify();
                end;

                // Sumar cantidades al registro actual
                Rec.TotalQuantity += ItemLedgerEntry.Quantity;
                Rec.RemainingQuantity += ItemLedgerEntry."Remaining Quantity";
                Rec.InvoicedQuantity += ItemLedgerEntry."Invoiced Quantity";
                Rec.Modify();

            until ItemLedgerEntry.Next() = 0;
        end;
    end;
}
