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
            field(asOfDate; Rec."As Of Date")
            {
                Caption = 'As Of Date';
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
            field(resultJson; ResultJsonText)
            {
                Caption = 'Result JSON';
                Editable = false;
            }
        }
    }

    var
        ResultJsonText: Text;

    trigger OnAfterGetRecord()
    begin
        // Recargar el JSON completo desde el Blob: la respuesta OData del POST
        // re-lee el registro, y sin esto el string saldria vacio en la respuesta.
        ResultJsonText := LoadResultJsonBlob();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Item: Record Item;
        RequestGuid: Guid;
        LocationFilter: Text;
        AsOfDate: Date;
    begin
        if Rec."Item No." = '' then
            Error('itemNo es requerido');
        if not Item.Get(Rec."Item No.") then
            Error('Item %1 no existe', Rec."Item No.");

        LocationFilter := Rec."Location Filter";
        if LocationFilter = '' then
            LocationFilter := 'ALM*';

        AsOfDate := Rec."As Of Date";
        if AsOfDate = 0D then
            AsOfDate := Today();

        RequestGuid := CreateGuid();
        Rec."Requested At" := CurrentDateTime();
        ResultJsonText := ProcessAndBuildJson(Rec."Item No.", Rec."Variant Code", LocationFilter, AsOfDate, Item."Base Unit of Measure");
        Rec."Request Id" := DelChr(Format(RequestGuid), '=', '{}');
        // Persistir en Blob (sin tope de largo) en vez del Text[2048] que truncaba.
        SaveResultJsonBlob(ResultJsonText);
        Rec.Status := 'OK';
        exit(true);
    end;

    local procedure SaveResultJsonBlob(TextValue: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec."Result Json Blob");
        Rec."Result Json Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(TextValue);
    end;

    local procedure LoadResultJsonBlob(): Text
    var
        InStr: InStream;
        TextValue: Text;
    begin
        // El JSON de JsonArray.WriteTo es compacto (una sola linea), asi que
        // un unico ReadText devuelve el contenido completo del Blob.
        Rec.CalcFields("Result Json Blob");
        if not Rec."Result Json Blob".HasValue() then
            exit('');
        Rec."Result Json Blob".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(TextValue);
        exit(TextValue);
    end;

    local procedure ProcessAndBuildJson(ItemNo: Code[20]; VariantCode: Code[10]; LocationFilter: Text; AsOfDate: Date; UnitOfMeasure: Code[10]): Text
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
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetFilter("Location Code", LocationFilter);
        ItemLedgerEntry.SetRange("Posting Date", 0D, AsOfDate);

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
