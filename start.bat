@echo off

%1 %2
net session >nul 2>&1 && goto :Admin
mshta vbscript:createobject("shell.application").shellexecute("%~s0","goto :Admin","","runas",1)(window.close)&goto :eof

:Admin
@powershell -ExecutionPolicy Unrestricted -FILE %~dp0start.ps1


if NOT %errorlevel% == 0 (
    pause
)
