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
    procedure CreateWork(obraNo: Code[20]; description: Text[100]; description2: Text[50]; areaCosteo: Code[20]; centroCosto: Code[20]): Text
    var
        Works: Record "GomJob Works";
    begin
        if obraNo = '' then
            Error('Falta el N.º de obra.');
        if Works.Get(obraNo) then
            Error('La obra %1 ya existe en BC.', obraNo);

        // Setear TODO antes del Insert. El Insert(true) dispara lógica interna de GomJob
        // que modifica el registro; si después hiciéramos Modify(true) sobre esta variable
        // (ya desactualizada) BC lo rechaza por concurrencia optimista ("...record cannot
        // be saved because some information ... is not up-to-date"). Por eso: un solo Insert.
        Works.Init();
        Works."No." := obraNo;
        Works.Validate(Description, description);
        Works.Validate("Description 2", description2);
        Works.Validate("Bill-to Customer No.", BillToCustomerNo());
        Works.Insert(true);

        // El Centro de Costo (CC) es propio de cada obra: su valor = N° de obra, y NO existe
        // todavía como valor de dimensión → hay que crearlo antes de asignarlo. El Área de
        // Costo (AC) se elige de valores ya existentes (ej. PRO VIVIENDA), no se crea.
        EnsureDimensionValue(DimCentroCosto(), centroCosto, description);

        // Almacén (Location) propio de la obra: su código = N° de obra.
        EnsureLocation(obraNo, description);

        // Dimensiones por código (tabla aparte; no dependen del número de dimensión de atajo).
        // areaCosteo -> dimensión AC ; centroCosto -> dimensión CC.
        SetObraDimension(obraNo, DimAreaCosto(), areaCosteo);
        SetObraDimension(obraNo, DimCentroCosto(), centroCosto);

        exit('OK');
    end;

    /// <summary>
    /// Devuelve los valores de una dimensión (ej. 'AC' o 'CC') como JSON:
    /// [{"code":"PRO VIVIENDA","name":"Vivienda"}, ...]. Para poblar los combobox de la app.
    /// </summary>
    procedure GetDimensionValues(dimensionCode: Code[20]): Text
    var
        DimValue: Record "Dimension Value";
        JArr: JsonArray;
        JObj: JsonObject;
        result: Text;
    begin
        DimValue.SetRange("Dimension Code", dimensionCode);
        DimValue.SetRange(Blocked, false);
        if DimValue.FindSet() then
            repeat
                Clear(JObj);
                JObj.Add('code', DimValue.Code);
                JObj.Add('name', DimValue.Name);
                JArr.Add(JObj);
            until DimValue.Next() = 0;
        JArr.WriteTo(result);
        exit(result);
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

    /// <summary>Crea el almacén (Location) con código = N° de obra si aún no existe.</summary>
    local procedure EnsureLocation(obraNo: Code[20]; name: Text[100])
    var
        Location: Record Location;
        locCode: Code[10];
    begin
        locCode := CopyStr(obraNo, 1, MaxStrLen(locCode));
        if locCode = '' then
            exit;
        if Location.Get(locCode) then
            exit;
        Location.Init();
        Location.Validate(Code, locCode);
        Location.Validate(Name, CopyStr(name, 1, MaxStrLen(Location.Name)));
        Location.Insert(true);
    end;

    /// <summary>Crea el valor de dimensión (Dimension Value) si aún no existe.</summary>
    local procedure EnsureDimensionValue(dimCode: Code[20]; valueCode: Code[20]; name: Text[100])
    var
        DimValue: Record "Dimension Value";
    begin
        if (dimCode = '') or (valueCode = '') then
            exit;
        if DimValue.Get(dimCode, valueCode) then
            exit;
        DimValue.Init();
        DimValue.Validate("Dimension Code", dimCode);
        DimValue.Validate(Code, valueCode);
        DimValue.Validate(Name, CopyStr(name, 1, MaxStrLen(DimValue.Name)));
        DimValue.Insert(true);
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
