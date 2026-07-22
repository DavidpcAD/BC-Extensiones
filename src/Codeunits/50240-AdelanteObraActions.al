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
    procedure CreateWork(obraNo: Code[20]; description: Text[100]; description2: Text[50]; areaCosteo: Code[20]; centroCosto: Code[20]; tiposInventario: Text): Text
    var
        Works: Record "GomJob Works";
        acField: Integer;
    begin
        if obraNo = '' then
            Error('Falta el N.º de obra.');
        if areaCosteo = '' then
            Error('Falta el Área de Costo. El parámetro esperado es exactamente "areaCosteo" (valor de dimensión AC, ej. "PRO VIVIENDA").');
        if Works.Get(obraNo) then
            Error('La obra %1 ya existe en BC.', obraNo);

        // 1) Insertar el Work primero (sin tocar dimensiones antes → si no, se intenta escribir
        //    Default Dimension sobre un Work inexistente: "No. ... cannot be found in Work").
        Works.Init();
        Works."No." := obraNo;
        Works.Validate(Description, description);
        Works.Validate("Description 2", description2);
        Works.Validate("Bill-to Customer No.", BillToCustomerNo());
        Works.Insert(true);

        // 2) Con el Work ya existente: valor de dimensión del CC (propio de la obra) y almacén.
        EnsureDimensionValue(DimCentroCosto(), centroCosto, description);
        EnsureLocation(obraNo, description);

        // 2b) Inventory Posting Setup por cada tipo de inventario recibido (idempotente).
        CreateInventoryPostingSetups(obraNo, tiposInventario);

        // 3) AC = dimensión de atajo/global (campo "Área de Costo" de la ficha). Se asigna con
        //    ValidateShortcutDimCode, que YA persiste la Default Dimension y el campo global por
        //    sí mismo. NO hacer Modify después: ese Modify (sobre la variable ya desactualizada
        //    por el guardado interno) es el que chocaba por concurrencia optimista.
        acField := ShortcutFieldNo(DimAreaCosto());
        if acField > 0 then begin
            Works.Get(obraNo); // fresco
            Works.ValidateShortcutDimCode(acField, areaCosteo); // persiste la Default Dimension del AC

            // Persistir el campo denormalizado "Global Dimension 1/2 Code" (la columna
            // "Área de Costo" de las listas/reportes). ValidateShortcutDimCode lo deja solo
            // en memoria. Re-leemos FRESCO (ya con lo que escribió el subscriber de GomJob) y
            // lo seteamos por asignación directa (sin re-disparar el guardado de dimensión que
            // causaba el race), y recién ahí Modify. El Get va DESPUÉS del ValidateShortcutDimCode
            // (antes chocaba porque la variable quedaba desactualizada por el guardado interno).
            if acField in [1, 2] then begin
                Works.Get(obraNo);
                if acField = 1 then
                    Works."Global Dimension 1 Code" := areaCosteo
                else
                    Works."Global Dimension 2 Code" := areaCosteo;
                Works.Modify(true);
            end;
        end;

        // AC como Default Dimension SIEMPRE. Sobre la tabla custom GomJob Works,
        // ValidateShortcutDimCode NO crea la fila en Default Dimension (solo setea el campo
        // global denormalizado), así que el AC no quedaba como dimensión predeterminada.
        // SetObraDimension es idempotente (Get->Modify / Insert) y opera sobre Default
        // Dimension —no sobre el Work—, así que no reintroduce el race de concurrencia.
        SetObraDimension(obraNo, DimAreaCosto(), areaCosteo);

        // 4) CC = dimensión normal → Default Dimension (tabla aparte, no toca el Work).
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

        // CreateJob hereda el CC al Job pero no el AC. Copiamos TODAS las Default Dimensions
        // de la Obra (GomJob Works) al Job (mismo N°), así el Proyecto queda con AC + CC igual
        // que la Obra. Idempotente y sobre Default Dimension (no toca el Work).
        CopyObraDimsToJob(obraNo);

        exit('OK');
    end;

    /// <summary>Copia las Default Dimensions de la Obra (GomJob Works) al Job del mismo N°.</summary>
    local procedure CopyObraDimsToJob(obraNo: Code[20])
    var
        Job: Record Job;
        ObraDim: Record "Default Dimension";
        JobDim: Record "Default Dimension";
    begin
        if not Job.Get(obraNo) then
            exit; // el Job normalmente nace con el mismo N° que la obra; si no, no hay a dónde copiar
        ObraDim.SetRange("Table ID", Database::"GomJob Works");
        ObraDim.SetRange("No.", obraNo);
        if ObraDim.FindSet() then
            repeat
                if JobDim.Get(Database::Job, obraNo, ObraDim."Dimension Code") then begin
                    JobDim.Validate("Dimension Value Code", ObraDim."Dimension Value Code");
                    JobDim.Modify(true);
                end else begin
                    JobDim.Init();
                    JobDim.Validate("Table ID", Database::Job);
                    JobDim.Validate("No.", obraNo);
                    JobDim.Validate("Dimension Code", ObraDim."Dimension Code");
                    JobDim.Validate("Dimension Value Code", ObraDim."Dimension Value Code");
                    JobDim.Insert(true);
                end;
            until ObraDim.Next() = 0;
    end;

    /// <summary>
    /// Bloquea (o desbloquea) una obra en un solo paso, replicando el proceso manual:
    ///   1) Obra (GomJob Works): Blocked = blocked
    ///   2) Proyecto (Job): Blocked = All (Todo) si blocked; sin bloqueo si no
    ///   3) Valor de dimensión CC de la obra (Code = N° obra): Blocked = blocked
    /// blocked=true bloquea; blocked=false revierte los tres.
    /// </summary>
    procedure SetObraBlocked(obraNo: Code[20]; blocked: Boolean; postventaNo: Code[20]): Text
    var
        Works: Record "GomJob Works";
        Job: Record Job;
        DimValue: Record "Dimension Value";
        pvNo: Code[20];
    begin
        if obraNo = '' then
            Error('Falta el N.º de obra.');
        if not Works.Get(obraNo) then
            Error('La obra %1 no existe en BC.', obraNo);

        // 1) Obra (GomJob Works)
        Works.Validate(Blocked, blocked);
        Works.Modify(true);

        // 2) Proyecto (Job) — mismo N° que la obra. Bloqueado = Todo (All).
        if Job.Get(obraNo) then begin
            if blocked then
                Job.Validate(Blocked, Job.Blocked::All)
            else
                Job.Validate(Blocked, Job.Blocked::" ");
            Job.Modify(true);
        end;

        // 3) Valor de dimensión CC de la obra (Code = N° de obra)
        if DimValue.Get(DimCentroCosto(), obraNo) then begin
            DimValue.Validate(Blocked, blocked);
            DimValue.Modify(true);
        end;

        // 4) Actividad en la obra Postventa ELEGIDA por el usuario (postventaNo). Si no viene,
        //    se intenta resolver por el prefijo (fallback). Con blocked=true da de alta; con
        //    blocked=false marca Revertida (no borra).
        pvNo := ResolvePostventaNo(obraNo, postventaNo, blocked);
        if pvNo <> '' then
            UpsertPostventaActivity(obraNo, pvNo, Works.Description, blocked);

        exit('OK');
    end;

    /// <summary>
    /// Determina la obra Postventa destino: 1) la que eligió el usuario (postventaNo); 2) si
    /// viene vacía, la del mapeo por prefijo en "Adelante Postventa Setup" (fallback). Si no
    /// hay ninguna y se está bloqueando, Error claro. Al desbloquear sin dato, devuelve ''.
    /// </summary>
    local procedure ResolvePostventaNo(obraNo: Code[20]; postventaNo: Code[20]; blocked: Boolean): Code[20]
    var
        Setup: Record "Adelante Postventa Setup";
        prefijo: Code[20];
        p: Integer;
    begin
        if postventaNo <> '' then
            exit(postventaNo);

        p := StrPos(obraNo, '-');
        if p > 1 then
            prefijo := CopyStr(obraNo, 1, p - 1)
        else
            prefijo := obraNo;
        if Setup.Get(prefijo) then
            exit(Setup."Obra Postventa No.");

        if blocked then
            Error('Elegí una obra Postventa (PV-…) para registrar la actividad de %1, o configurá el prefijo "%2" en "Adelante Postventa Setup".', obraNo, prefijo);
        exit('');
    end;

    /// <summary>
    /// Da de alta (o marca como revertida) la actividad de la obra en la obra Postventa dada
    /// (pvNo, ya resuelta por ResolvePostventaNo). La actividad debe quedar en AMBAS secciones
    /// de la obra Postventa: Líneas venta (Line Type = Sales) y Coste directo (Line Type = Cost)
    /// —es el mismo estado final que se logra a mano creando la línea en venta y luego con el
    /// botón "Traer líneas de obra"—. Cada línea es una GomJob Works Line con Task Type = Posting
    /// (se muestra como "Auxiliar") y Task No. = N° de la obra (idempotencia por PK).
    /// blocked=true crea/reactiva; blocked=false marca Revertida (no borra).
    /// </summary>
    local procedure UpsertPostventaActivity(obraNo: Code[20]; pvNo: Code[20]; description: Text[100]; blocked: Boolean)
    var
        PVWorks: Record "GomJob Works";
        versionCode: Code[20];
    begin
        if not PVWorks.Get(pvNo) then begin
            if blocked then
                Error('La obra Postventa "%1" no existe en BC.', pvNo);
            exit;
        end;
        versionCode := PVWorks.GetLatestVersionCode();

        UpsertPostventaLine(pvNo, versionCode, Enum::"GomJob Works Line Type"::Sales, obraNo, description, blocked);
        UpsertPostventaLine(pvNo, versionCode, Enum::"GomJob Works Line Type"::Cost, obraNo, description, blocked);
    end;

    /// <summary>
    /// Crea/reactiva (blocked=true) o marca Revertida (blocked=false) la línea auxiliar de la obra
    /// (Task No. = obraNo, Task Type = Posting/"Auxiliar", Qty = 1) en la obra Postventa, para el
    /// Line Type indicado (Sales = Líneas venta, Cost = Coste directo). Idempotente por la PK de
    /// GomJob Works Line (Works No., Version Code, Line Type, Task No.).
    /// </summary>
    local procedure UpsertPostventaLine(pvNo: Code[20]; versionCode: Code[20]; lineType: Enum "GomJob Works Line Type"; obraNo: Code[20]; description: Text[100]; blocked: Boolean)
    var
        WorksLine: Record "GomJob Works Line";
    begin
        if blocked then begin
            if WorksLine.Get(pvNo, versionCode, lineType, obraNo) then begin
                WorksLine."Adelante Revertida" := false;
                WorksLine.Modify(true);
            end else begin
                WorksLine.Init();
                WorksLine."Works No." := pvNo;
                WorksLine."Version Code" := versionCode;
                WorksLine."Line Type" := lineType;
                WorksLine."Task No." := obraNo;
                WorksLine."Job No." := pvNo;
                WorksLine."Task Type" := WorksLine."Task Type"::Posting; // "Auxiliar" en la UI de GomJob
                WorksLine.Description := CopyStr(description, 1, MaxStrLen(WorksLine.Description));
                WorksLine.Quantity := 1;
                WorksLine."Adelante Revertida" := false;
                WorksLine.Insert(true);
            end;
        end else begin
            if WorksLine.Get(pvNo, versionCode, lineType, obraNo) then begin
                WorksLine."Adelante Revertida" := true;
                WorksLine."Adelante Fecha Reversa" := Today();
                WorksLine.Modify(true);
            end;
        end;
    end;

    /// <summary>Bloquea la obra (atajo). La Postventa se resuelve por prefijo (sin selección).</summary>
    procedure BlockWork(obraNo: Code[20]): Text
    begin
        exit(SetObraBlocked(obraNo, true, ''));
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

    /// <summary>
    /// Crea una fila de Inventory Posting Setup por cada tipo de inventario de la lista CSV
    /// (ej. "MATERIALES,SUMINISTROS"), para el almacén de la obra. Idempotente. Cuenta de
    /// inventario fija (Inventario de producto en proceso).
    /// </summary>
    local procedure CreateInventoryPostingSetups(obraNo: Code[20]; tiposInventario: Text)
    var
        grupos: List of [Text];
        g: Text;
        locCode: Code[10];
        grp: Code[20];
    begin
        if tiposInventario = '' then
            exit;
        locCode := CopyStr(obraNo, 1, MaxStrLen(locCode));
        grupos := tiposInventario.Split(',');
        foreach g in grupos do begin
            grp := CopyStr(DelChr(g, '<>', ' '), 1, MaxStrLen(grp)); // trim espacios y ajustar a Code[20]
            if grp <> '' then
                EnsureInventoryPostingSetup(locCode, grp);
        end;
    end;

    local procedure EnsureInventoryPostingSetup(locationCode: Code[10]; postingGroup: Code[20])
    var
        InvtPostingSetup: Record "Inventory Posting Setup";
    begin
        if (locationCode = '') or (postingGroup = '') then
            exit;
        if InvtPostingSetup.Get(locationCode, postingGroup) then
            exit; // ya existe -> no duplicar
        InvtPostingSetup.Init();
        InvtPostingSetup.Validate("Location Code", locationCode);
        InvtPostingSetup.Validate("Invt. Posting Group Code", postingGroup);
        InvtPostingSetup.Validate("Inventory Account", InventoryAccountNo());
        InvtPostingSetup.Insert(true);
    end;

    local procedure InventoryAccountNo(): Code[20]
    begin
        exit('10-10-006-000-010'); // Inventario de producto en proceso (cuenta fija)
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
