@ECHO OFF
@echo:
@echo:
ECHO Generating Visual Studio Solution (64 bit)
@echo:
@echo:
call "%VS140COMNTOOLS%..\..\VC\bin\amd64\vcvars64.bat"
:: remove any generated sources
if exist "%~p0Artifacts\Build\Source\Generated\" rd /q /s "%~p0Artifacts\Build\Source\Generated\"
:: get current foldername
set "cdir=%~dp0"
:: for loop requires removing trailing backslash from %~dp0 output
set "cdir=%cdir:~0,-1%"
for %%i IN ("%cdir%") do set "foldername=%%~nxi"
:: run cmake
cmake -E make_directory "..\%foldername%-VS2015" && cmake -E chdir "..\%foldername%-VS2015" cmake %~dp0 -G "Visual Studio 14 2015 Win64" -DATOMIC_D3D11=1
@echo:
ECHO Solution created in ..\%foldername%-VS2015
@echo:
