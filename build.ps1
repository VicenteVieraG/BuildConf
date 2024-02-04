<#
.SYNOPSIS
Create, build, and debug C++ proyects using CMake with ease.

.DESCRIPTION
Script to help managing CMake proyects using C++.
Creates an advanced proyect folder structure ensuring
efficiency mahaging all your proyect files. The script takes care of
the CMake configurations needed to build and debug your proyect.

.PARAMETER init
Creates a new C++ proyect in the scripts current folder.
If the parameter git is used alongside init, it will create a local git repo
and if gith is used, a remote repo will be created with the selected name.

.PARAMETER run
If enabeled, this parameter runs the executable after build.

.PARAMETER rel
Sets the build mode to release.
If ommited, will build with debug mode by default.

.PARAMETER gen
Sets the generator used by CMake to build the proyect.
You can select the generator form the following list:

- Unix Makefiles
- MinGW Makefiles
- Ninja
- JOM

Set a generator in the following way:

.\build -gen="Ninja"

.PARAMETER graph
Wether or not to build a graphviz document containing a visualization of the
dependency tree.
This option is enabled by default.

.INPUTS
Switch values.
The script can verify wether or not the switch flags have been added.

Strings.
Some parameters require an string as a value. The string needs to be between "" or ''.

.OUTPUTS
If init is selected, the program will create the following folder structure:

SCRIPT_ROOT:
|- app: // Contains the main files of your application.
    |- CMakeLists.txt
|- external: // Used to include Git submodules.
|- include: // Contains all your header files.
    |- CMakeLists.txt
|- src: // Contains your actual source files.
    |- CMakeLists.txt
|- CMakeLists.txt
|- build.ps1
|- .gitignore // If git or gith options are enabeled.

.EXAMPLE
.NOTES
Author: VicenteVieraG

To dos:
- Validate if the selected generator exists in the system and warn the user if it doesn't.
- Create the init configuration.
    - Implement the template switch parameter to generate the initial files.
        - Add different template variables and styles.
- Implement the git and gith parameters functions.
- Validate parameters.
    - Validation for init
        - init can only used with the parameters template, git or gith.

.LINK
Link to repo:
https://github.com/VicenteVieraG/BuildConf
#>

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
[string]$DependenciesGraph = if ($graph) { "--graphviz=Dependencies.dot" } else { "" };

$CMakeCommand =
"cmake .. " `
    + "-G `"$gen`" " `
    + "-DCMAKE_BUILD_TYPE=$BuildType "`
    + "$DependenciesGraph";

$Folders = @("app", "config", "external", "include", "src");

if ($init) {
    Write-Host -Object "-[Initializing Proyect]" -BackgroundColor Blue -ForegroundColor Black;

    # Create the folder structure.
    $DirectoryInfoList = New-Object System.Collections.Generic.List[[System.IO.DirectoryInfo]];

    foreach ($folder in $Folders) {
        [System.IO.DirectoryInfo]$NewFolder =
        New-Item -Path $PSScriptRoot -Name $folder -ItemType Directory -Force -ErrorAction Stop;
    
        $DirectoryInfoList.Add($NewFolder);
    }

    $DirectoryInfoList | Format-Table Mode, LastWriteTime, Name -AutoSize;
    Write-Host -Object "-[Folder Structure Created]`n" -BackgroundColor Green -ForegroundColor Black;

    Write-Host -Object "-[Creating CMakeLists Configurations]" -BackgroundColor Blue -ForegroundColor Black;
    
    # Creating the CMakeLists root file.
    [string]$CMakeVersion = Invoke-Expression "cmake --version" -ErrorAction Stop;
    if ($CMakeVersion -match "\d+\.\d+\.\d+") {
        $CMakeVersion = $Matches[0];
        Write-Host -Object "-[CMake Version Found]: $CMakeVersion"
    }
    else {
        Write-Host -Object "-[No CMake Version Found]" -BackgroundColor Red -ForegroundColor Black;
    }

    [string]$CMakeListsRoot = 
    @"
cmake_minimum_required(VERSION $CMakeVersion)

project(__PROJECT_NAME__ VERSION 0.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_COMPILER C:\\mingw64\\bin\\clang++)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY `${CMAKE_BINARY_DIR}\\bin)

add_subdirectory(config)
add_subdirectory(external)
add_subdirectory(src)
add_subdirectory(include)
add_subdirectory(app)
"@

    $FileInfoList = New-Object System.Collections.Generic.List[[System.IO.FileInfo]];

    $Folders | ForEach-Object -Begin {
        [System.IO.FileInfo]$RootFile =
        New-Item -Path $PSScriptRoot -Name CMakeLists.txt -ItemType File -Value $CMakeListsRoot -Force -ErrorAction Stop;
        
        $FileInfoList.Add($RootFile);
    } -Process {
        [System.IO.FileInfo]$File =
        New-Item -Path $PSScriptRoot\$_ -Name CMakeLists.txt -ItemType File -Force -ErrorAction Stop;
        
        $FileInfoList.Add($File);
    } -End {
        $FileInfoList | Format-Table Mode, LastWriteTime, Lenght, Name -AutoSize;
    }

    Write-Host -Object "-[CMakeLists Configured]" -BackgroundColor Green -ForegroundColor Black;
}
# Else Created for debug purposes future delete.
else {
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
            Write-Host -Object "-[Build Files Created]" -BackgroundColor Green -ForegroundColor Black;
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
                Set-Location -Path $PSScriptRoot\build\app\bin -ErrorAction Stop;
        
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
}
