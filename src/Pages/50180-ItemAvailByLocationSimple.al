namespace Adelante.Inventory;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Ledger;

page 50180 "Item Avail. by Location Simple"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'itemAvailbyLocationSimple';
    EntitySetName = 'itemAvailbyLocationSimple';
    SourceTable = ItemAvailLocationBuffer;
    SourceTableTemporary = true;
    Editable = false;
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
                field(description; ItemDescription)
                {
                    Caption = 'Description';
                }
                field(locationCode; Rec.LocationCode)
                {
                    Caption = 'Location Code';
                }
                field(locationName; LocationName)
                {
                    Caption = 'Location Name';
                }
                field(availableQuantity; Rec.TotalQuantity)
                {
                    Caption = 'Inventory';
                }
                field(unitOfMeasure; UnitOfMeasure)
                {
                    Caption = 'Unit of Measure';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        PopulateBuffer();
    end;

    trigger OnAfterGetRecord()
    begin
        GetLocationName();
        GetItemDescription();
        GetUnitOfMeasure();
    end;

    var
        LocationName: Text[100];
        ItemDescription: Text[100];
        UnitOfMeasure: Code[10];

    local procedure PopulateBuffer()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempBuffer: Record ItemAvailLocationBuffer temporary;
    begin
        Rec.DeleteAll();

        ItemLedgerEntry.SetRange("Posting Date", 0D, Today());
        ItemLedgerEntry.SetCurrentKey("Item No.", "Location Code");

        if ItemLedgerEntry.FindSet() then begin
            repeat
                if not TempBuffer.Get(ItemLedgerEntry."Item No.", ItemLedgerEntry."Location Code") then begin
                    TempBuffer.Init();
                    TempBuffer.ItemNo := ItemLedgerEntry."Item No.";
                    TempBuffer.LocationCode := ItemLedgerEntry."Location Code";
                    TempBuffer.TotalQuantity := 0;
                    TempBuffer.Insert();
                end;

                TempBuffer.TotalQuantity += ItemLedgerEntry.Quantity;
                TempBuffer.Modify();
            until ItemLedgerEntry.Next() = 0;
        end;

        if TempBuffer.FindSet() then begin
            repeat
                Rec := TempBuffer;
                Rec.Insert();
            until TempBuffer.Next() = 0;
        end;
    end;

    local procedure GetLocationName()
    var
        Location: Record Location;
    begin
        LocationName := '';
        if Location.Get(Rec.LocationCode) then
            LocationName := Location.Name;
    end;

    local procedure GetItemDescription()
    var
        Item: Record Item;
    begin
        ItemDescription := '';
        if Item.Get(Rec.ItemNo) then
            ItemDescription := Item.Description;
    end;

    local procedure GetUnitOfMeasure()
    var
        Item: Record Item;
    begin
        UnitOfMeasure := '';
        if Item.Get(Rec.ItemNo) then
            UnitOfMeasure := Item."Base Unit of Measure";
    end;


}
