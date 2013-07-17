@ECHO OFF
SET DLC=C:\devarea\dlc\oe1120
SET PATH=%DLC%\bin;%PATH%

REM

CALL "%DLC%\bin\asbman.bat" -i mobile_asAutoEdgeTheFactory -start -port 20931
pause