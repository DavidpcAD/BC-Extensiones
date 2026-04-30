page 50101 "GJW Item Journal Lines API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'itemJournalLine';
    EntitySetName = 'itemJournalLines';

    SourceTable = "Item Journal Line"; // Table 83
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    // Habilitado CRUD para Power Apps
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // --- System fields ---
                field(systemId; Rec.SystemId) { Caption = 'System Id'; }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Caption = 'System Created At'; }
                field(systemCreatedBy; Rec.SystemCreatedBy) { Caption = 'System Created By'; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }
                field(systemModifiedBy; Rec.SystemModifiedBy) { Caption = 'System Modified By'; }

                // --- Claves de proceso que conviene exponer ---
                field(entryType; Rec."Entry Type") { ApplicationArea = All; }
                field(valueEntryType; Rec."Value Entry Type") { ApplicationArea = All; }
                field(documentType; Rec."Document Type") { ApplicationArea = All; }
                field(priceCalculationMethod; Rec."Price Calculation Method") { ApplicationArea = All; }

                // --- Campos 1:1 con la tabla 83 ---
                field(journalTemplateName; Rec."Journal Template Name") { ApplicationArea = All; }
                field(journalBatchName; Rec."Journal Batch Name") { ApplicationArea = All; }
                field(lineNo; Rec."Line No.") { ApplicationArea = All; }
                field(itemNo; Rec."Item No.") { ApplicationArea = All; }

                field(postingDate; Rec."Posting Date") { ApplicationArea = All; }
                field(sourceNo; Rec."Source No.") { ApplicationArea = All; }
                field(documentNo; Rec."Document No.") { ApplicationArea = All; }

                // Si prefieres que BC calcule la descripción al validar Item/Variant, déjala no editable.
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false; // <- cambia a true si quieres permitir edición manual
                }
                field(taskNo; TaskNoText)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        SyncApiFieldsToRecord();
                    end;
                }

                field(locationCode; Rec."Location Code") { ApplicationArea = All; }
                field(inventoryPostingGroup; Rec."Inventory Posting Group") { ApplicationArea = All; }
                field(sourcePostingGroup; Rec."Source Posting Group") { ApplicationArea = All; }
                field(quantity; Rec.Quantity) { ApplicationArea = All; }
                field(invoicedQuantity; Rec."Invoiced Quantity") { ApplicationArea = All; }
                field(unitAmount; Rec."Unit Amount") { ApplicationArea = All; }
                field(unitCost; Rec."Unit Cost") { ApplicationArea = All; }
                field(amount; Rec.Amount) { ApplicationArea = All; }
                field(discountAmount; Rec."Discount Amount") { ApplicationArea = All; }

                field(salespersPurchCode; Rec."Salespers./Purch. Code") { ApplicationArea = All; }
                field(sourceCode; Rec."Source Code") { ApplicationArea = All; }

                field(appliesToEntry; Rec."Applies-to Entry") { ApplicationArea = All; }
                field(itemShptEntryNo; Rec."Item Shpt. Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code") { ApplicationArea = All; }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code") { ApplicationArea = All; }
                field(indirectCost; Rec."Indirect Cost %") { ApplicationArea = All; }

                // ✅ CAMPO PARA REGISTRAR DESDE POWER APPS
                field(postThisLine; Rec."GJW Post This Line") { ApplicationArea = All; }

                field(shptMethodCode; Rec."Shpt. Method Code") { ApplicationArea = All; }
                field(reasonCode; Rec."Reason Code") { ApplicationArea = All; }

                field(recurringMethod; Rec."Recurring Method") { ApplicationArea = All; }
                field(expirationDate; Rec."Expiration Date") { ApplicationArea = All; }
                field(recurringFrequency; Rec."Recurring Frequency") { ApplicationArea = All; }

                field(dropShipment; Rec."Drop Shipment")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(transactionType; Rec."Transaction Type") { ApplicationArea = All; }
                field(transportMethod; Rec."Transport Method") { ApplicationArea = All; }
                field(countryRegionCode; Rec."Country/Region Code") { ApplicationArea = All; }

                field(newLocationCode; Rec."New Location Code") { ApplicationArea = All; }
                field(newShortcutDimension1Code; Rec."New Shortcut Dimension 1 Code") { ApplicationArea = All; }
                field(newShortcutDimension2Code; Rec."New Shortcut Dimension 2 Code") { ApplicationArea = All; }

                field(qtyCalculated; Rec."Qty. (Calculated)")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(qtyPhysInventory; Rec."Qty. (Phys. Inventory)") { ApplicationArea = All; }

                field(lastItemLedgerEntryNo; Rec."Last Item Ledger Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(physInventory; Rec."Phys. Inventory")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group") { ApplicationArea = All; }
                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group") { ApplicationArea = All; }
                field(entryExitPoint; Rec."Entry/Exit Point") { ApplicationArea = All; }
                field(documentDate; Rec."Document Date") { ApplicationArea = All; }
                field(externalDocumentNo; Rec."External Document No.") { ApplicationArea = All; }
                field(areaCode; Rec."Area") { ApplicationArea = All; }
                field(transactionSpecification; Rec."Transaction Specification") { ApplicationArea = All; }
                field(postingNoSeries; Rec."Posting No. Series") { ApplicationArea = All; }

                field(reservedQuantity; Rec."Reserved Quantity")
                {
                    ApplicationArea = All;
                    Editable = false; // FlowField
                }

                field(unitCostAcy; Rec."Unit Cost (ACY)")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(sourceCurrencyCode; Rec."Source Currency Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(documentLineNo; Rec."Document Line No.") { ApplicationArea = All; }
                field(vatReportingDate; Rec."VAT Reporting Date") { ApplicationArea = All; }

                field(orderNo; Rec."Order No.") { ApplicationArea = All; }
                field(orderLineNo; Rec."Order Line No.") { ApplicationArea = All; }

                field(appliesToRemQuantity; Rec."Applies-to Rem. Quantity")
                {
                    ApplicationArea = All;
                    Editable = false; // FlowField
                }

                field(dimensionSetId; Rec."Dimension Set ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(newDimensionSetId; Rec."New Dimension Set ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(assembleToOrder; Rec."Assemble to Order")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(jobNo; Rec."Job No.") { ApplicationArea = All; }
                field(jobTaskNo; JobTaskNoText)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        SyncApiFieldsToRecord();
                    end;
                }
                field(newJobNo; NewJobNoText)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        SyncApiFieldsToRecord();
                    end;
                }
                field(newJobTaskNo; NewJobTaskNoText)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        SyncApiFieldsToRecord();
                    end;
                }
                field(jobPurchase; Rec."Job Purchase") { ApplicationArea = All; }
                field(jobContractEntryNo; Rec."Job Contract Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(variantCode; Rec."Variant Code") { ApplicationArea = All; }
                field(binCode; Rec."Bin Code") { ApplicationArea = All; }
                field(qtyPerUnitOfMeasure; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(newBinCode; Rec."New Bin Code") { ApplicationArea = All; }
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field(derivedFromBlanketOrder; Rec."Derived from Blanket Order")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(qtyRoundingPrecision; Rec."Qty. Rounding Precision")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(qtyRoundingPrecisionBase; Rec."Qty. Rounding Precision (Base)")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(quantityBase; Rec."Quantity (Base)") { ApplicationArea = All; }
                field(invoicedQtyBase; Rec."Invoiced Qty. (Base)")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(reservedQtyBase; Rec."Reserved Qty. (Base)")
                {
                    ApplicationArea = All;
                    Editable = false; // FlowField
                }

                field(level; Rec.Level)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(changedByUser; Rec."Changed by User")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(originallyOrderedNo; Rec."Originally Ordered No.") { ApplicationArea = All; }
                field(originallyOrderedVarCode; Rec."Originally Ordered Var. Code") { ApplicationArea = All; }
                field(outOfStockSubstitution; Rec."Out-of-Stock Substitution") { ApplicationArea = All; }
                field(itemCategoryCode; Rec."Item Category Code") { ApplicationArea = All; }
                field(nonstock; Rec.Nonstock) { ApplicationArea = All; }
                field(purchasingCode; Rec."Purchasing Code") { ApplicationArea = All; }

                field(itemReferenceNo; Rec."Item Reference No.") { ApplicationArea = All; }
                field(itemReferenceUnitOfMeasure; Rec."Item Reference Unit of Measure") { ApplicationArea = All; }
                field(itemReferenceTypeNo; Rec."Item Reference Type No.") { ApplicationArea = All; }

                field(plannedDeliveryDate; Rec."Planned Delivery Date") { ApplicationArea = All; }
                field(orderDate; Rec."Order Date") { ApplicationArea = All; }

                field(itemChargeNo; Rec."Item Charge No.") { ApplicationArea = All; }

                field(inventoryValueCalculated; Rec."Inventory Value (Calculated)")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(inventoryValueRevalued; Rec."Inventory Value (Revalued)") { ApplicationArea = All; }
                field(inventoryValuePer; Rec."Inventory Value Per")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(partialRevaluation; Rec."Partial Revaluation")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(appliesFromEntry; Rec."Applies-from Entry") { ApplicationArea = All; }
                field(invoiceNo; Rec."Invoice No.") { ApplicationArea = All; }

                field(unitCostCalculated; Rec."Unit Cost (Calculated)")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(unitCostRevalued; Rec."Unit Cost (Revalued)") { ApplicationArea = All; }

                field(appliedAmount; Rec."Applied Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(updateStandardCost; Rec."Update Standard Cost") { ApplicationArea = All; }
                field(amountAcy; Rec."Amount (ACY)") { ApplicationArea = All; }

                field(correction; Rec.Correction) { ApplicationArea = All; }
                field(adjustment; Rec.Adjustment) { ApplicationArea = All; }
                field(appliesToValueEntry; Rec."Applies-to Value Entry") { ApplicationArea = All; }

                field(invoiceToSourceNo; Rec."Invoice-to Source No.") { ApplicationArea = All; }

                field(no; Rec."No.") { ApplicationArea = All; }
                field(capUnitOfMeasureCode; Rec."Cap. Unit of Measure Code") { ApplicationArea = All; }
                field(qtyPerCapUnitOfMeasure; Rec."Qty. per Cap. Unit of Measure") { ApplicationArea = All; }

                field(serialNo; Rec."Serial No.") { ApplicationArea = All; }
                field(lotNo; Rec."Lot No.") { ApplicationArea = All; }
                field(warrantyDate; Rec."Warranty Date") { ApplicationArea = All; }

                field(newSerialNo; Rec."New Serial No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(newLotNo; Rec."New Lot No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(newItemExpirationDate; Rec."New Item Expiration Date") { ApplicationArea = All; }
                field(itemExpirationDate; Rec."Item Expiration Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(packageNo; Rec."Package No.") { ApplicationArea = All; }
                field(newPackageNo; Rec."New Package No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(returnReasonCode; Rec."Return Reason Code") { ApplicationArea = All; }
                field(warehouseAdjustment; Rec."Warehouse Adjustment") { ApplicationArea = All; }
                field(directTransfer; Rec."Direct Transfer")
                {
                    ApplicationArea = All;
                    // Metadata/system: mejor no editar desde API
                    Editable = false;
                }

                field(physInvtCountingPeriodCode; Rec."Phys Invt Counting Period Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(physInvtCountingPeriodType; Rec."Phys Invt Counting Period Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(overheadRate; Rec."Overhead Rate") { ApplicationArea = All; }

                field(singleLevelMaterialCost; Rec."Single-Level Material Cost") { ApplicationArea = All; }
                field(singleLevelCapacityCost; Rec."Single-Level Capacity Cost") { ApplicationArea = All; }
                field(singleLevelSubcontrdCost; Rec."Single-Level Subcontrd. Cost") { ApplicationArea = All; }
                field(singleLevelCapOvhdCost; Rec."Single-Level Cap. Ovhd Cost") { ApplicationArea = All; }
                field(singleLevelMfgOvhdCost; Rec."Single-Level Mfg. Ovhd Cost") { ApplicationArea = All; }
                field(rolledUpMaterialCost; Rec."Rolled-up Material Cost") { ApplicationArea = All; }
                field(rolledUpCapacityCost; Rec."Rolled-up Capacity Cost") { ApplicationArea = All; }
                field(rolledUpSubcontractedCost; Rec."Rolled-up Subcontracted Cost") { ApplicationArea = All; }
                field(rolledUpMfgOvhdCost; Rec."Rolled-up Mfg. Ovhd Cost") { ApplicationArea = All; }
                field(rolledUpCapOverheadCost; Rec."Rolled-up Cap. Overhead Cost") { ApplicationArea = All; }
                field(singleLvlMatNonInvtCost; Rec."Single-Lvl Mat. Non-Invt. Cost") { ApplicationArea = All; }
                field(rolledUpMatNonInvtCost; Rec."Rolled-up Mat. Non-Invt. Cost") { ApplicationArea = All; }
            }
        }
    }

    // --- Inicialización opcional para diario de reclasificación ---
    // Descomenta si quieres que al crear un registro nuevo se proponga Transfer + Direct Cost.
    /*
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Validate("Entry Type", Rec."Entry Type"::Transfer);
        Rec.Validate("Value Entry Type", Rec."Value Entry Type"::"Direct Cost");
    end;
    */

    // Prevenir líneas vacías desde Power Apps
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        SyncApiFieldsToRecord();

        // Validar que al menos tenga campos críticos antes de permitir la inserción
        if (Rec."Item No." = '') or
           (Rec."Journal Template Name" = '') or
           (Rec."Journal Batch Name" = '') then
            exit(false); // Rechazar silenciosamente la inserción si faltan campos críticos

        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        SyncRecordToApiFields();
    end;

    trigger OnAfterGetCurrRecord()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        SyncRecordToApiFields();

        // Eliminar líneas vacías que pudieron crearse con DelayedInsert
        ItemJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        ItemJnlLine.SetRange("Item No.", '');
        if ItemJnlLine.FindSet() then
            ItemJnlLine.DeleteAll(false);
    end;

    // ========== ACCIONES PARA POWER APPS ==========

    [ServiceEnabled]
    procedure PostBatch(TemplateName: Code[10]; BatchName: Code[20]): Text
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        LineCount: Integer;
    begin
        // Filtrar líneas del batch
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if not ItemJnlLine.FindSet() then
            Error('No se encontraron líneas en el batch: %1/%2', TemplateName, BatchName);

        LineCount := ItemJnlLine.Count;

        // Registrar todas las líneas del batch
        ItemJnlPostBatch.Run(ItemJnlLine);

        exit(StrSubstNo('Batch registrado exitosamente: %1 - %2 líneas procesadas', BatchName, LineCount));
    end;

    local procedure SyncApiFieldsToRecord()
    begin
        Rec.Validate("Task No.", CopyStr(TaskNoText, 1, MaxStrLen(Rec."Task No.")));
        Rec.Validate("Job Task No.", CopyStr(JobTaskNoText, 1, MaxStrLen(Rec."Job Task No.")));
        Rec.Validate("New Job No.", CopyStr(NewJobNoText, 1, MaxStrLen(Rec."New Job No.")));
        Rec.Validate("New Job Task No.", CopyStr(NewJobTaskNoText, 1, MaxStrLen(Rec."New Job Task No.")));
    end;

    local procedure SyncRecordToApiFields()
    begin
        TaskNoText := Rec."Task No.";
        JobTaskNoText := Rec."Job Task No.";
        NewJobNoText := Rec."New Job No.";
        NewJobTaskNoText := Rec."New Job Task No.";
    end;

    var
        TaskNoText: Text[20];
        JobTaskNoText: Text[20];
        NewJobNoText: Text[20];
        NewJobTaskNoText: Text[20];
}
