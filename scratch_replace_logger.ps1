$files = Get-ChildItem -Path "C:\src\VERASSO\lib" -Recurse -Filter "*.dart"

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($content -match "debugPrint") {
        # Replace debugPrint with appLogger.d
        $content = $content -replace "debugPrint\(", "appLogger.d("
        
        # Check if import is needed
        if ($content -notmatch "package:verasso/core/utils/logger.dart") {
            # Find the last import
            $lines = $content -split "`r`n|`n"
            $lastImportIndex = -1
            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i].StartsWith("import ")) {
                    $lastImportIndex = $i
                }
            }
            
            $importStmt = "import 'package:verasso/core/utils/logger.dart';"
            if ($lastImportIndex -ge 0) {
                # Insert after last import
                $lines = $lines[0..$lastImportIndex] + $importStmt + $lines[($lastImportIndex+1)..($lines.Length-1)]
            } else {
                # Insert at top
                $lines = $importStmt, $lines
            }
            $content = $lines -join "`n"
        }
        
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        Write-Host "Updated $($file.Name)"
    }
}
