tableextension 50136 "GJW Item Jnl Batch Ext" extends "Item Journal Batch"
{
    fields
    {
        field(50100; "GJW Trigger Post"; Boolean)
        {
            Caption = 'Trigger Post';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ItemJnlLine: Record "Item Journal Line";
                ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
                LineCount: Integer;
            begin
                if not Rec."GJW Trigger Post" then
                    exit;

                // Obtener líneas del batch
                ItemJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                ItemJnlLine.SetRange("Journal Batch Name", Rec.Name);

                if not ItemJnlLine.FindSet() then
                    Error('❌ No hay líneas para registrar en batch: %1', Rec.Name);

                // Contar líneas antes de registrar
                LineCount := ItemJnlLine.Count();

                // ✅ EJECUTAR MISMO POSTING QUE BOTÓN "REGISTRAR" DE BC
                // Esto registra TODAS las líneas del diario y:
                // 1. Crea Item Ledger Entries
                // 2. Dispara Event Subscriber 50157 que copia Task No.
                // 3. Dispara Event Subscriber 50157 que crea Warehouse Quantity
                // 4. Transfiere materiales al almacén de obra
                ItemJnlPostBatch.Run(ItemJnlLine);

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
