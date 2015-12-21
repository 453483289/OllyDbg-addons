// A simple plugin for OllyDbg, written by TQN
library DllBreakEx;

uses
  Windows, Classes, SysUtils, ShellAPI, Messages, IniFiles,
  Plugin in 'plugin.pas';

resourcestring
  VERSION = '2.2';
  AUTHOR  = 'Epsylon3';
  PLUGIN_NAME = 'DllBreakEx';
  ABOUT   = 'DllBreakEx Plugin for OllyDbg - By Epsylon3'#10'Compiled with Borland Delphi 7';

  PLUGIN_MENU =
  '0 &Add Named DLL Breakpoint...,'+
  '1 &List Named DLL Breakpoints,'+
  '2 &Remove Named DLL Breakpoints'+
  ' |'+
  '3 &Save current list for this process,'+
  '4 L&oad saved list for this process,'+
  '5 Reloa&d last used list'+
  ' |'+
  '6 Abou&t';

const
  MENU_ADD  = 0;
  MENU_LIST = 1;
  MENU_DEL  = 2;

  MENU_SAVE = 3;
  MENU_LOAD = 4;
  MENU_LAST = 5;

  MENU_ABOUT = 6;

var
  g_hwndOlly: HWND;
  g_hmodOlly: HMODULE;

  aDLL, aMOD: TStringList;
  aINI: TIniFile;

function GetExeName: string;
var
  pProcess: PChar;
  sExeFName: string;
