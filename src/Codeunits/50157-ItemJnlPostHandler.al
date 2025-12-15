codeunit 50157 "GJW Item Journal Post Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertItemLedgEntry', '', false, false)]
    local procedure CopyTaskNoToItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        // Copiar Task No. del diario al Item Ledger Entry
        ItemLedgerEntry."Task No." := ItemJournalLine."Task No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure CreateWarehouseQuantity(var Rec: Record "Item Ledger Entry"; RunTrigger: Boolean)
    var
        WarehouseQty: Record "GomJob Warehouse Quantity";
        JobTask: Record "Job Task";
    begin
        // Solo procesar si tiene Task No. y Job No.
        if (Rec."Task No." = '') or (Rec."Global Dimension 1 Code" = '') then
            exit;

        // Verificar que la tarea existe en Job Task
        if not JobTask.Get(Rec."Global Dimension 1 Code", Rec."Task No.") then
            exit;

        // Buscar si ya existe el registro
        if WarehouseQty.Get(Rec."Entry No.", Rec."Global Dimension 1 Code", Rec."Task No.") then
            exit; // Ya existe, no duplicar

        // Crear nuevo registro en GomJob Warehouse Quantity
        WarehouseQty.Init();
        WarehouseQty."Item Ledger Entry No." := Rec."Entry No.";
        WarehouseQty."Job No." := Rec."Global Dimension 1 Code";
        WarehouseQty."Job Task No." := Rec."Task No.";
        WarehouseQty."Job Task Description" := JobTask.Description;
        WarehouseQty.Quantity := Rec.Quantity;
        WarehouseQty.Insert(true);
    end;
}
