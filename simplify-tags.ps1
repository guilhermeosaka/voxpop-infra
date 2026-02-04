# PowerShell script to simplify tags in Terraform files
# Replaces tags = merge(...) with tags = { Name = "..." }

$files = Get-ChildItem -Path "c:\Users\osaka\Projects\voxpop\voxpop.infra" -Recurse -Filter "*.tf"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # Pattern to match tags = merge( ... ) blocks
    $pattern = '(?s)tags\s*=\s*merge\(\s*var\.tags,\s*\{\s*Name\s*=\s*(".*?")\s*Environment\s*=\s*var\.environment\s*ManagedBy\s*=\s*"terraform"\s*\}\s*\)'
    
    # Replace with simple tags
    $replacement = 'tags = { Name = $1 }'
    
    $newContent = $content -replace $pattern, $replacement
    
    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        Write-Host "Updated: $($file.FullName)"
    }
}

Write-Host "Done!"
