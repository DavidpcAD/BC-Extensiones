codeunit 50261 "Produccion Pendiente Guard"
{
    // Pared contra el sobreavance de producción (incidente 2026-10-01).
    //
    // «Traer tareas de proyecto» inserta las líneas con "Maximum Quantity" = 1 y
    // Quantity = 0, y deja "Outstanding Amount" calculado contra la Maximum
    // Quantity: la línea nace con el 100 % del presupuesto como pendiente. El
    // report 70720583 «GomJob Register Production» postea ese pendiente, así que
    // registrar la obra genera el asiento del presupuesto entero con las
    // cantidades en cero (VC-F.12 línea 1.1: 725.399,30 = (1 - 0,8875) x 6.447.993,81).
    //
    // Acá se fuerza la identidad sana —la misma que deja el OnValidate de
    // Quantity— antes de que la fila se escriba. En una línea sana ya se cumple,
    // así que no cambia nada; si Goom corrige el bug sigue sin cambiar nada y se
    // puede retirar sin prisa.

    [EventSubscriber(ObjectType::Table, Database::"GomJob Works Production Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure CuadrarAlInsertar(var Rec: Record "GomJob Works Production Line"; RunTrigger: Boolean)
    begin
        CuadrarPendiente(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GomJob Works Production Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CuadrarAlModificar(var Rec: Record "GomJob Works Production Line"; RunTrigger: Boolean)
    begin
        CuadrarPendiente(Rec);
    end;

    local procedure CuadrarPendiente(var Linea: Record "GomJob Works Production Line")
    var
        Correcto: Decimal;
    begin
        Correcto := (Linea.Quantity - Linea."Registered Quantity") * Linea."Unit Amount";
        if Linea."Outstanding Amount" <> Correcto then
            Linea."Outstanding Amount" := Correcto;
    end;
}
