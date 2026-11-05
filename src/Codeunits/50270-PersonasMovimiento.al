// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50270 "GJW Personas Movimiento"
// Quién hizo cada Mov. producto (pág. 38), porque el "User ID" estándar es siempre la
// cuenta de servicio (DIGITACION-APP / BUSINESSCENTRAL_API_ADELANTE).
//
// Columnas del ILE (tableext 50135):
//   · Origen         → "Boletas" o "Digitación". Se pone solo al registrar (50157), según
//                      la cuenta que registra; Boletas además por el formato del documento
//                      (BE000123 / BT000045), porque su cuenta la comparte con Compras.
//   · Digitado por   → Digitación: el realizadoPor que manda la app (username), traducido a
//                      nombre con la tabla 50270. Se pone solo al registrar.
//   · Encargado / Bodega / Transportista → Boletas: los estampa la app después de cada paso
//                      con Estampar(), porque el traslado del despacho se registra antes de
//                      que exista transportista o receptor.
//
// Estampar() también sirve para el histórico. Reglas:
//   · Solo toca ILE del Document No. indicado (más los filtros opcionales de ítem, fecha y
//     Nº de movimiento).
//   · Por defecto solo llena campos VACÍOS; con "sobrescribir" reemplaza, pero nunca escribe
//     un valor en blanco encima de uno lleno.
//   · No toca cantidades, costos, dimensiones ni el "User ID".
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50270 "GJW Personas Movimiento"
{
    Permissions = tabledata "Item Ledger Entry" = rm;

    procedure OrigenBoletas(): Text[20]
    begin
        exit('Boletas');
    end;

    procedure OrigenDigitacion(): Text[20]
    begin
        exit('Digitación');
    end;

    // Origen según la cuenta con la que se está registrando.
    procedure OrigenDeLaSesion(DocumentNo: Code[20]): Text[20]
    var
        Usuario: Text;
    begin
        Usuario := UpperCase(UserId());
        if Usuario = 'DIGITACION-APP' then
            exit(OrigenDigitacion());
        if (Usuario = 'BUSINESSCENTRAL_API_ADELANTE') and EsDocumentoBoletas(DocumentNo) then
            exit(OrigenBoletas());
        exit('');
    end;

    // BE000123 (entrega) o BT000045 (traslado): 2 letras + 6 dígitos.
    procedure EsDocumentoBoletas(DocumentNo: Code[20]): Boolean
    var
        Prefijo: Text;
    begin
        if StrLen(DocumentNo) <> 8 then
            exit(false);
        Prefijo := CopyStr(DocumentNo, 1, 2);
        if (Prefijo <> 'BE') and (Prefijo <> 'BT') then
            exit(false);
        exit(DelChr(CopyStr(DocumentNo, 3), '=', '0123456789') = '');
    end;

    // username → nombre completo (tabla 50270). Si no está, devuelve lo mismo que recibió.
    procedure NombreDeUsuario(Usuario: Text): Text[100]
    var
        Mapa: Record "GJW Usuario App Nombre";
    begin
        Usuario := Usuario.Trim();
        if (Usuario <> '') and (StrLen(Usuario) <= MaxStrLen(Mapa.Usuario)) then
            if Mapa.Get(UpperCase(Usuario)) then
                if Mapa.Nombre <> '' then
                    exit(Mapa.Nombre);
        exit(CopyStr(Usuario, 1, 100));
    end;

    // PersonasJSON = arreglo de objetos:
    //   { "documentNo": "BE000123",           (obligatorio)
    //     "entryNos": "301,302",              (opcional: solo esos movimientos)
    //     "itemNo": "M10-0120",               (opcional)
    //     "postingDate": "2026-10-06",        (opcional)
    //     "origen": "Boletas", "encargado": "...", "bodega": "...",
    //     "transportista": "...", "digitadoPor": "...",
    //     "sobrescribir": false }
    // Devuelve un arreglo { documentNo, encontrados, actualizados } (o { documentNo, error }).
    procedure Estampar(PersonasJSON: Text): Text
    var
        Entrada: JsonArray;
        Salida: JsonArray;
        Tok: JsonToken;
        Obj: JsonObject;
        Fila: JsonObject;
        Ile: Record "Item Ledger Entry";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        EntryNos: Text;
        FechaTxt: Text;
        PostingDate: Date;
        Origen: Text[20];
        Encargado: Text[100];
        Bodega: Text[100];
        Transportista: Text[100];
        DigitadoPor: Text[100];
        Sobrescribir: Boolean;
        Encontrados: Integer;
        Actualizados: Integer;
        Cambio: Boolean;
        Txt: Text;
    begin
        if not Entrada.ReadFrom(PersonasJSON) then
            Error('JSON inválido: se espera un arreglo de objetos');

        foreach Tok in Entrada do begin
            Clear(Fila);
            if not Tok.IsObject() then begin
                Fila.Add('error', 'Elemento del arreglo no es un objeto');
                Salida.Add(Fila);
                continue;
            end;
            Obj := Tok.AsObject();

            DocumentNo := CopyStr(LeerTexto(Obj, 'documentNo'), 1, MaxStrLen(DocumentNo));
            Fila.Add('documentNo', DocumentNo);
            if DocumentNo = '' then begin
                Fila.Add('error', 'documentNo es obligatorio');
                Salida.Add(Fila);
                continue;
            end;

            ItemNo := CopyStr(LeerTexto(Obj, 'itemNo'), 1, MaxStrLen(ItemNo));
            EntryNos := DelChr(LeerTexto(Obj, 'entryNos'), '=', ' ');
            FechaTxt := LeerTexto(Obj, 'postingDate');
            Clear(PostingDate);
            if FechaTxt <> '' then
                if not Evaluate(PostingDate, FechaTxt, 9) then begin
                    Fila.Add('error', 'postingDate inválida (usar AAAA-MM-DD)');
                    Salida.Add(Fila);
                    continue;
                end;
            if (EntryNos <> '') and (DelChr(EntryNos, '=', '0123456789,') <> '') then begin
                Fila.Add('error', 'entryNos inválido (números separados por coma)');
                Salida.Add(Fila);
                continue;
            end;

            Origen := CopyStr(LeerTexto(Obj, 'origen'), 1, MaxStrLen(Origen));
            Encargado := CopyStr(LeerTexto(Obj, 'encargado'), 1, MaxStrLen(Encargado));
            Bodega := CopyStr(LeerTexto(Obj, 'bodega'), 1, MaxStrLen(Bodega));
            Transportista := CopyStr(LeerTexto(Obj, 'transportista'), 1, MaxStrLen(Transportista));
            DigitadoPor := CopyStr(LeerTexto(Obj, 'digitadoPor'), 1, MaxStrLen(DigitadoPor));
            Sobrescribir := LowerCase(LeerTexto(Obj, 'sobrescribir')) = 'true';

            Ile.Reset();
            Ile.SetRange("Document No.", DocumentNo);
            if ItemNo <> '' then
                Ile.SetRange("Item No.", ItemNo);
            if PostingDate <> 0D then
                Ile.SetRange("Posting Date", PostingDate);
            if EntryNos <> '' then
                Ile.SetFilter("Entry No.", ConvertStr(EntryNos.TrimEnd(','), ',', '|'));

            Encontrados := 0;
            Actualizados := 0;
            if Ile.FindSet(true) then
                repeat
                    Encontrados += 1;
                    Cambio := false;
                    if (Origen <> '') and ((Ile."GJW Origen" = '') or Sobrescribir) and (Ile."GJW Origen" <> Origen) then begin
                        Ile."GJW Origen" := Origen;
                        Cambio := true;
                    end;
                    if (Encargado <> '') and ((Ile."GJW Encargado" = '') or Sobrescribir) and (Ile."GJW Encargado" <> Encargado) then begin
                        Ile."GJW Encargado" := Encargado;
                        Cambio := true;
                    end;
                    if (Bodega <> '') and ((Ile."GJW Bodega" = '') or Sobrescribir) and (Ile."GJW Bodega" <> Bodega) then begin
                        Ile."GJW Bodega" := Bodega;
                        Cambio := true;
                    end;
                    if (Transportista <> '') and ((Ile."GJW Transportista" = '') or Sobrescribir) and (Ile."GJW Transportista" <> Transportista) then begin
                        Ile."GJW Transportista" := Transportista;
                        Cambio := true;
                    end;
                    if (DigitadoPor <> '') and ((Ile."GJW Digitado Por" = '') or Sobrescribir) and (Ile."GJW Digitado Por" <> DigitadoPor) then begin
                        Ile."GJW Digitado Por" := DigitadoPor;
                        Cambio := true;
                    end;
                    if Cambio then begin
                        Ile.Modify(false);
                        Actualizados += 1;
                    end;
                until Ile.Next() = 0;

            Fila.Add('encontrados', Encontrados);
            Fila.Add('actualizados', Actualizados);
            Salida.Add(Fila);
        end;

        Salida.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure LeerTexto(Obj: JsonObject; Nombre: Text): Text
    var
        Tok: JsonToken;
    begin
        if not Obj.Get(Nombre, Tok) then
            exit('');
        if not Tok.IsValue() then
            exit('');
        if Tok.AsValue().IsNull() then
            exit('');
        exit(Tok.AsValue().AsText().Trim());
    end;
}
