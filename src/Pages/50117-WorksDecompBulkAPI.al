page 50117 "GJW WorksDecomp Bulk API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'workDecompBulk';
    EntitySetName = 'workDecompBulks';

    // Obsoleto: usar Codeunit 50114 Import(jsonNuevos, jsonEditados, jsonEliminados)
    ObsoleteState = Pending;
    ObsoleteReason = 'Reemplazado por ServiceEnabled Codeunit 50114 (Import) sin chunks';
    ObsoleteTag = '2026-02-16';

    // Usar buffer temporal propio para transportar JSON
    SourceTable = "GJW Bulk Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = ID;

    // Patrón BULK vía PATCH/POST → OnInsertRecord
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(payload1; Rec.payload1) { Caption = 'payload1'; }
                field(payload2; Rec.payload2) { Caption = 'payload2'; }
                field(payload3; Rec.payload3) { Caption = 'payload3'; }
                field(payload4; Rec.payload4) { Caption = 'payload4'; }
                field(payload5; Rec.payload5) { Caption = 'payload5'; }
                field(payload6; Rec.payload6) { Caption = 'payload6'; }
                field(payload7; Rec.payload7) { Caption = 'payload7'; }
                field(payload8; Rec.payload8) { Caption = 'payload8'; }
                field(payload9; Rec.payload9) { Caption = 'payload9'; }
                field(payload10; Rec.payload10) { Caption = 'payload10'; }
                field(payload11; Rec.payload11) { Caption = 'payload11'; }
                field(payload12; Rec.payload12) { Caption = 'payload12'; }
                field(payload13; Rec.payload13) { Caption = 'payload13'; }
                field(payload14; Rec.payload14) { Caption = 'payload14'; }
                field(payload15; Rec.payload15) { Caption = 'payload15'; }
                field(payload16; Rec.payload16) { Caption = 'payload16'; }
                field(payload17; Rec.payload17) { Caption = 'payload17'; }
                field(payload18; Rec.payload18) { Caption = 'payload18'; }
                field(payload19; Rec.payload19) { Caption = 'payload19'; }
                field(payload20; Rec.payload20) { Caption = 'payload20'; }
                field(payload21; Rec.payload21) { Caption = 'payload21'; }
                field(payload22; Rec.payload22) { Caption = 'payload22'; }
                field(payload23; Rec.payload23) { Caption = 'payload23'; }
                field(payload24; Rec.payload24) { Caption = 'payload24'; }
                field(payload25; Rec.payload25) { Caption = 'payload25'; }
                field(payload26; Rec.payload26) { Caption = 'payload26'; }
                field(payload27; Rec.payload27) { Caption = 'payload27'; }
                field(payload28; Rec.payload28) { Caption = 'payload28'; }
                field(payload29; Rec.payload29) { Caption = 'payload29'; }
                field(payload30; Rec.payload30) { Caption = 'payload30'; }
                field(payload31; Rec.payload31) { Caption = 'payload31'; }
                field(payload32; Rec.payload32) { Caption = 'payload32'; }
                field(payload33; Rec.payload33) { Caption = 'payload33'; }
                field(payload34; Rec.payload34) { Caption = 'payload34'; }
                field(payload35; Rec.payload35) { Caption = 'payload35'; }
                field(payload36; Rec.payload36) { Caption = 'payload36'; }
                field(payload37; Rec.payload37) { Caption = 'payload37'; }
                field(payload38; Rec.payload38) { Caption = 'payload38'; }
                field(payload39; Rec.payload39) { Caption = 'payload39'; }
                field(payload40; Rec.payload40) { Caption = 'payload40'; }
                field(ejecutar; Rec.ejecutar)
                {
                    Caption = 'ejecutar';
                }
                field(resultado; Rec.resultado)
                {
                    Caption = 'resultado';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.resultado := 'API obsoleta: use Codeunit 50114 Import(jsonNuevos,jsonEditados,jsonEliminados).';
        // Mantener compatibilidad si aún se usa ejecutar=true
        if Rec.ejecutar then
            RunBulk();

        exit(true);
    end;

    local procedure RunBulk()
    var
        BulkCU: Codeunit "GJW WorksDecomp Bulk";
        Response: Text;
        FullPayload: Text;
        Obj: JsonObject;
        Tok: JsonToken;
        Arr: JsonArray;
        txtN: Text;
        txtE: Text;
        txtD: Text;
    begin
        FullPayload :=
            Rec.payload1 + Rec.payload2 + Rec.payload3 + Rec.payload4 + Rec.payload5 +
            Rec.payload6 + Rec.payload7 + Rec.payload8 + Rec.payload9 + Rec.payload10 +
            Rec.payload11 + Rec.payload12 + Rec.payload13 + Rec.payload14 + Rec.payload15 +
            Rec.payload16 + Rec.payload17 + Rec.payload18 + Rec.payload19 + Rec.payload20 +
            Rec.payload21 + Rec.payload22 + Rec.payload23 + Rec.payload24 + Rec.payload25 +
            Rec.payload26 + Rec.payload27 + Rec.payload28 + Rec.payload29 + Rec.payload30 +
            Rec.payload31 + Rec.payload32 + Rec.payload33 + Rec.payload34 + Rec.payload35 +
            Rec.payload36 + Rec.payload37 + Rec.payload38 + Rec.payload39 + Rec.payload40;

        if not Obj.ReadFrom(FullPayload) then begin
            // Trazas para diagnóstico: longitud y encabezado del payload
            Rec.resultado :=
                'Error: payload JSON inválido | len=' + Format(StrLen(FullPayload)) +
                ' | head=' + CopyStr(FullPayload, 1, 200);
            exit;
        end;

        // n = nuevos, e = editados, d = eliminados
        txtN := '[]';
        txtE := '[]';
        txtD := '[]';

        if Obj.Get('n', Tok) and Tok.IsArray() then begin
            Arr := Tok.AsArray();
            Arr.WriteTo(txtN);
        end;
        if Obj.Get('e', Tok) and Tok.IsArray() then begin
            Arr := Tok.AsArray();
            Arr.WriteTo(txtE);
        end;
        if Obj.Get('d', Tok) and Tok.IsArray() then begin
            Arr := Tok.AsArray();
            Arr.WriteTo(txtD);
        end;

        Response := BulkCU.Import(txtN, txtE, txtD);
        Rec.resultado := Response;
    end;
}
