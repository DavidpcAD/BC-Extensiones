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
        if areaCosteo = '' then
            Error('Falta el Área de Costo. El parámetro esperado es exactamente "areaCosteo" (valor de dimensión AC, ej. "PRO VIVIENDA").');
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

        // Asignar dimensiones. areaCosteo -> AC ; centroCosto -> CC.
        AsignarDimension(obraNo, DimAreaCosto(), areaCosteo);
        AsignarDimension(obraNo, DimCentroCosto(), centroCosto);

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

    /// <summary>
    /// Asigna un valor de dimensión a la obra. Si la dimensión es de atajo/global (aparece
    /// como campo en la ficha, ej. "Área de Costo"), se setea con ValidateShortcutDimCode en
    /// el registro (así se ve en la ficha y se crea la Default Dimension). Si no lo es, se
    /// inserta directamente la Default Dimension.
    /// </summary>
    local procedure AsignarDimension(obraNo: Code[20]; dimCode: Code[20]; dimValue: Code[20])
    var
        Works: Record "GomJob Works";
        fieldNo: Integer;
    begin
        if (dimCode = '') or (dimValue = '') then
            exit;
        fieldNo := ShortcutFieldNo(dimCode);
        if fieldNo > 0 then begin
            Works.Get(obraNo); // fresco, para no chocar por concurrencia con el Insert previo
            Works.ValidateShortcutDimCode(fieldNo, dimValue);
            Works.Modify(true);
        end else
            SetObraDimension(obraNo, dimCode, dimValue);
    end;

    /// <summary>Devuelve el N° de dimensión de atajo (1-8) de un código de dimensión, o 0 si no es de atajo.</summary>
    local procedure ShortcutFieldNo(dimCode: Code[20]): Integer
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if dimCode = '' then
            exit(0);
        GLSetup.Get();
        if dimCode = GLSetup."Global Dimension 1 Code" then exit(1);
        if dimCode = GLSetup."Global Dimension 2 Code" then exit(2);
        if dimCode = GLSetup."Shortcut Dimension 3 Code" then exit(3);
        if dimCode = GLSetup."Shortcut Dimension 4 Code" then exit(4);
        if dimCode = GLSetup."Shortcut Dimension 5 Code" then exit(5);
        if dimCode = GLSetup."Shortcut Dimension 6 Code" then exit(6);
        if dimCode = GLSetup."Shortcut Dimension 7 Code" then exit(7);
        if dimCode = GLSetup."Shortcut Dimension 8 Code" then exit(8);
        exit(0);
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
