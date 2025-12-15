# Script para reorganizar proyecto AdelanteAPI
$srcPath = "c:\Users\David\OneDrive - Adelante Desarrollos\Escritorio\AdelanteAPI_Daniel_Original\src"
Set-Location $srcPath

# Mover Pages (solo los que existen)
$pages = @(
    @("GJWItemAvailabilityAPI.al", "Pages\50100-ItemAvailabilityAPI.al"),
    @("GJWItemAvailabilityUnboundAPI.al", "Pages\50101-ItemAvailUnboundAPI.al"),
    @("JobTaskAPI.al", "Pages\50102-JobTaskAPI.al"),
    @("GJWProdLineAPI.al", "Pages\50103-ProdLineAPI.al"),
    @("GJWProdLineImportAPI.al", "Pages\50104-ProdLineImportAPI.al"),
    @("GJWProdLineStatusImportAPI.al", "Pages\50105-ProdLineStatusImportAPI.al"),
    @("GJWWarehouseQuantityAPI.al", "Pages\50106-WarehouseQtyAPI.al"),
    @("GJWWarehouseQuantityUnboundAPI.al", "Pages\50107-WarehouseQtyUnboundAPI.al"),
    @("GJWWorksAPI.al", "Pages\50108-WorksAPI.al"),
    @("GJWWorksDecompAPI.al", "Pages\50109-WorksDecompAPI.al"),
    @("GJWWorksDecompImportAPI.al", "Pages\50110-WorksDecompImportAPI.al"),
    @("GJWDecompRead.al", "Pages\50111-DecompReadAPI.al"),
    @("GJWWorkVersionAPI.al", "Pages\50112-WorkVersionAPI.al"),
    @("GJWWorksDecompLines.al", "Pages\50113-WorksDecompLines.al"),
    @("GJWItemLedgerEntryAPI.al", "Pages\50114-ItemLedgerEntryAPI.al"),
    @("GJWWarehouse.al", "Pages\50115-WarehouseAPI.al"),
    @("GJWWorksDecompBulkAPI.al", "Pages\50116-WorksDecompBulkAPI.al"),
    @("GJWWorksDecompBulkSingleton.al", "Pages\50117-WorksDecompBulkSingleton.al"),
    @("GJWBulkOperationsAPI.al", "Pages\50118-BulkOperationsAPI.al"),
    @("GJWWorkLines.al", "Pages\50119-WorkLinesAPI.al"),
    @("ItemAPI.al", "Pages\50120-ItemAPI.al"),
    @("GJWItemAvailabilityByLocationAPI.al", "Pages\50121-ItemAvailByLocationAPI.al"),
    @("GJWItemAvailabilityExtendedAPI.al", "Pages\50122-ItemAvailExtendedAPI.al"),
    @("GJWItemJournalLinesAPI.al", "Pages\50123-ItemJournalLinesAPI.al"),
    @("GJWItemJournalLineImportAPI.al", "Pages\50124-ItemJnlLineImportAPI.al"),
    @("JobJournalLineAPI.al", "Pages\50125-JobJournalLineAPI.al"),
    @("GJWJobJournalLineImportAPI.al", "Pages\50126-JobJnlLineImportAPI.al"),
    @("GJWItemJournalLinePosImportAPI.al", "Pages\50127-ItemJnlLinePosImportAPI.al"),
    @("GJWItemJournalLineNegImportAPI.al", "Pages\50128-ItemJnlLineNegImportAPI.al"),
    @("GJWJobJournalLinePosImportAPI.al", "Pages\50129-JobJnlLinePosImportAPI.al"),
    @("GJWJobJournalLineNegImportAPI.al", "Pages\50130-JobJnlLineNegImportAPI.al"),
    @("GJWWorksDecompLinePage.al", "Pages\50131-WorksDecompLinePage.al"),
    @("GJWPostedProdBufferAPI.al", "Pages\50140-PostedProdBufferAPI.al"),
    @("GJWPostedProdLinesAPI.al", "Pages\50141-PostedProdLinesAPI.al"),
    @("GJWItemAvailabilityBufferAPI.al", "Pages\50149-ItemAvailBufferAPI.al"),
    @("GJWInitItemAvailBufferPage.al", "Pages\50150-InitItemAvailBufferPage.al"),
    @("GJWItemJournalTemplateAPI.al", "Pages\50151-ItemJnlTemplateAPI.al"),
    @("GJWItemJournalBatchesAPI.al", "Pages\50152-ItemJnlBatchesAPI.al"),
    @("JobJournalTemplateAPI.al", "Pages\50160-JobJnlTemplateAPI.al"),
    @("JobJournalBatchAPI.al", "Pages\50161-JobJnlBatchAPI.al")
)

