tableextension 50133 "GJW Item Journal Line Ext" extends "Item Journal Line"
{
    fields
    {
        field(50100; "Task No."; Code[20])
        {
            Caption = 'Task No.';
            DataClassification = CustomerContent;
        }
    }

    trigger OnBeforeModify()
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // Detectar comando especial en Description
        if Rec.Description = 'REGISTER_BATCH_NOW' then begin
            // Obtener TODAS las líneas del batch
            ItemJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            ItemJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");

            if ItemJnlLine.FindSet() then begin
                // ✅ REGISTRAR (igual que botón BC)
                ItemJnlPostBatch.Run(ItemJnlLine);
                Message('✅ Líneas registradas en Almacén de Obra');
            end;
        end;
    end;
}