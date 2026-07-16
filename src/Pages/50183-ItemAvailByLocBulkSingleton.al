namespace Adelante.Inventory;

using Microsoft.Inventory.Ledger;

page 50183 "GJW Item Avail Bulk Single"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'itemAvailByLocBulkOperation';
    EntitySetName = 'itemAvailByLocBulkOperations';

    SourceTable = "GJW Item Avail Bulk Request";
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
            field(itemsJson; ItemsJsonText)
            {
                Caption = 'Items JSON';
            }
            field(locationCode; Rec."Location Code")
            {
                Caption = 'Location Code';
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
        ItemsJsonText: Text;
        ResultJsonText: Text;

    trigger OnAfterGetRecord()
    begin
        // Recargar el JSON completo desde el Blob: la respuesta OData del POST
        // re-lee el registro, y sin esto el string saldria vacio en la respuesta.
        ItemsJsonText := LoadItemsJsonBlob();
        ResultJsonText := LoadResultJsonBlob();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        RequestGuid: Guid;
    begin
        if Rec."Location Code" = '' then
            Error('locationCode es requerido');
        if ItemsJsonText = '' then
            Error('itemsJson es requerido');

        RequestGuid := CreateGuid();
        Rec."Requested At" := CurrentDateTime();

        // ItemsJsonText es una variable Text sin longitud: no topa en 2048 al entrar.
        ResultJsonText := ProcessAndBuildJson(ItemsJsonText, Rec."Location Code", RequestGuid);

        Rec."Request Id" := DelChr(Format(RequestGuid), '=', '{}');
        // Persistir en Blob (sin tope de largo) en vez del Text[2048] que truncaba.
        SaveItemsJsonBlob(ItemsJsonText);
        SaveResultJsonBlob(ResultJsonText);
        Rec.Status := 'OK';
        exit(true);
    end;

    local procedure SaveItemsJsonBlob(TextValue: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec."Items Json Blob");
        Rec."Items Json Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(TextValue);
    end;

    local procedure SaveResultJsonBlob(TextValue: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec."Result Json Blob");
        Rec."Result Json Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(TextValue);
    end;

    local procedure LoadItemsJsonBlob(): Text
    var
        InStr: InStream;
        TextValue: Text;
    begin
        Rec.CalcFields("Items Json Blob");
        if not Rec."Items Json Blob".HasValue() then
            exit('');
        Rec."Items Json Blob".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(TextValue);
        exit(TextValue);
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

    local procedure ProcessAndBuildJson(itemsJson: Text; locationCode: Code[10]; RequestGuid: Guid): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemsArray: JsonArray;
        ResultArray: JsonArray;
        ResultObj: JsonObject;
        RequestedSpecific: Dictionary of [Text, Boolean];
        RequestedBlankByItem: Dictionary of [Text, Boolean];
        RequestedItems: Dictionary of [Text, Boolean];
        RequestedOrder: List of [Text];
        OutputKeys: Dictionary of [Text, Boolean];
        QtyByKey: Dictionary of [Text, Decimal];
        ItemNoTxt: Text;
        VariantCodeTxt: Text;
        RequestKey: Text;
        SpecificKey: Text;
        BlankKey: Text;
        FilterItems: Text;
        QtyAvailable: Decimal;
        ResultJsonTxt: Text;
    begin
        if not ItemsArray.ReadFrom(itemsJson) then
            Error('itemsJson invalido. Debe ser un arreglo JSON');

        ParseRequestedItems(ItemsArray, RequestedSpecific, RequestedBlankByItem, RequestedItems, RequestedOrder, OutputKeys);

        if RequestedItems.Count() = 0 then
            exit('[]');

        FilterItems := BuildItemsFilter(RequestedItems);

        ItemLedgerEntry.SetRange("Location Code", locationCode);
        ItemLedgerEntry.SetRange("Posting Date", 0D, Today());
        ItemLedgerEntry.SetFilter("Item No.", FilterItems);
        ItemLedgerEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code");

        if ItemLedgerEntry.FindSet() then
            repeat
                ItemNoTxt := Format(ItemLedgerEntry."Item No.");
                VariantCodeTxt := Format(ItemLedgerEntry."Variant Code");

                SpecificKey := BuildKey(ItemNoTxt, VariantCodeTxt);
                if RequestedSpecific.ContainsKey(SpecificKey) then
                    AddQty(QtyByKey, SpecificKey, ItemLedgerEntry.Quantity);

                if RequestedBlankByItem.ContainsKey(ItemNoTxt) then begin
                    BlankKey := BuildKey(ItemNoTxt, '*');
                    AddQty(QtyByKey, BlankKey, ItemLedgerEntry.Quantity);
                end;
            until ItemLedgerEntry.Next() = 0;

        foreach RequestKey in RequestedOrder do begin
            QtyAvailable := GetQty(QtyByKey, RequestKey);
            ItemNoTxt := GetItemNoFromKey(RequestKey);
            VariantCodeTxt := GetVariantFromKey(RequestKey);

            Clear(ResultObj);
            ResultObj.Add('itemNo', ItemNoTxt);
            ResultObj.Add('variantCode', VariantCodeTxt);
            ResultObj.Add('locationCode', locationCode);
            ResultObj.Add('availableQuantity', QtyAvailable);
            ResultArray.Add(ResultObj);
        end;

        ResultArray.WriteTo(ResultJsonTxt);
        exit(ResultJsonTxt);
    end;

    local procedure ParseRequestedItems(var ItemsArray: JsonArray; var RequestedSpecific: Dictionary of [Text, Boolean]; var RequestedBlankByItem: Dictionary of [Text, Boolean]; var RequestedItems: Dictionary of [Text, Boolean]; var RequestedOrder: List of [Text]; var OutputKeys: Dictionary of [Text, Boolean])
    var
        ItemToken: JsonToken;
        ItemObject: JsonObject;
        ItemNoTxt: Text;
        VariantCodeTxt: Text;
        RequestKey: Text;
        i: Integer;
    begin
        for i := 0 to ItemsArray.Count() - 1 do begin
            if not ItemsArray.Get(i, ItemToken) then
                continue;

            if not ItemToken.IsObject() then
                continue;

            ItemObject := ItemToken.AsObject();
            ItemNoTxt := CopyStr(GetJsonText(ItemObject, 'itemNo'), 1, 20);
            VariantCodeTxt := CopyStr(GetJsonText(ItemObject, 'variantCode'), 1, 10);

            if ItemNoTxt = '' then
                continue;

            if not RequestedItems.ContainsKey(ItemNoTxt) then
                RequestedItems.Add(ItemNoTxt, true);

            if VariantCodeTxt = '' then begin
                if not RequestedBlankByItem.ContainsKey(ItemNoTxt) then
                    RequestedBlankByItem.Add(ItemNoTxt, true);
                RequestKey := BuildKey(ItemNoTxt, '*');
            end else begin
                RequestKey := BuildKey(ItemNoTxt, VariantCodeTxt);
                if not RequestedSpecific.ContainsKey(RequestKey) then
                    RequestedSpecific.Add(RequestKey, true);
            end;

            if not OutputKeys.ContainsKey(RequestKey) then begin
                OutputKeys.Add(RequestKey, true);
                RequestedOrder.Add(RequestKey);
            end;
        end;
    end;

    local procedure BuildItemsFilter(var RequestedItems: Dictionary of [Text, Boolean]): Text
    var
        ItemNoTxt: Text;
        ItemFilter: Text;
    begin
        ItemFilter := '';
        foreach ItemNoTxt in RequestedItems.Keys() do begin
            if ItemFilter <> '' then
                ItemFilter += '|';
            ItemFilter += ItemNoTxt;
        end;

        exit(ItemFilter);
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

    local procedure BuildKey(ItemNoTxt: Text; VariantCodeTxt: Text): Text
    begin
        exit(ItemNoTxt + '|' + VariantCodeTxt);
    end;

    local procedure GetItemNoFromKey(KeyTxt: Text): Text
    var
        SeparatorPos: Integer;
    begin
        SeparatorPos := StrPos(KeyTxt, '|');
        if SeparatorPos = 0 then
            exit(KeyTxt);

        exit(CopyStr(KeyTxt, 1, SeparatorPos - 1));
    end;

    local procedure GetVariantFromKey(KeyTxt: Text): Text
    var
        SeparatorPos: Integer;
        VariantTxt: Text;
    begin
        SeparatorPos := StrPos(KeyTxt, '|');
        if SeparatorPos = 0 then
            exit('');

        VariantTxt := CopyStr(KeyTxt, SeparatorPos + 1);
        if VariantTxt = '*' then
            exit('');

        exit(VariantTxt);
    end;

    local procedure GetJsonText(var JObject: JsonObject; KeyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit('');

        if JToken.AsValue().IsNull() then
            exit('');

        exit(JToken.AsValue().AsText());
    end;
}
