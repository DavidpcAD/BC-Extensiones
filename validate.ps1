# Script de validación de nombres de archivo vs IDs de objeto
$srcPath = "c:\Users\David\OneDrive - Adelante Desarrollos\Escritorio\AdelanteAPI_Daniel_Original\src"
Set-Location $srcPath

$errors = @()
$validated = 0

Get-ChildItem -Recurse -Filter *.al | ForEach-Object {
    $fileName = $_.Name
    $filePath = $_.FullName.Replace($srcPath + '\', '')
    
    # Extraer número del nombre de archivo
    if ($fileName -match '^(\d+)-') {
        $fileNumber = $matches[1]
        
        # Leer primeras líneas del archivo
        $content = (Get-Content $_.FullName -TotalCount 10) -join ' '
        
        # Buscar declaración de objeto
        if ($content -match '(table|page|codeunit|permissionset)\s+(\d+)\s+"') {
            $objectType = $matches[1]
            $objectId = $matches[2]
            
            if ($fileNumber -ne $objectId) {
                $errors += [PSCustomObject]@{
                    'Archivo' = $fileName
                    'Ruta' = $filePath
                    'ArchivoNum' = $fileNumber
                    'ObjetoReal' = "$objectType $objectId"
                }
            } else {
                $validated++
            }
        }
    }
}

Write-Host "`n═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  VALIDACIÓN DE ESTRUCTURA DEL PROYECTO" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════`n" -ForegroundColor Cyan

if ($errors.Count -gt 0) {
    Write-Host "❌ ENCONTRADAS $($errors.Count) INCONSISTENCIAS:`n" -ForegroundColor Red
    $errors | ForEach-Object {
        Write-Host "  Archivo: $($_.Archivo)" -ForegroundColor Yellow
        Write-Host "    Ruta: $($_.Ruta)" -ForegroundColor Gray
        Write-Host "    Número en archivo: $($_.ArchivoNum)" -ForegroundColor Red
        Write-Host "    Objeto real: $($_.ObjetoReal)" -ForegroundColor Green
        Write-Host ""
    }
} else {
    Write-Host "✅ TODOS LOS ARCHIVOS VALIDADOS CORRECTAMENTE" -ForegroundColor Green
    Write-Host "   Total archivos: $validated" -ForegroundColor White
}

Write-Host "═══════════════════════════════════════════`n" -ForegroundColor Cyan
