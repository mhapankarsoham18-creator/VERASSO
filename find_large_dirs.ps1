$path = "C:\Users"
$cutoff = 500MB
Get-ChildItem -Path $path -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $dirSize = (Get-ChildItem -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($dirSize -gt $cutoff) {
        [PSCustomObject]@{
            Path   = $_.FullName
            SizeMB = [math]::Round($dirSize / 1MB, 2)
        }
    }
} | Sort-Object SizeMB -Descending | Format-Table -AutoSize | Out-File d:\Games\VERASSO\Users_Sizes.txt
