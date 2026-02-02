codeunit 50157 "GJW Item Journal Post Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertItemLedgEntry', '', false, false)]
    local procedure CopyTaskNoToItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        // Copiar Task No. del diario al Item Ledger Entry
        ItemLedgerEntry."Task No." := ItemJournalLine."Task No.";

        // Guardar NewJobNo y NewJobTaskNo en variables globales para usar después
        if ItemJournalLine."New Job No." <> '' then
            GlobalNewJobNo := ItemJournalLine."New Job No.";
        if ItemJournalLine."New Job Task No." <> '' then
            GlobalNewJobTaskNo := ItemJournalLine."New Job Task No.";
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

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure CreateWarehouseQtyForDestination(var Rec: Record "Item Ledger Entry"; RunTrigger: Boolean)
    var
        WarehouseQty: Record "GomJob Warehouse Quantity";
        JobTask: Record "Job Task";
    begin
        // Solo procesar transferencias con proyecto/tarea destino
        if (GlobalNewJobNo = '') or (GlobalNewJobTaskNo = '') then
            exit;

        // Solo para movimientos positivos (entrada al destino)
        if not Rec.Positive then
            exit;

        // Verificar que la tarea destino existe
        if not JobTask.Get(GlobalNewJobNo, GlobalNewJobTaskNo) then
            exit;

        // Buscar si ya existe el registro
        if WarehouseQty.Get(Rec."Entry No.", GlobalNewJobNo, GlobalNewJobTaskNo) then
            exit; // Ya existe

        // Crear vínculo con la tarea destino
        WarehouseQty.Init();
        WarehouseQty."Item Ledger Entry No." := Rec."Entry No.";
        WarehouseQty."Job No." := GlobalNewJobNo;
        WarehouseQty."Job Task No." := GlobalNewJobTaskNo;
        WarehouseQty."Job Task Description" := JobTask.Description;
        WarehouseQty.Quantity := Rec.Quantity;
        WarehouseQty.Insert(true);

        // Limpiar variables globales
        Clear(GlobalNewJobNo);
        Clear(GlobalNewJobTaskNo);
    end;

    var
        GlobalNewJobNo: Code[20];
        GlobalNewJobTaskNo: Code[20];
}
