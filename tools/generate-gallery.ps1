<#
    generate-gallery.ps1
    --------------------------------------------------------------
    Liest alle Bilddateien im Ordner "images/" und schreibt daraus
    automatisch das Manifest "images/gallery.js". So musst du Bilder
    nur in den Ordner legen und dieses Skript einmal ausführen.

    Aufruf (im Projektordner):
        powershell -ExecutionPolicy Bypass -File tools/generate-gallery.ps1

    Oder Rechtsklick auf die Datei -> "Mit PowerShell ausführen".

    Reihenfolge: alphabetisch nach Dateiname. Willst du eine eigene
    Reihenfolge, benenne die Bilder z. B. 01-..., 02-... usw.
#>

$ErrorActionPreference = 'Stop'

# Projekt-Wurzel = ein Ordner über diesem Skript (tools/..)
$root      = Split-Path -Parent $PSScriptRoot
$imagesDir = Join-Path $root 'images'
$manifest  = Join-Path $imagesDir 'gallery.js'

if (-not (Test-Path $imagesDir)) {
    Write-Error "Ordner nicht gefunden: $imagesDir"
    return
}

# Unterstützte Bildformate
$extensions = '.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif'

$files = Get-ChildItem -Path $imagesDir -File |
    Where-Object { $extensions -contains $_.Extension.ToLower() } |
    Sort-Object Name

# Zeilen für das Manifest bauen (Dateinamen in Anführungszeichen)
$entries = $files | ForEach-Object { '    "' + $_.Name + '",' }
$list = if ($entries) { ($entries -join "`r`n") } else { '' }

# Kommentar bewusst ohne Umlaute halten: PowerShell 5.1 liest dieses Skript
# je nach System als ANSI ein, wodurch Umlaute in der Ausgabe zerschossen
# wuerden. Reiner ASCII-Header ist hier robust.
$header = @'
/* ============================================================
   Bilder-Manifest fuer die Galerie  (automatisch erzeugt)
   ------------------------------------------------------------
   Diese Datei wurde von tools/generate-gallery.ps1 erzeugt.
   Manuelle Aenderungen werden beim naechsten Lauf ueberschrieben.
   Bilder einfach in den Ordner "images/" legen und das Skript
   erneut ausfuehren.
   ============================================================ */
window.GALLERY = [
'@

$footer = @'
];
'@

$content = if ($list) {
    "$header`r`n$list`r`n$footer`r`n"
} else {
    "$header$footer`r`n"
}

# Als UTF-8 (ohne BOM) schreiben, damit der Browser es sauber liest
[System.IO.File]::WriteAllText($manifest, $content, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Galerie-Manifest aktualisiert: $manifest"
Write-Host ("Gefundene Bilder: {0}" -f $files.Count)
$files | ForEach-Object { Write-Host "  - $($_.Name)" }
