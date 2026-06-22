// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50223 "GJW Purch Posting Preview"
// Propósito: Ejecutar la VISTA PREVIA (Preview Posting) de un Pedido de Compra de
//            forma "headless" (sin UI) y capturar los asientos que se generarían
//            (G/L Entry, VAT Entry, Item Ledger Entry, Value Entry, Vendor Ledger
//            Entry, etc.) serializándolos a JSON.
//
// Mecánica: Es el mismo motor que usa el botón "Vista previa" de BC:
//   1. Purch.-Post (Yes/No).Preview() corre el posting en modo preview (rollback).
//   2. El framework dispara Gen. Jnl.-Post Preview.OnBeforeShowAllEntries justo
//      antes de mostrar la página 99 "Posting Preview".
//   3. Aquí interceptamos ese evento, leemos los asientos temporales vía
//      Posting Preview Event Handler.GetEntries(), los pasamos a JSON y ponemos
//      IsHandled := true para suprimir la página (no hay UI en una API).
//
// Uso (desde codeunit 50199):
//   BindSubscription(PreviewHandler);
//   PreviewHandler.RunPreview(PurchHeader);
//   JsonResult := PreviewHandler.GetEntries();
//   UnbindSubscription(PreviewHandler);
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50223 "GJW Purch Posting Preview"
{
    EventSubscriberInstance = Manual;

    var
        EntriesArray: JsonArray;
        Captured: Boolean;

    /// <summary>Corre la vista previa del pedido. Llamar con la suscripción ya enlazada.</summary>
    procedure RunPreview(var PurchHeader: Record "Purchase Header")
    var
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
    begin
        Clear(EntriesArray);
        Captured := false;
        // Dispara el flujo de preview estándar; el resultado se captura en el evento.
        PurchPostYesNo.Preview(PurchHeader);
    end;

    /// <summary>Devuelve el arreglo JSON con los grupos de asientos capturados.</summary>
    procedure GetEntries(): JsonArray
    begin
        exit(EntriesArray);
    end;

    /// <summary>Indica si se capturaron asientos (preview exitosa).</summary>
    procedure HasCapturedEntries(): Boolean
    begin
        exit(Captured);
    end;

    // ─── Intercepta los asientos justo antes de que se muestre la página de preview ───
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnBeforeShowAllEntries', '', false, false)]
    local procedure HandleOnBeforeShowAllEntries(var TempDocumentEntry: Record "Document Entry" temporary; var IsHandled: Boolean; var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    var
        RecRef: RecordRef;
        GroupObj: JsonObject;
        RowsArray: JsonArray;
    begin
        Clear(EntriesArray);

        if TempDocumentEntry.FindSet() then
            repeat
                Clear(RecRef);
                PostingPreviewEventHandler.GetEntries(TempDocumentEntry."Table ID", RecRef);

                Clear(RowsArray);
                SerializeRecordSet(RecRef, RowsArray);

                Clear(GroupObj);
                GroupObj.Add('tableId', TempDocumentEntry."Table ID");
                GroupObj.Add('tableName', TempDocumentEntry."Table Name");
                GroupObj.Add('count', TempDocumentEntry."No. of Records");
                GroupObj.Add('entries', RowsArray);
                EntriesArray.Add(GroupObj);
            until TempDocumentEntry.Next() = 0;

        Captured := true;
        IsHandled := true; // suprime la página 99 (sin UI en API)
    end;

    // ─── Serializa todos los registros de un RecordRef a un arreglo JSON ───
    local procedure SerializeRecordSet(var RecRef: RecordRef; var RowsArray: JsonArray)
    var
        FldRef: FieldRef;
        RowObj: JsonObject;
        i: Integer;
        ValTxt: Text;
    begin
        if RecRef.Number = 0 then
            exit;

        if RecRef.FindSet() then
            repeat
                Clear(RowObj);
                for i := 1 to RecRef.FieldCount do begin
                    FldRef := RecRef.FieldIndex(i);
                    if FldRef.Class = FieldClass::Normal then
                        if TryGetFieldText(FldRef, ValTxt) then
                            if not IsEmptyValue(ValTxt) then
                                RowObj.Add(FldRef.Name, ValTxt);
                end;
                RowsArray.Add(RowObj);
            until RecRef.Next() = 0;
    end;

    // Protegido: BLOB/Media/RecordId no se pueden formatear directamente -> se omiten.
    [TryFunction]
    local procedure TryGetFieldText(FldRef: FieldRef; var ValTxt: Text)
    begin
        ValTxt := Format(FldRef.Value, 0, 9); // formato XML/invariante
    end;

    local procedure IsEmptyValue(ValTxt: Text): Boolean
    begin
        case ValTxt of
            '', '0', '00000000-0000-0000-0000-000000000000', '0001-01-01':
                exit(true);
        end;
        exit(false);
    end;
}
