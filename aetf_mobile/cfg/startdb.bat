:* startdbs.bat - Starts servers for AutoEdge|TheFactory databases
SET DLC=C:\devarea\dlc\oe1120
SET PATH=%DLC%;%DLC%\bin;%PATH%
call proserve "C:\devarea\samples\aetf_mobile\db\aetf.db"
pause
