// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50240 "Adelante Obra Actions"
// Propósito: Crear Obras (GomJob Works) y su Proyecto desde la app, vía Web Service
//            OData ("AdelanteObra"). Espeja el flujo del UI:
//              - CreateWork  -> alta de la Obra + dimensiones AC (Área de Costo) y
//                               CC (Centro de Costo) + cliente fijo 'AD'.
//              - CreateProject -> "Crear proyecto" (GomJob Job Management.CreateJob)
//                               + tareas (UpsertJobTask).
//
// Llamada desde la app (OData V4 unbound action, S2S):
//   POST .../ODataV4/AdelanteObra_CreateWork?company={companyId}
//   body: { "obraNo":"VC-D.99", "description":"...", "description2":"",
//           "areaCosto":"PRO VIVIENDA", "centroCosto":"PRUEBA" }
//   POST .../ODataV4/AdelanteObra_CreateProject?company={companyId}
//   body: { "obraNo":"VC-D.99" }
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50240 "Adelante Obra Actions"
{
    Access = Public;

    /// <summary>
    /// Crea una Obra (GomJob Works) con su cliente de facturación fijo 'AD' y asigna las
    /// dimensiones por defecto Área de Costo (AC) y Centro de Costo (CC). Devuelve 'OK'.
    /// </summary>
    procedure CreateWork(obraNo: Code[20]; description: Text[100]; description2: Text[50]; areaCosto: Code[20]; centroCosto: Code[20]): Text
    var
        Works: Record "GomJob Works";
    begin
        if obraNo = '' then
            Error('Falta el N.º de obra.');
        if Works.Get(obraNo) then
            Error('La obra %1 ya existe en BC.', obraNo);

        Works.Init();
        Works."No." := obraNo;
        Works.Insert(true);

        Works.Validate(Description, description);
        Works.Validate("Description 2", description2);
        Works.Validate("Bill-to Customer No.", BillToCustomerNo());
        Works.Modify(true);

        // Dimensiones por código (no dependen del número de dimensión de atajo).
        SetObraDimension(obraNo, DimAreaCosto(), areaCosto);
        SetObraDimension(obraNo, DimCentroCosto(), centroCosto);

        exit('OK');
    end;

    /// <summary>
    /// Crea el Proyecto (Job) en BC a partir de la Obra y actualiza sus tareas.
    /// Usa la última versión de la obra. Devuelve 'OK'.
    /// </summary>
    procedure CreateProject(obraNo: Code[20]): Text
    var
        Works: Record "GomJob Works";
        JobMgmt: Codeunit "GomJob Job Management";
        versionCode: Code[20];
    begin
        if not Works.Get(obraNo) then
            Error('La obra %1 no existe en BC.', obraNo);

        versionCode := Works.GetLatestVersionCode();
        JobMgmt.CreateJob(Works, versionCode);
        JobMgmt.UpsertJobTask(Works, versionCode);

        exit('OK');
    end;

    /// <summary>Crea o actualiza una dimensión por defecto de la obra por código de dimensión.</summary>
    local procedure SetObraDimension(obraNo: Code[20]; dimCode: Code[20]; dimValue: Code[20])
    var
        DefaultDim: Record "Default Dimension";
    begin
        if (dimCode = '') or (dimValue = '') then
            exit;
        if DefaultDim.Get(Database::"GomJob Works", obraNo, dimCode) then begin
            DefaultDim.Validate("Dimension Value Code", dimValue);
            DefaultDim.Modify(true);
        end else begin
            DefaultDim.Init();
            DefaultDim.Validate("Table ID", Database::"GomJob Works");
            DefaultDim.Validate("No.", obraNo);
            DefaultDim.Validate("Dimension Code", dimCode);
            DefaultDim.Validate("Dimension Value Code", dimValue);
            DefaultDim.Insert(true);
        end;
    end;

    local procedure BillToCustomerNo(): Code[20]
    begin
        exit('AD'); // Adelante Desarrollos S.A. (cliente de facturación fijo)
    end;

    local procedure DimAreaCosto(): Code[20]
    begin
        exit('AC'); // Área de Costo
    end;

    local procedure DimCentroCosto(): Code[20]
    begin
        exit('CC'); // Centro de Costo
    end;
}
