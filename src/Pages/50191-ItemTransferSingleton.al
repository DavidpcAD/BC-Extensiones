// ════════════════════════════════════════════════════════════════════════════════
// Page 50191 "GJW Item Transfer Singleton"
// Propósito: API REST para procesar transferencias masivas de inventario
// Tipo: API Singleton (un solo registro activo)
// Endpoint: /adelante_construction_v1.0_itemTransferBulks
// ════════════════════════════════════════════════════════════════════════════════
page 50191 "GJW Item Transfer Singleton"
{
    // ═══ Configuración del tipo de página ═══
    PageType = API;  // Define que esta página es una API REST (no una página de UI)

    // ═══ Configuración de la ruta del endpoint OData ═══
    APIPublisher = 'adelante';      // Primer segmento de la ruta: nombre del publicador
    APIGroup = 'construction';      // Segundo segmento: grupo o módulo funcional
    APIVersion = 'v1.0';            // Tercer segmento: versión de la API

    // ═══ Nombres de las entidades para el endpoint ═══
    EntityName = 'itemTransferBulk';     // Nombre singular de la entidad (para GET de 1 registro)
    EntitySetName = 'itemTransferBulks'; // Nombre plural del conjunto (para GET de colección)
                                         // Esto genera la URL: /adelante_construction_v1.0_itemTransferBulks

    // ═══ Configuración de la tabla de datos ═══
    SourceTable = "Name/Value Buffer";   // Tabla base (tabla temporal para almacenar datos en memoria)
    SourceTableTemporary = true;         // La tabla solo existe en memoria, no persiste en BD

    // ═══ Configuración de claves y comportamiento ═══
    ODataKeyFields = ID;     // Campo que actúa como clave primaria para el endpoint OData
    DelayedInsert = true;    // Retrasar la inserción hasta que se completen todas las validaciones

    // ════════════════════════════════════════════════════════════════════════════
    // LAYOUT: Define los campos expuestos en la API
    // ════════════════════════════════════════════════════════════════════════════
    layout
    {
        area(content)  // Área de contenido de la página
        {
            repeater(Group)  // Grupo repetidor para mostrar múltiples registros (aunque solo usamos 1)
            {
                // ─────────────────────────────────────────────────────────────────
                // Campo 1: ID (identificador único del registro)
                // ─────────────────────────────────────────────────────────────────
                field(id; Rec.ID)  // 'id' es el nombre expuesto en API, 'Rec.ID' es el campo de la tabla
                {
                    Caption = 'Id';  // Etiqueta descriptiva del campo
                }

                // ─────────────────────────────────────────────────────────────────
                // Campo 2: transfersJSON (recibe el array JSON con las transferencias)
                // ─────────────────────────────────────────────────────────────────
                field(transfersJSON; TransfersJSON)  // 'transfersJSON' en API, 'TransfersJSON' es la variable
                {
                    Caption = 'Transfers JSON';  // Etiqueta del campo
                }

                // ─────────────────────────────────────────────────────────────────
                // Campo 3: ejecutar (trigger para iniciar el procesamiento)
                // ─────────────────────────────────────────────────────────────────
                field(ejecutar; Ejecutar)  // 'ejecutar' en API, 'Ejecutar' es la variable booleana
                {
                    Caption = 'Ejecutar';  // Etiqueta del campo

                    // Trigger que se ejecuta cuando el campo cambia de valor
                    trigger OnValidate()
                    begin
                        if Ejecutar then  // Si el campo se pone en true
                            ProcesarTransferencias();  // Llamar al procedimiento que procesa las transferencias
                    end;
                }

                // ─────────────────────────────────────────────────────────────────
                // Campo 4: resultado (retorna el mensaje de éxito o error)
                // ─────────────────────────────────────────────────────────────────
                field(resultado; Resultado)  // 'resultado' en API, 'Resultado' es la variable de texto
                {
                    Caption = 'Resultado';  // Etiqueta del campo
                    Editable = false;  // Solo lectura, no se puede modificar desde la API
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════════
    // VARIABLES GLOBALES: Almacenan los valores de los campos de la API
    // ════════════════════════════════════════════════════════════════════════════
    var
        TransfersJSON: Text;   // Variable que almacena el JSON con las transferencias recibidas
        Ejecutar: Boolean;     // Variable booleana que al ponerse en true ejecuta el proceso
        Resultado: Text;       // Variable que almacena el resultado del procesamiento

    // ════════════════════════════════════════════════════════════════════════════
    // Trigger: OnOpenPage
    // Propósito: Se ejecuta cuando se abre la página (al hacer GET a la API)
    // Acción: Crea un registro temporal único para la API singleton
    // ════════════════════════════════════════════════════════════════════════════
    trigger OnOpenPage()
    begin
        Rec.DeleteAll();  // Eliminar todos los registros existentes de la tabla temporal
        Rec.Init();       // Inicializar un nuevo registro con valores por defecto
        Rec.ID := 1;      // Asignar ID = 1 (clave primaria única para el singleton)
        Rec.Name := 'ItemTransferBulk';  // Asignar nombre identificativo al registro
        Rec.Insert();     // Insertar el registro en la tabla temporal
    end;

    // ════════════════════════════════════════════════════════════════════════════
    // Procedimiento: ProcesarTransferencias (Local)
    // Propósito: Procesar las transferencias llamando al codeunit correspondiente
    // Se ejecuta cuando: El campo 'ejecutar' se pone en true desde PowerApps
    // ════════════════════════════════════════════════════════════════════════════
    local procedure ProcesarTransferencias()
    var
        TransferCU: Codeunit "GJW Item Transfer Bulk";  // Variable para el codeunit que procesa transferencias
    begin
        // ═══ PASO 1: Resetear el campo ejecutar para evitar ejecuciones múltiples ═══
        Ejecutar := false;  // Volver a poner el campo en false inmediatamente

        // ═══ PASO 2: Validar que se recibió JSON ═══
        if TransfersJSON = '' then begin  // Si no hay JSON
            Resultado := 'ERROR: No se recibió JSON de transferencias';  // Asignar mensaje de error
            exit;  // Salir del procedimiento sin procesar
        end;

        // ═══ PASO 3: Llamar al codeunit para procesar las transferencias ═══
        // El codeunit crea las líneas de diario, las valida y ejecuta el posting automáticamente
        Resultado := TransferCU.ProcessTransfers(TransfersJSON);  // Ejecutar y guardar resultado
    end;  // Fin del procedimiento ProcesarTransferencias
}  // Fin de la página API

// ════════════════════════════════════════════════════════════════════════════════
// FIN DEL ARCHIVO
// ════════════════════════════════════════════════════════════════════════════════  // Fin de la página API

// ══════════════════════════════════════════════════════════════════════════════
// FIN DEL ARCHIVO
// ══════════════════════════════════════════════════════════════════════════════
