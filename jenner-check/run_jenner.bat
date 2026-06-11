@echo off
rem run_jenner.bat - Windows runner for Jenner compatibility checks.
rem
rem Usage:   run_jenner.bat <script.sas> [response.json]
rem
rem Submits a single .sas file to api.jenneranalytics.com. For
rem bundle-aware mode (autoexec.sas + script.sas concatenation) on
rem Windows, use WSL and invoke run_jenner.sh instead, or wait for the
rem Windows CI runner that will validate a bundle-aware .bat.
rem
rem Output:  response.json contains the API response. Read it back in SAS:
rem     filename resp 'response.json';
rem     libname  resp JSON fileref=resp;
rem     proc print data=resp.root; run;
rem
rem Requires: curl.exe (ships with Windows 10+ at C:\Windows\System32).

setlocal

if "%~1"=="" (
  echo Usage: %~nx0 ^<script.sas^> [response.json]
  exit /b 2
)

set SCRIPT=%~1
set OUT=%~2
if "%OUT%"=="" set OUT=response.json

set HOST=api.jenneranalytics.com

curl.exe -sS -X POST "https://%HOST%/v1/run" ^
  -F "script=@%SCRIPT%;type=application/x-sas" ^
  -F "deterministic=1" ^
  -F "timeout=60" ^
  -o "%OUT%"

if errorlevel 1 (
  echo curl failed with errorlevel %errorlevel%
  exit /b 1
)

echo Response written to %OUT%
exit /b 0
