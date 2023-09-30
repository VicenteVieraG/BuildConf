Param(
    [Parameter()]
    [switch]$run 
);
[string]$ExeName;

try {
    Write-Host -Object "-[Starting Build]" -BackgroundColor Blue -ForegroundColor Black;

    # Check if the build folder exists.
    if(Join-Path -Path $PSScriptRoot -ChildPath build | Test-Path){
        Remove-Item -Path build -Force -Recurse -ErrorAction Stop;
    }
    
    New-Item -Path .\ -Name build -ItemType Directory -ErrorAction Stop;
    Set-Location -Path .\build;
    Invoke-Expression -Command "cmake .." -ErrorAction Stop;
    Invoke-Expression -Command "cmake --build ." -ErrorAction Stop;

    if($run){
        Set-Location -Path .\app\debug -ErrorAction Stop;
        $ExeName = Invoke-Expression "dir *.exe" | Select-Object -ExpandProperty Name -ErrorAction Stop;
        Write-Host -Object "-[Executing: $ExeName]" -BackgroundColor Blue -ForegroundColor Black;
        Invoke-Expression -Command ".\$ExeName" -ErrorAction Stop;
    }

    Set-Location -Path $PSScriptRoot -ErrorAction Ignore;
}
catch {
    Write-Host -Object "-[Unspected Error]" -BackgroundColor Red -ForegroundColor Black;
    Set-Location -Path $PSScriptRoot;
}
