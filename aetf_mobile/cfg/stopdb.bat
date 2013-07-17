:* stopdbs.bat - Shuts down AutoEdge|TheFactory database servers
SET DLC=C:\devarea\dlc\oe1120
SET PATH=%DLC%;%DLC%\bin;%PATH%
call proshut -by "C:\devarea\samples\aetf_mobile\db\aetf.db"
pause