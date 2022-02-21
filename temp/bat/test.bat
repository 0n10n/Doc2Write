SETLOCAL EnableDelayedExpansion
echo %CommonProgramFiles%
set "target=%CommonProgramFiles:~0,3%" & dir !target!
endlocal
