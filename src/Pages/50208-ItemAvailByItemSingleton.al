namespace Adelante.Inventory;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Ledger;

page 50208 "GJW Item Avail By Item Single"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'itemAvailByItemOperation';
    EntitySetName = 'itemAvailByItemOperations';

    SourceTable = "GJW Item Avail By Item Req";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            field(id; Rec.SystemId)
            {
                Caption = 'Id';
                Editable = false;
            }
            field(itemNo; Rec."Item No.")
            {
                Caption = 'Item No.';
            }
            field(variantCode; Rec."Variant Code")
            {
                Caption = 'Variant Code';
            }
            field(locationFilter; Rec."Location Filter")
            {
                Caption = 'Location Filter';
            }
            field(requestId; Rec."Request Id")
            {
                Caption = 'Request Id';
                Editable = false;
            }
            field(status; Rec.Status)
            {
                Caption = 'Status';
                Editable = false;
            }
            field(errorMessage; Rec."Error Message")
            {
                Caption = 'Error Message';
                Editable = false;
            }
            field(resultJson; Rec."Result Json")
            {
                Caption = 'Result JSON';
                Editable = false;
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Item: Record Item;
        RequestGuid: Guid;
        LocationFilter: Text;
        ResultJson: Text;
    begin
        if Rec."Item No." = '' then
            Error('itemNo es requerido');
        if not Item.Get(Rec."Item No.") then
            Error('Item %1 no existe', Rec."Item No.");

        LocationFilter := Rec."Location Filter";
        if LocationFilter = '' then
            LocationFilter := 'ALM*';

        RequestGuid := CreateGuid();
        Rec."Requested At" := CurrentDateTime();
        ResultJson := ProcessAndBuildJson(Rec."Item No.", Rec."Variant Code", LocationFilter, Item."Base Unit of Measure");
        Rec."Request Id" := DelChr(Format(RequestGuid), '=', '{}');
        Rec."Result Json" := CopyStr(ResultJson, 1, MaxStrLen(Rec."Result Json"));
        Rec.Status := 'OK';
        exit(true);
    end;

    local procedure ProcessAndBuildJson(ItemNo: Code[20]; VariantCode: Code[10]; LocationFilter: Text; UnitOfMeasure: Code[10]): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ResultArray: JsonArray;
        ResultObj: JsonObject;
        QtyByLocation: Dictionary of [Text, Decimal];
        LocationOrder: List of [Text];
        LocationCodeTxt: Text;
        LocationNameTxt: Text;
        QtyAvailable: Decimal;
        ResultJsonTxt: Text;
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        if VariantCode <> '' then
            ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetFilter("Location Code", LocationFilter);
        ItemLedgerEntry.SetRange("Posting Date", 0D, Today());

        if ItemLedgerEntry.FindSet() then
            repeat
                LocationCodeTxt := Format(ItemLedgerEntry."Location Code");
                if not QtyByLocation.ContainsKey(LocationCodeTxt) then
                    LocationOrder.Add(LocationCodeTxt);
                AddQty(QtyByLocation, LocationCodeTxt, ItemLedgerEntry.Quantity);
            until ItemLedgerEntry.Next() = 0;

        foreach LocationCodeTxt in LocationOrder do begin
            QtyAvailable := GetQty(QtyByLocation, LocationCodeTxt);
            if QtyAvailable <> 0 then begin
                LocationNameTxt := '';
                if Location.Get(LocationCodeTxt) then
                    LocationNameTxt := Location.Name;

                Clear(ResultObj);
                ResultObj.Add('locationCode', LocationCodeTxt);
                ResultObj.Add('locationName', LocationNameTxt);
                ResultObj.Add('availableQuantity', QtyAvailable);
                ResultObj.Add('unitOfMeasure', UnitOfMeasure);
                ResultArray.Add(ResultObj);
            end;
        end;

        ResultArray.WriteTo(ResultJsonTxt);
        exit(ResultJsonTxt);
    end;

    local procedure AddQty(var QtyByKey: Dictionary of [Text, Decimal]; KeyTxt: Text; QtyToAdd: Decimal)
    var
        CurrentQty: Decimal;
    begin
        if QtyByKey.ContainsKey(KeyTxt) then begin
            QtyByKey.Get(KeyTxt, CurrentQty);
            QtyByKey.Set(KeyTxt, CurrentQty + QtyToAdd);
        end else
            QtyByKey.Add(KeyTxt, QtyToAdd);
    end;

    local procedure GetQty(var QtyByKey: Dictionary of [Text, Decimal]; KeyTxt: Text): Decimal
    var
        Qty: Decimal;
    begin
        if QtyByKey.ContainsKey(KeyTxt) then begin
            QtyByKey.Get(KeyTxt, Qty);
            exit(Qty);
        end;

        exit(0);
    end;
}
