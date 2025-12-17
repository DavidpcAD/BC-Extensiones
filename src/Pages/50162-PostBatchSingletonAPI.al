page 50162 "GJW Register Batch Trigger API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'registerBatchTrigger';
    EntitySetName = 'registerBatchTriggers';

    SourceTable = "Item Journal Batch";
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId) { }
                field(journalTemplateName; Rec."Journal Template Name") { }
                field(name; Rec.Name) { }
                field(description; Rec.Description) { }
                field(triggerPost; TriggerPost) { }
                field(postingResult; PostingResult) { Editable = false; }
            }
        }
    }

    var
        TriggerPost: Boolean;
        PostingResult: Text[250];

    trigger OnModifyRecord(): Boolean
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        LineCount: Integer;
    begin
        // Solo ejecutar si TriggerPost = true
        if not TriggerPost then
            exit(true);

        // Obtener todas las líneas del batch
        ItemJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", Rec.Name);

        if not ItemJnlLine.FindSet() then begin
            PostingResult := 'ERROR: No hay líneas para registrar';
            Error(PostingResult);
        end;

        LineCount := ItemJnlLine.Count;

        // ✅ EJECUTAR MISMO PROCESO QUE BOTÓN "REGISTRAR" DE BC
        // Esto automáticamente:
        // 1. Registra las líneas del diario
        // 2. Dispara Event Subscriber 50157 (OnBeforeInsertItemLedgEntry)
        // 3. Copia Task No. al Item Ledger Entry
        // 4. Dispara Event Subscriber 50157 (OnAfterInsertEvent)
        // 5. Crea automáticamente registro en GomJob Warehouse Quantity
        ItemJnlPostBatch.Run(ItemJnlLine);

        PostingResult := StrSubstNo('✅ Registrado: %1 - %2 líneas procesadas', Rec.Name, LineCount);

        exit(true);
    end;
}
