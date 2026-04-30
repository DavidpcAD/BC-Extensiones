namespace Adelante.Inventory;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

page 50206 "GJW Item Stock Check API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'itemStockCheck';
    EntitySetName = 'itemStockChecks';

    SourceTable = "GJW Item Stock Check Req";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(availableQuantity; Rec."Available Quantity")
                {
                    Caption = 'Available Quantity';
                    Editable = false;
                }
                field(remainingQuantity; Rec."Remaining Quantity")
                {
                    Caption = 'Remaining Quantity';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                }
                field(unitOfMeasure; Rec."Unit of Measure")
                {
                    Caption = 'Unit of Measure';
                    Editable = false;
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'Error Message';
                    Editable = false;
                }
                field(requestedAt; Rec."Requested At")
                {
                    Caption = 'Requested At';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        Rec."Requested At" := CurrentDateTime();
        Rec.Status := 'OK';
        Rec."Error Message" := '';
        Rec."Available Quantity" := 0;
        Rec."Remaining Quantity" := 0;
        Rec.Description := '';
        Rec."Unit of Measure" := '';

        if Rec."Item No." = '' then begin
            Rec.Status := 'ERROR';
            Rec."Error Message" := 'itemNo es requerido';
            exit(true);
        end;

        if not Item.Get(Rec."Item No.") then begin
            Rec.Status := 'ERROR';
            Rec."Error Message" := StrSubstNo('No existe el item %1', Rec."Item No.");
            exit(true);
        end;

        Rec.Description := Item.Description;
        Rec."Unit of Measure" := Item."Base Unit of Measure";

        ItemLedgerEntry.SetRange("Item No.", Rec."Item No.");
        ItemLedgerEntry.SetRange("Posting Date", 0D, Today());

        if Rec."Variant Code" <> '' then
            ItemLedgerEntry.SetRange("Variant Code", Rec."Variant Code");

        if Rec."Location Code" <> '' then
            ItemLedgerEntry.SetRange("Location Code", Rec."Location Code");

        ItemLedgerEntry.CalcSums(Quantity, "Remaining Quantity");
        Rec."Available Quantity" := ItemLedgerEntry.Quantity;
        Rec."Remaining Quantity" := ItemLedgerEntry."Remaining Quantity";

        exit(true);
    end;
}