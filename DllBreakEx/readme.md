DLLBreakEx v2.2 
=================

Description : 
------------

For debugged proggies which loads a lot of dll, with this plugin you can select a dll from harddrive. When this dll will be loaded, you will get an Alert MessageBox. 

Needs this debugging option event checked : 
    
- "Break on new module (DLL)"

Tested on odbg 1.10
Sources Compiled with Delphi 7 / TNG Plugin SDK 1.10

---------------------------------------------------------------

History:
=======

v2.2
-----
- Load/Save filter for process name command
- Reload last used filter
  
v2.1
-----
- Bug with module cache on restart

v2.0
----
- Compiled with Delphi 7 (Made DLLProc Fix from TNG Sample)
  
v1.2
------
- Static version (no runtime)
- Added compatibility with 1.10b (ODBG_Paused)
  
v1.1
------
- Added DLL Breakpoints List in Menu
- gnore other modules when bp is set
- bug with module cache on restart
  
v1.0 
-----
- Initial Release
