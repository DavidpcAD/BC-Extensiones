pageextension 50132 "GJW Works Decomp Page Ext" extends "GomJob Works Decomposed Line"
{
    layout
    {
        addafter(Description)
        {
            field("ID Visibles Text"; Rec."ID Visibles Text")
            {
                ApplicationArea = All;
                Caption = 'ID Visibles';
                ToolTip = 'Identificador visible asociado a esta línea';
                Visible = true;
                Enabled = true;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(GJWRepairMissingDecompItems)
            {
                ApplicationArea = All;
                Caption = 'Reparar Materiales Vacios';
                ToolTip = 'Rellena No. y Description de lineas de descompuesto que quedaron vacias usando Source Code y la ficha del item.';

                trigger OnAction()
                var
                    DecompLine: Record "GomJob Works Decomposed Lines";
                    ItemRec: Record Item;
                    CandidateNo: Code[50];
                    NeedsModify: Boolean;
                    FixedCount: Integer;
                begin
                    DecompLine.SetRange("Works No.", Rec."Works No.");
                    if DecompLine.FindSet(true) then
                        repeat
                            CandidateNo := '';
                            NeedsModify := false;

                            if DecompLine."No." = '' then begin
                                if DecompLine."Source Code" <> '' then
                                    CandidateNo := CopyStr(DecompLine."Source Code", 1, MaxStrLen(CandidateNo));

                                if (CandidateNo <> '') and ItemRec.Get(CandidateNo) then begin
                                    DecompLine."No." := CopyStr(CandidateNo, 1, MaxStrLen(DecompLine."No."));
                                    NeedsModify := true;
                                end;
                            end;

                            if (DecompLine.Description = '') and (DecompLine."No." <> '') and ItemRec.Get(DecompLine."No.") then begin
                                DecompLine.Description := CopyStr(ItemRec.Description, 1, MaxStrLen(DecompLine.Description));
                                NeedsModify := true;
                            end;

                            if NeedsModify then begin
                                DecompLine.Modify(true);
                                FixedCount += 1;
                            end;
                        until DecompLine.Next() = 0;

                    Message('%1 lineas reparadas para la obra %2.', FixedCount, Rec."Works No.");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
