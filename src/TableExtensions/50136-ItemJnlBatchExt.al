tableextension 50136 "GJW Item Jnl Batch Ext" extends "Item Journal Batch"
{
    fields
    {
        field(50099; "GJW ID Colaborador"; Code[20])
        {
            Caption = 'ID Colaborador';
            DataClassification = CustomerContent;
        }

        field(50100; "GJW Trigger Post"; Boolean)
        {
            Caption = 'Trigger Post';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ItemJnlLine: Record "Item Journal Line";
                LineCount: Integer;
                ErrorText: Text;
            begin
                if not Rec."GJW Trigger Post" then
                    exit;

                // Obtener líneas del batch
                ItemJnlLine.Reset();
                ItemJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                ItemJnlLine.SetRange("Journal Batch Name", Rec.Name);

                if not ItemJnlLine.FindSet() then
                    Error('❌ No hay líneas para registrar en batch: %1', Rec.Name);

                // Contar líneas antes de registrar
                LineCount := ItemJnlLine.Count();

                // 🛡️ Validar límite de líneas (prevenir timeouts)
                if LineCount > 200 then
                    Error('❌ Demasiadas líneas (%1). Máximo permitido: 200. Divida en batches más pequeños.', LineCount);

                // ✅ EJECUTAR POSTING CON MANEJO DE ERRORES
                // Esto registra TODAS las líneas del diario y:
                // 1. Crea Item Ledger Entries
                // 2. Dispara Event Subscriber 50157 que copia Task No.
                // 3. Dispara Event Subscriber 50157 que crea Warehouse Quantity
                // 4. Transfiere materiales al almacén de obra
                Commit(); // Asegurar que no hay transacciones pendientes

                if not Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJnlLine) then begin
                    ErrorText := GetLastErrorText();
                    ClearLastError();
                    Rec."GJW Trigger Post" := false; // Resetear el flag
                    Rec.Modify(true);
                    Error('❌ Error al registrar batch %1: %2', Rec.Name, ErrorText);
                end;

                // Verificar que todas las líneas se registraron
                ItemJnlLine.Reset();
                ItemJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                ItemJnlLine.SetRange("Journal Batch Name", Rec.Name);

                if ItemJnlLine.FindFirst() then begin
                    Rec."GJW Trigger Post" := false;
                    Rec.Modify(true);
                    Error('❌ Posting parcial: Quedan %1 de %2 líneas sin registrar', ItemJnlLine.Count(), LineCount);
                end;

                // Commit para asegurar que el posting se completó
                Commit();

                // Mostrar mensaje de éxito
                Message('✅ Registradas %1 líneas del batch %2' + '\' + 'Materiales transferidos al Almacén de Obra', LineCount, Rec.Name);

                // Resetear el flag
                Rec."GJW Trigger Post" := false;
                Rec.Modify(true);
            end;
        }
    }
}
