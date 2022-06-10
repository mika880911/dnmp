@ECHO OFF

PUSHD %~DP0 & cd /d "%~dp0"
%1 %2
mshta vbscript:createobject("shell.application").shellexecute("%~s0","goto :runas","","runas",1)(window.close)&goto :eof
:runas

php %~dp0/src/StartContainer.php > docker_command_output
SET /p docker_command=<docker_command_output
DEL docker_command_output
%docker_command%