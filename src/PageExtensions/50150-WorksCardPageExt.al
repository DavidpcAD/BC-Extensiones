// Botón "Sincronizar tareas" en la FICHA de la Obra (GomJob Works Card, 70720577).
// Contraparte de "Actualizar tareas proyecto" de Goom: ese va Obra -> tareas del proyecto;
// este trae las tareas de Registro del proyecto -> líneas de la Obra (ej. SSO, HER) que
// todavía no existen. Promovido estilo Goom (Process) para salir en la fila del ribbon.
pageextension 50150 "GJW Works Card Page Ext" extends "GomJob Works Card"
{
    actions
    {
        addlast(CreateJob)
        {
            action(GJWSyncTasksToWorks)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sincronizar tareas';
                Image = UpdateXML;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Crea en la obra las tareas de registro del proyecto (ej. SSO, HER) que todavía no tienen línea. Las existentes se omiten.';

                trigger OnAction()
                var
                    SyncTasksToWorks: Codeunit "GJW Sync Tasks To Works";
                    TasksCreated: Integer;
                    TasksSkipped: Integer;
                    ResultMessage: Text;
                    ErrorMessage: Text;
                begin
                    if SyncTasksToWorks.SyncTasks(Rec."No.", '', TasksCreated, TasksSkipped, ResultMessage, ErrorMessage) then
                        Message(ResultMessage)
                    else
                        Error(ErrorMessage);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