foreach ($item in $pages) {
    if (Test-Path $item[0]) {
        Move-Item -Force $item[0] $item[1] -ErrorAction SilentlyContinue
    }
}
Write-Host "Pages movidas" -ForegroundColor Green

# Mover Tables
$tables = @(
    @("GJWItemAvailability.al", "Tables\50100-ItemAvailability.al"),
    @("GJWWarehouseQuantity.al", "Tables\50101-WarehouseQuantity.al"),
    @("GJWWarehouseQuantityBuffer.al", "Tables\50148-WarehouseQtyBuffer.al"),
    @("GJWItemAvailabilityBuffer.al", "Tables\50149-ItemAvailBuffer.al")
)

foreach ($item in $tables) {
    if (Test-Path $item[0]) {
        Move-Item -Force $item[0] $item[1] -ErrorAction SilentlyContinue
    }
}
Write-Host "Tables movidas" -ForegroundColor Green

# Mover TableExtensions
$tableExts = @(
    @("GJWWarehouseQuantityExt.al", "Tables\50127-WarehouseQtyExt.al"),
    @("GJWWorkVersion.al", "Tables\50128-WorkVersionExt.al"),
    @("GJWWorksLineExt.al", "Tables\50129-WorksLineExt.al"),
    @("GJWWorksDecompLineExt.al", "Tables\50130-WorksDecompLineExt.al"),
    @("GJWItemJournalLineExt.al", "Tables\50133-ItemJnlLineExt.al"),
    @("GJWItemLedgerEntryExt.al", "Tables\50135-ItemLedgerEntryExt.al")
)

foreach ($item in $tableExts) {
    if (Test-Path $item[0]) {
        Move-Item -Force $item[0] $item[1] -ErrorAction SilentlyContinue
    }
}
Write-Host "Table Extensions movidas" -ForegroundColor Green

# Mover PageExtensions
$pageExts = @(
    @("GJWWorksLinePageExt.al", "Pages\50131-WorksLinePageExt.al"),
    @("GJWWorksDecompPageExt.al", "Pages\50132-WorksDecompPageExt.al"),
    @("GJWItemJournalLinePageExt.al", "Pages\50134-ItemJnlLinePageExt.al")
)

foreach ($item in $pageExts) {
    if (Test-Path $item[0]) {
        Move-Item -Force $item[0] $item[1] -ErrorAction SilentlyContinue
    }
}
Write-Host "Page Extensions movidas" -ForegroundColor Green

# Mover Permissions
if (Test-Path "GJWProdLinesPerm.al") {
    Move-Item -Force "GJWProdLinesPerm.al" "Permissions\50100-AdelanteAPIPerm.al" -ErrorAction SilentlyContinue
}
Write-Host "Permissions movido" -ForegroundColor Green

Write-Host "`nReorganización completada!" -ForegroundColor Cyan
Write-Host "Estructura:" -ForegroundColor Yellow
Write-Host "  - Codeunits/" -ForegroundColor White
Write-Host "  - Pages/" -ForegroundColor White
Write-Host "  - Tables/" -ForegroundColor White
Write-Host "  - Permissions/" -ForegroundColor White
