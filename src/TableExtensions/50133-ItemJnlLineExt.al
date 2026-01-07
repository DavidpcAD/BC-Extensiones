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

    trigger OnBeforeInsert()
    begin
        // 🛡️ Limpiar Variant Code vacío antes de insertar
        CleanEmptyVariantCode();
    end;

    trigger OnBeforeModify()
    var
        ItemJnlLine: Record "Item Journal Line";
        ErrorText: Text;
    begin
        // 🛡️ Limpiar Variant Code vacío antes de modificar
        CleanEmptyVariantCode();

        // Detectar comando especial en Description para auto-posting
        if Rec.Description = 'REGISTER_BATCH_NOW' then begin
            // Obtener TODAS las líneas del batch
            ItemJnlLine.Reset();
            ItemJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            ItemJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");

            if not ItemJnlLine.FindSet() then
                Error('No se encontraron líneas para registrar en batch %1', Rec."Journal Batch Name");

            // ✅ REGISTRAR con manejo de errores
            Commit(); // Asegurar que no hay transacciones pendientes

            if not Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJnlLine) then begin
                ErrorText := GetLastErrorText();
                ClearLastError();
                Error('Error al registrar en Almacén de Obra: %1', ErrorText);
            end;

            Message('✅ %1 líneas registradas en Almacén de Obra', ItemJnlLine.Count());
        end;
    end;

    local procedure CleanEmptyVariantCode()
    var
        ItemRec: Record Item;
    begin
        // Solo limpiar si Variant Code está vacío o es un espacio en blanco
        if (Rec."Variant Code" = '') or (Rec."Variant Code" = ' ') then begin
            // Verificar si el producto tiene variantes configuradas
            if Rec."Item No." <> '' then begin
                if ItemRec.Get(Rec."Item No.") then begin
                    // Si el producto NO usa variantes, limpiar el campo completamente
                    if ItemRec."Item Tracking Code" = '' then
                        Rec."Variant Code" := '';
                end else
                    // Si no se encuentra el producto, limpiar el campo
                    Rec."Variant Code" := '';
            end else begin
                // Si no hay producto, limpiar el campo
                Rec."Variant Code" := '';
            end;
        end;
    end;
}