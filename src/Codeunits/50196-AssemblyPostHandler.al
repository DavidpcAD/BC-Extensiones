codeunit 50196 "GJW Assembly Post Handler"
{
    procedure PostAssemblyOrder(DocumentNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyPost: Codeunit "Assembly-Post";
    begin
        AssemblyHeader.Reset();
        AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.SetRange("No.", DocumentNo);

        if not AssemblyHeader.FindFirst() then
            Error('Assembly Order %1 not found', DocumentNo);

        if AssemblyHeader.Status <> AssemblyHeader.Status::Released then
            Error('Assembly Order %1 must be Released before posting', DocumentNo);

        AssemblyPost.Run(AssemblyHeader);
    end;

    procedure ReleaseAssemblyOrder(DocumentNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
    begin
        AssemblyHeader.Reset();
        AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.SetRange("No.", DocumentNo);

        if not AssemblyHeader.FindFirst() then
            Error('Assembly Order %1 not found', DocumentNo);

        if AssemblyHeader.Status = AssemblyHeader.Status::Released then
            exit; // Already released

        AssemblyHeader.Validate(Status, AssemblyHeader.Status::Released);
        AssemblyHeader.Modify(true);
    end;
}
