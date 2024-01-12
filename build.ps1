Param(
    [Parameter()]
    [switch]$init,
    [switch]$run,
    [switch]$rel,
    [ValidateSet(
        "Unix Makefiles",
        "MinGW Makefiles",
        "Ninja",
        "JOM"
    )]
    [string]$gen = "MinGW Makefiles",
    [bool]$graph = $true
);

[string]$ExeName;
[string]$CMakeCommand;
[string]$BuildType = if ($rel) { "Release" } else { "Debug" };
[string]$DependenciesGraph = if ($graph) { " --graphviz=Dependencies.dot" } else { "" };

$CMakeCommand = "cmake .. -G `"$gen`" -DCMAKE_BUILD_TYPE=$BuildType$DependenciesGraph";

try {
    Write-Host -Object "-[Starting Build]" -BackgroundColor Blue -ForegroundColor Black;

    # Check if the build folder exists.
    if (Join-Path -Path $PSScriptRoot -ChildPath build | Test-Path) {
        Remove-Item -Path $PSScriptRoot\build -Force -Recurse -ErrorAction Stop;
    }
    
    # Creating and configuring the build directory.
    New-Item -Path $PSScriptRoot -Name build -ItemType Directory -ErrorAction Stop;
    Set-Location -Path $PSScriptRoot\build -ErrorAction Stop;

    # Build process.
    try {
        # Configure Build files generation.
        Invoke-Expression -Command $CMakeCommand -ErrorAction Stop;
        Write-Host -Object "-[Build Files Created]" -BackgroundColor Blue -ForegroundColor Black;
        Write-Host -Object $CMakeCommand -BackgroundColor Blue -ForegroundColor Black;
        
        # Build process configuration.
        try {
            switch ($gen) {
                "MinGW Makefiles" {
                    Invoke-Expression -Command "cmake --build ." -ErrorAction Stop;
                }
                "Ninja" {
                    Invoke-Expression -Command "Ninja" -ErrorAction Stop;
                }
            }
        }
        catch {
            Write-Host -Object "-[Error While Building Project]" -BackgroundColor Red -ForegroundColor Black;
            Set-Location -Path $PSScriptRoot;
        }
    }
    catch {
        Write-Host -Object "-[Error While Generating Build Files]" -BackgroundColor Red -ForegroundColor Black;
        Set-Location -Path $PSScriptRoot;
    }
    
    # Run executable.
    if ($run) {
        try {
            Set-Location -Path $PSScriptRoot\build\app\Debug -ErrorAction Stop;
    
            $ExeName = Invoke-Expression "dir *.exe" | Select-Object -ExpandProperty Name -ErrorAction Stop;
            Write-Host -Object "-[Executing: $ExeName]" -BackgroundColor Blue -ForegroundColor Black;
            Invoke-Expression -Command ".\$ExeName" -ErrorAction Stop;
        }
        catch {
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
