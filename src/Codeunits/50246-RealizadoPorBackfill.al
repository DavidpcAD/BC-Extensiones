// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50246 "GJW Realizado Por Backfill"
// Completa "Realizado por" en Job Ledger Entries YA registrados que salieron sin él.
//
// Caso real (cierre fiscal 31-oct-2026): la app de Boletas consumía al proyecto por
// materialConsumptionOperations SIN mandar realizadoPor, así que sus Movs. proyecto
// (Document No. = BExxxxxx) quedaron con el campo en blanco y no se sabía qué encargado
// pidió el material. El handler 50245 solo lo copia al registrar; después ya no hay
// cómo ponerlo. Esto lo completa a posteriori.
//
// Reglas (a propósito estrechas):
//   · Solo llena si el campo está VACÍO: nunca pisa lo que estampó otra app (Digitación,
//     Compras) ni una corrección hecha a mano.
//   · Solo toca el movimiento si su Document No. es el indicado (evita un Entry No. errado).
//   · No toca cantidades, costos, dimensiones ni el "User ID" estándar.
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50246 "GJW Realizado Por Backfill"
{
    Permissions = tabledata "Job Ledger Entry" = rm;

    procedure Backfill(JobLedgerEntryNos: Text; DocumentNo: Code[20]; RealizadoPor: Text[50]): Text
    var
        JobLedgEntry: Record "Job Ledger Entry";
        EntryNoList: List of [Text];
        EntryNoText: Text;
        EntryNo: Integer;
        Arr: JsonArray;
        Row: JsonObject;
        Estado: Text;
        Txt: Text;
    begin
        if JobLedgerEntryNos = '' then
            Error('No se especificaron movimientos de proyecto');
        if DocumentNo = '' then
            Error('Debe especificar el número de documento');
        if RealizadoPor = '' then
            Error('Debe especificar quién lo realizó');

        EntryNoList := JobLedgerEntryNos.Split(',');
        foreach EntryNoText in EntryNoList do
            if Evaluate(EntryNo, EntryNoText.Trim()) then begin
                Clear(Row);
                Row.Add('entryNo', EntryNo);
                if not JobLedgEntry.Get(EntryNo) then
                    Estado := 'no existe'
                else
                    if JobLedgEntry."Document No." <> DocumentNo then
                        Estado := 'otro documento'
                    else
                        if JobLedgEntry."GJW Realizado Por" <> '' then
                            Estado := 'ya tenía'
                        else begin
                            JobLedgEntry."GJW Realizado Por" := RealizadoPor;
                            JobLedgEntry.Modify(false);
                            Estado := 'actualizado';
                        end;
                Row.Add('estado', Estado);
                if JobLedgEntry.Get(EntryNo) then
                    Row.Add('realizadoPor', JobLedgEntry."GJW Realizado Por");
                Arr.Add(Row);
            end;

        Arr.WriteTo(Txt);
        exit(Txt);
    end;
}
