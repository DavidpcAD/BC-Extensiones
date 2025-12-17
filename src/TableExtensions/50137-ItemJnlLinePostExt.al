tableextension 50137 "GJW Item Jnl Line Post Ext" extends "Item Journal Line"
{
    fields
    {
        field(50101; "GJW Post This Line"; Boolean)
        {
            Caption = 'Post This Line';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ItemJnlLine: Record "Item Journal Line";
                ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
            begin
                if not Rec."GJW Post This Line" then
                    exit;

                // Obtener TODAS las líneas del MISMO batch
                ItemJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                ItemJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");

                if not ItemJnlLine.FindSet() then
                    Error('No se encontraron líneas para registrar');

                // ✅ REGISTRAR TODAS LAS LÍNEAS DEL BATCH
                ItemJnlPostBatch.Run(ItemJnlLine);

                Message('✅ Líneas registradas en Almacén de Obra');
            end;
        }
    }
}
