codeunit 50152 "GJW Init ItemAvailBuffer API"
{
    Subtype = Normal;
    Access = Public;  // 👈 NECESARIO para que se muestre en el buscador

    trigger OnRun()
    var
        PageAPI: Page "GJW ItemAvailBuffer API";
    begin
        Message('⏳ Inicializando API temporal de disponibilidad...');

        // Ejecuta la página API una vez (sin mostrarla)
        PageAPI.Run();

        Message('✅ Inicialización completada. Vuelve a probar el endpoint OData.');
    end;
}
