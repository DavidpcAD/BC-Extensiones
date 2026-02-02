tableextension 50137 "GJW Item Jnl Line Post Ext" extends "Item Journal Line"
{
    fields
    {
        field(50105; "GJW Post This Line"; Boolean)
        {
            Caption = 'Post This Line';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ItemJnlLine: Record "Item Journal Line";
                LineCount: Integer;
                ErrorText: Text;
            begin
                if not Rec."GJW Post This Line" then
                    exit;

                // Obtener TODAS las líneas del MISMO batch
                ItemJnlLine.Reset();
                ItemJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                ItemJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");

                if not ItemJnlLine.FindSet() then
                    Error('No se encontraron líneas para registrar en batch %1', Rec."Journal Batch Name");

                // Contar líneas antes de registrar
                LineCount := ItemJnlLine.Count();

                // 🛡️ Validar límite de líneas (prevenir timeouts)
                if LineCount > 200 then
                    Error('❌ Demasiadas líneas (%1). Máximo permitido: 200. Divida en batches más pequeños.', LineCount);

                // ✅ REGISTRAR TODAS LAS LÍNEAS DEL BATCH CON MANEJO DE ERRORES
                Commit(); // Asegurar que no hay transacciones pendientes

                if not Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJnlLine) then begin
                    ErrorText := GetLastErrorText();
                    ClearLastError();
                    Rec."GJW Post This Line" := false; // Resetear el flag
                    Rec.Modify(true);
                    Error('❌ Error al registrar líneas en Almacén de Obra: %1', ErrorText);
                end;

                // Verificar que todas las líneas se registraron
                ItemJnlLine.Reset();
                ItemJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                ItemJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");

                if ItemJnlLine.FindFirst() then begin
                    Rec."GJW Post This Line" := false;
                    Rec.Modify(true);
                    Error('❌ Posting parcial: Quedan %1 de %2 líneas sin registrar', ItemJnlLine.Count(), LineCount);
                end;

                Message('✅ %1 líneas registradas en Almacén de Obra', LineCount);

                // Resetear el flag
                Rec."GJW Post This Line" := false;
                Rec.Modify(true);
            end;
        }
    }
}