begin
  pProcess := PChar(Plugingetvalue(VAL_PROCESSNAME));
  if (pProcess = nil) or (pProcess[0] = #0) then
    sExeFName := GetModuleName(g_hmodOlly)
  else
    sExeFName := PChar(Plugingetvalue(VAL_EXEFILENAME));

  Result := sExeFName;
end;

function GetExePath: string;
var
  pProcess: PChar;
  sExeFName: string;
begin
  pProcess := PChar(Plugingetvalue(VAL_PROCESSNAME));
  if (pProcess = nil) or (pProcess[0] = #0) then
    sExeFName := GetModuleName(g_hmodOlly)
  else
    sExeFName := PChar(Plugingetvalue(VAL_EXEFILENAME));

  Result := ExtractFilePath(sExeFName);
end;

procedure Information(sMsg : String);
begin
  MessageBox(g_hwndOlly, PAnsiChar(sMsg), PAnsiChar(PLUGIN_NAME+' v'+VERSION),MB_OK+MB_ICONINFORMATION);
end;

procedure LoadDLLList(sSection:String='');
var n: integer;
begin
  if sSection='' then sSection:=ExtractFileName(GetExeName());
  aINI := TIniFile.Create(ExtractFilePath(GetModuleName(g_hmodOlly))+PLUGIN_NAME+'.ini');
  aDLL.Clear;
  aIni.ReadSectionValues(sSection,aDLL);
  aDLL.Sort;
  for n:=0 to aDLL.Count-1 do
    aDLL[n] := aDLL.ValueFromIndex[n];
  aINI.Destroy;
end;

procedure SaveDLLList(sSection:String='');
var n: integer;
begin
  if sSection='' then sSection:=ExtractFileName(GetExeName());
  aINI := TIniFile.Create(ExtractFilePath(GetModuleName(g_hmodOlly))+PLUGIN_NAME+'.ini');
  aIni.EraseSection(sSection);
  for n:=0 to aDLL.Count-1 do
    aIni.WriteString(sSection,Format('DLL%0.02d',[n]),aDLL[N]);
  aINI.Destroy;
end;

function ODBG_Plugindata(name: PChar): Integer; cdecl;
begin
  StrLCopy(name, PChar(PLUGIN_NAME), 32);
  Result := PLUGIN_VERSION;
end;

function ODBG_Plugininit(ollydbgversion: Integer; hWndOlly: HWND; features: PULONG): Integer; cdecl;
begin
  if (ollydbgversion < PLUGIN_VERSION) then
  begin
    Result := -1;
    Exit;
  end;

  g_hwndOlly := hWndOlly;
  Addtolist(0, 0, PAnsiChar(PLUGIN_NAME+' plugin v%s'), VERSION);
  Addtolist(0,-1,'  Written by %s',AUTHOR);

  Result := 0;
end;

function ODBG_Pluginmenu(origin: Integer; pData: PChar; pItem: Pointer): Integer; cdecl;
begin
  case origin of
  PM_MAIN:
    begin
      // Plugin menu in main window
      StrCopy(pData,PAnsiChar(PLUGIN_MENU));
      Result := 1;
    end;
  else
    Result := 0; // Any other window
  end;
end;

procedure ODBG_Pluginaction(origin: Integer; action: Integer; pItem: Pointer); cdecl;
var
  sExePath: string;
  sDllPath: String;
  f:Integer;
begin
  if (origin = PM_MAIN) then
  begin
    sExePath := GetExePath;
    case action of
    MENU_ADD:
      begin
        sDllPath:=sExePath+#0;
        SetLength(sDllPath,254);
        if Browsefilename('Select library',@sDllPath[1],'.dll',0)>0 then
         if (Length(sDllPath)>0) then begin
          if (not aDLL.Find(sDllPath,f)) then begin
           aDLL.Add(UpperCase(sDllPath));
           aDLL.Sort();
           information('Librairies which pauses OllyDbg:'+#10+#10+aDLL.Text);
          end;
         end;
      end;
    MENU_LIST:
      if (Length(aDLL.Text)>0) then information(aDLL.Text) else information('No Filter: Break on every dll.');
    MENU_DEL:
      begin
        aDLL.Clear();
        Information('DLL filter has been cleared.');
      end;
    MENU_SAVE:
      SaveDLLList();
    MENU_LOAD:
      LoadDLLList();
    MENU_LAST:
      begin
        LoadDLLList('LAST');
        if (Length(aDLL.Text)>0) then information(aDLL.Text) else information('No Filter: Break on every dll.'); 
      end;
    MENU_ABOUT:
      Information(ABOUT);
    end;
  end;
end;

function ODBG_Paused(reason:Integer;var reg:t_reg): Integer; cdecl;
var tt: ^t_table; module: ^t_module;
    L,f,n: Integer;
    ptr: Cardinal;
    item: String;
    bfound: Boolean;
begin
  Result:=0;
  if ((reason and PP_PAUSE)<>1) then exit;
  if not assigned(aDLL) then exit;  
  if (aDLL.Count=0) then exit;

  tt := Pointer(Plugingetvalue(VAL_MODULES));

  L := tt^.data.itemsize;

  SetLength(item,L);

  bfound:=false;

  f:=0;

  for n:=tt^.data.n-1 downto 0 do begin
    ptr := Cardinal(tt^.data.data) + Cardinal(n*L);
    module := Pointer(ptr);
    if (not aMOD.Find(UpperCase(module^.path),f)) then begin
      aMOD.Add(UpperCase(module^.path)); aMOD.Sort();
      bfound := bfound or aDLL.Find(UpperCase(module^.path),f);
    end;
  end;

  Setlength(item,0);

  if (bfound) then
    Information('DLLBreakEx Breakpoint !')
  else
    //ignore bad dlls load breakpoint
    PostMessage(g_hwndOlly,WM_KEYDOWN,VK_F9,0);

  Result := 0;
end;

procedure ODBG_Pluginreset; cdecl;
begin
  //Clear internal cache of loaded modules (on restart/new)
  aMOD.Clear;
end;

procedure ODBG_PluginDestroy; cdecl;
begin
end;

procedure DLLMain(dwReason: DWORD);
begin
  case dwReason of
  DLL_PROCESS_ATTACH:
   begin
    OutputDebugString(PChar(PLUGIN_NAME+' loaded by DLL_PROCESS_ATTACH'));
    // Initialize code here
    aDLL := TStringList.Create;
    aMOD := TStringList.Create;
   end;
  DLL_PROCESS_DETACH:
   begin
    OutputDebugString(PChar(PLUGIN_NAME+' unloaded by DLL_PROCESS_DETACH'));
    // Uninitialize code here
    if aDLL.Count>0 then
       SaveDLLList('LAST');
    aMOD.Destroy;
    aDLL.Destroy;
   end;
  DLL_THREAD_ATTACH:
   begin
   end;
  DLL_THREAD_DETACH:
   begin
   end;
  end;
end;

exports
  ODBG_Paused        name '_ODBG_Paused',
  ODBG_Pluginreset   name '_ODBG_Pluginreset',
  ODBG_PluginDestroy name '_ODBG_PluginDestroy',

  ODBG_Plugindata    name '_ODBG_Plugindata',
  ODBG_Plugininit    name '_ODBG_Plugininit',
  ODBG_Pluginmenu    name '_ODBG_Pluginmenu',
  ODBG_Pluginaction  name '_ODBG_Pluginaction';

begin
  DllProc := @DllMain;
  DllProc(DLL_PROCESS_ATTACH);

  g_hmodOlly := GetModuleHandle(nil);
end.
