Param(
    [Parameter()]
    [switch]$init,
    [switch]$run,
    [switch]$rel
);
[string]$ExeName;

try {
    Write-Host -Object "-[Starting Build]" -BackgroundColor Blue -ForegroundColor Black;

    # Check if the build folder exists.
    if(Join-Path -Path $PSScriptRoot -ChildPath build | Test-Path){
        Remove-Item -Path $PSScriptRoot\build -Force -Recurse -ErrorAction Stop;
    }
    
    # Creating and configuring the build directory.
    New-Item -Path $PSScriptRoot -Name build -ItemType Directory -ErrorAction Stop;
    Set-Location -Path $PSScriptRoot\build -ErrorAction Stop;

    # Build type configuration.
    Invoke-Expression -Command "cmake .. -DCMAKE_BUILD_TYPE=${$rel? "Release" : "Debug"} --graphviz=Dependencies.dot" -ErrorAction Stop;
    Invoke-Expression -Command "cmake --build ." -ErrorAction Stop;

    # Run executable.
    if($run){
        try{
            Set-Location -Path $PSScriptRoot\build\app\Debug -ErrorAction Stop;
    
            $ExeName = Invoke-Expression "dir *.exe" | Select-Object -ExpandProperty Name -ErrorAction Stop;
            Write-Host -Object "-[Executing: $ExeName]" -BackgroundColor Blue -ForegroundColor Black;
            Invoke-Expression -Command ".\$ExeName" -ErrorAction Stop;
        }catch{
            Write-Host -Object "-[Error Running Executable]" -BackgroundColor Red -ForegroundColor Black;
            Set-Location -Path $PSScriptRoot -ErrorAction Ignore;
        }
    }

    Set-Location -Path $PSScriptRoot -ErrorAction Ignore;
}
catch {
    Write-Host -Object "-[Unspected Error]" -BackgroundColor Red -ForegroundColor Black;
    Set-Location -Path $PSScriptRoot;
}
