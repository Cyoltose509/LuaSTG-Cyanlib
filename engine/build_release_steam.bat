@cd %~dp0
@echo %cd%
@setlocal
    :: values
    @set SOURCE=%cd%\luastg
    @set BUILDROOT=%cd%\build
    @set BUILD=%BUILDROOT%\release_steam
    @set BUILD32=%BUILD%\x86
    @set BUILD64=%BUILD%\amd64
    @set PACKAGE_CACHE=%BUILDROOT%\packages
    @set CUSTOM=%cd%\release_steam
    
    :: build and install directory
    mkdir %BUILDROOT%
    mkdir %BUILD%
    mkdir %BUILD32%
    mkdir %BUILD64%
    mkdir %PACKAGE_CACHE%
    
    :: x86
    ::@echo ============================ build Win32 ===========================
    ::cmake -S %SOURCE% -B %BUILD32% -G "Visual Studio 17 2022" -A Win32 -D CPM_SOURCE_CACHE=%PACKAGE_CACHE% -D LUASTG_RESDIR=%CUSTOM%
    ::cmake --build %BUILD32% --target LuaSTG --config Release --clean-first

    :: amd64
    @echo ============================= build x64 ============================
    cmake -S %SOURCE% -B %BUILD64% -G "Visual Studio 17 2022" -A x64 -D CPM_SOURCE_CACHE=%PACKAGE_CACHE% -D LUASTG_RESDIR=%CUSTOM%
    cmake --build %BUILD64% --target LuaSTG --config Release --clean-first
    
    @echo ============================= build finish ============================

    del  "%cd%\..\game\LuaSTG.exe"
    copy "%BUILD64%\LuaSTG\Release\LuaSTGSub.exe" "%cd%\..\game\LuaSTG.exe"
@endlocal
