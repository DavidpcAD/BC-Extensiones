page 50153 "GJW Init ItemAvailBuffer Page"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'Inicializar API de Disponibilidad';
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(InfoGroup)
            {
                Caption = 'Estado';
                field(StatusText; StatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Resultado';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RunInit)
            {
                Caption = '⚙️ Inicializar API';
                Image = Process;
                ApplicationArea = All;

                trigger OnAction()
                var
                    InitAPI: Codeunit "GJW Init ItemAvailBuffer API";
                begin
                    Message('⏳ Iniciando proceso de registro de API...');
                    InitAPI.Run();
                    StatusText := '✅ Inicialización completada correctamente.';
                end;
            }
        }
    }

    var
        StatusText: Text[100];
}
