
#COMPILE EXE "MaNo skin manager.exe"
#DIM ALL

$DATE = "2021-11-15"

'------------------------------------------------------------------------------
'   ** Includes **
'------------------------------------------------------------------------------
#RESOURCE "res\skinmgr.pbr"
#INCLUDE ONCE "WIN32API.INC"
#INCLUDE ONCE "SHFOLDER.INC"
#INCLUDE ONCE ".\SAVEPOS.INC"
'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
'   ** Constants **
'------------------------------------------------------------------------------
%IDC_LABEL1   = 1001
%IDC_LABEL2   = 1002
%IDC_BUTTON1  = 1003
%IDC_FRAME1   = 1004
%IDC_LISTBOX1 = 1005
%IDC_TEXTBOX1 = 1006
%IDC_GRAPHIC1 = 1007
%IDC_BUTTON2  = 1008
'------------------------------------------------------------------------------
GLOBAL mano_path   AS STRING
GLOBAL skin_file() AS STRING
GLOBAL skin_name() AS STRING
GLOBAL skin_desc() AS STRING
GLOBAL skin_auth() AS STRING
GLOBAL skin_vers() AS STRING
GLOBAL skin_nb     AS LONG
'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
'   ** Main Application Entry Point **
'------------------------------------------------------------------------------
FUNCTION PBMAIN()
    MainShow %HWND_DESKTOP
END FUNCTION
'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
'   ** CallBacks **
'------------------------------------------------------------------------------
CALLBACK FUNCTION MainProc()
    LOCAL i AS LONG
    LOCAL s, r AS STRING

    CB_SAVEPOS()

    SELECT CASE AS LONG CB.MSG
        CASE %WM_INITDIALOG
            ' Initialization handler
            mano_path = GetIniS(LocalAppData + "skinmgr.ini", "MaNo", "exe_path")
            IF mano_path = "" THEN ' try to auto-detect MaNo.exe
                CONTROL DISABLE CB.HNDL, %IDC_BUTTON2
                s = EXE.PATH$
                WHILE INSTR(s, "\") > 0 AND mano_path = ""
                    r = DIR$(s + "MaNo.exe") : DIR$ CLOSE
                    IF r <> "" THEN
                        mano_path = s
                    ELSE
                        i = INSTR(-2, s, "\")
                        IF i > 0 THEN s = LEFT$(s, i) ELSE s = ""
                    END IF
                WEND
            END IF
            IF mano_path <> "" THEN
                SetIni LocalAppData + "skinmgr.ini", "MaNo", "exe_path", mano_path
                CONTROL SET TEXT CB.HNDL, %IDC_LABEL2, " " + mano_path
                CONTROL ENABLE CB.HNDL, %IDC_BUTTON2
            END IF

        CASE %WM_COMMAND
            ' Process control notifications
            SELECT CASE AS LONG CB.CTL
                CASE %IDC_BUTTON1 ' Locate MaNo.exe
                    IF CB.CTLMSG = %BN_CLICKED OR CB.CTLMSG = 1 THEN
                        s = CHR$("MaNo executable", 0)
                        s += CHR$("MaNo.exe", 0)
                        DISPLAY OPENFILE CB.HNDL, -120, 0, "Locate MaNo.exe", "", s, _
                            "", "", %OFN_FILEMUSTEXIST TO s
                        IF s = "" THEN EXIT FUNCTION
                        i = INSTR(-2, s, "\")
                        mano_path = LEFT$(s, i)
                        SetIni LocalAppData + "skinmgr.ini", "MaNo", "exe_path", mano_path
                        CONTROL SET TEXT CB.HNDL, %IDC_LABEL2, " " + mano_path
                        CONTROL ENABLE CB.HNDL, %IDC_BUTTON2
                    END IF

                CASE %IDC_LISTBOX1
                    IF CB.CTLMSG = %LBN_DBLCLK THEN
                        IF mano_path = "" THEN EXIT FUNCTION
                        LISTBOX GET SELECT CB.HNDL, CB.CTL TO i
                        LISTBOX GET USER CB.HNDL, CB.CTL, i TO i
                        ApplySkin skin_file(i)

                    ELSEIF CB.CTLMSG = %LBN_SELCHANGE THEN
                        LISTBOX GET SELECT CB.HNDL, CB.CTL TO i
                        LISTBOX GET USER CB.HNDL, CB.CTL, i TO i
                        CONTROL SET TEXT CB.HNDL, %IDC_TEXTBOX1, skin_desc(i) + " - by " _
                                + skin_auth(i) + ", " + skin_vers(i)
                        Preview skin_file(i), CB.HNDL
                    END IF

                CASE %IDC_BUTTON2 ' Apply skin to MaNo
                    IF CB.CTLMSG = %BN_CLICKED OR CB.CTLMSG = 1 THEN
                        IF mano_path = "" THEN EXIT FUNCTION
                        LISTBOX GET SELECT CB.HNDL, %IDC_LISTBOX1 TO i
                        LISTBOX GET USER CB.HNDL, %IDC_LISTBOX1, i TO i
                        ApplySkin skin_file(i)
                    END IF

            END SELECT
    END SELECT
END FUNCTION
'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
SUB Preview(file AS STRING, hDlg AS DWORD)
    LOCAL c AS DWORD
    LOCAL i, x AS LONG

    ' Attach graphic control
    GRAPHIC ATTACH hDlg, %IDC_GRAPHIC1, REDRAW ' 160 x 122
    GRAPHIC BOX (0,0)-(160,122),,%WHITE,%WHITE

    ' Draw line number margin
    IF ISTRUE GetIniV(file, "editor", "LineNbShow") THEN
        c = Hex_To_Rgb(GetIniS(file, "editor", "LineNbBackColor"))
        GRAPHIC BOX (0,0)-(30,122),,c,c
        GRAPHIC COLOR Hex_To_Rgb(GetIniS(file, "editor", "LineNbForeColor")), c
        FOR i = 5 TO 105 STEP 10
            GRAPHIC SET POS (20, i)
            GRAPHIC PRINT "**"
        NEXT
        x = 31
    END IF

    ' Draw richedit zone
    c = Hex_To_Rgb(GetIniS(file, "editor", "TextBackColor"))
    GRAPHIC BOX (x,0)-(160,122),,c,c
    GRAPHIC COLOR Hex_To_Rgb(GetIniS(file, "editor", "TextForeColor")), c
    FOR i = 3 TO 103 STEP 10
        GRAPHIC SET POS (x,i)
        GRAPHIC PRINT STRING$(RND(10,30), "-")
    NEXT

    ' Redraw
    GRAPHIC REDRAW
END SUB
'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
FUNCTION Hex_To_Rgb(h AS STRING) AS LONG

    LOCAL r, g, b AS LONG
    LOCAL c AS STRING

    c = RIGHT$("000000" + h, 6)
    r = VAL("&H" + LEFT$(c,2))
    g = VAL("&H" + MID$(c,3,2))
    b = VAL("&H" + RIGHT$(c,2))

    FUNCTION = RGB(r,g,b)

END FUNCTION
'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
' returns a string from ini file
'------------------------------------------------------------------------------
FUNCTION GetIniS (BYVAL iniFile AS STRING, BYVAL sSection AS STRING, _
                  BYVAL sKey AS STRING) EXPORT AS STRING
    LOCAL zText AS ASCIIZ * 255
    GetPrivateProfileString BYCOPY sSection, BYCOPY sKey, "", zText, _
                            SIZEOF(zText), BYCOPY iniFile
    FUNCTION = zText
END FUNCTION

'------------------------------------------------------------------------------
' returns a number from ini file
'------------------------------------------------------------------------------
FUNCTION GetIniV (BYVAL iniFile AS STRING, BYVAL sSection AS STRING, _
                  BYVAL sKey AS STRING) EXPORT AS LONG
    LOCAL zText AS ASCIIZ * 255
    GetPrivateProfileString BYCOPY sSection, BYCOPY sKey, "0", zText, _
                            SIZEOF(zText), BYCOPY iniFile
    FUNCTION = VAL(zText)
END FUNCTION

'------------------------------------------------------------------------------
' sets a string in ini file
'------------------------------------------------------------------------------
FUNCTION SetIni (BYVAL iniFile AS STRING, BYVAL sSection AS STRING, _
                 BYVAL sKey AS STRING, BYVAL sValue AS STRING) AS LONG
    FUNCTION = WritePrivateProfileString (BYCOPY sSection, BYCOPY sKey, _
                                          BYCOPY sValue, BYCOPY iniFile)
END FUNCTION

'------------------------------------------------------------------------------
'   ** Sample Code **
'------------------------------------------------------------------------------
FUNCTION SampleListBox(BYVAL hDlg AS DWORD, BYVAL lID AS LONG) AS LONG
    LOCAL i AS LONG
    LOCAL e AS STRING

    LISTBOX RESET hDlg, lID
    skin_nb = 0

    e = DIR$(EXE.PATH$ + "*.ini")
    WHILE LEN(e) AND e <> "skinmgr.ini"
        INCR skin_nb
        REDIM PRESERVE skin_file(1 TO skin_nb)
        REDIM PRESERVE skin_name(1 TO skin_nb)
        REDIM PRESERVE skin_desc(1 TO skin_nb)
        REDIM PRESERVE skin_auth(1 TO skin_nb)
        REDIM PRESERVE skin_vers(1 TO skin_nb)
        skin_file(skin_nb) = EXE.PATH$ + e
        skin_name(skin_nb) = GetIniS(EXE.PATH$ + e, "info", "Skin")
        skin_desc(skin_nb) = GetIniS(EXE.PATH$ + e, "info", "Description")
        skin_auth(skin_nb) = GetIniS(EXE.PATH$ + e, "info", "Author")
        skin_vers(skin_nb) = GetIniS(EXE.PATH$ + e, "info", "Version")
        LISTBOX ADD hDlg, lID, skin_name(skin_nb)
        LISTBOX FIND EXACT hDlg, lID, 1, skin_name(skin_nb) TO i
        LISTBOX SET USER hDlg, lID, i, skin_nb
        e = DIR$(NEXT)
    WEND
    DIR$ CLOSE

    LISTBOX SELECT hDlg, lID, 1
    LISTBOX GET USER hDlg, lID, 1 TO i
    CONTROL SET TEXT hDlg, %IDC_TEXTBOX1, skin_desc(i) + " - by " _
            + skin_auth(i) + ", " + skin_vers(i)
    Preview skin_file(i), hDlg

END FUNCTION
'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
'   ** Dialogs **
'------------------------------------------------------------------------------
FUNCTION MainShow(BYVAL hParent AS DWORD) AS LONG
    LOCAL lRes AS LONG

    LOCAL hDlg  AS DWORD

    DIALOG NEW PIXELS, hParent, "MaNo skin manager ("+$DATE+")",,, 409, 225, _
        %WS_POPUP OR %WS_BORDER OR %WS_DLGFRAME OR %WS_CAPTION OR _
        %WS_SYSMENU OR %WS_MINIMIZEBOX OR %WS_CLIPSIBLINGS OR %WS_VISIBLE OR _
        %DS_MODALFRAME OR %DS_3DLOOK OR %DS_NOFAILCREATE OR %DS_SETFONT, _
        %WS_EX_CONTROLPARENT OR %WS_EX_LEFT OR %WS_EX_LTRREADING OR _
        %WS_EX_RIGHTSCROLLBAR, TO hDlg
    DIALOG SET ICON      hDlg, "AICO"

    CONTROL ADD LABEL,   hDlg, %IDC_LABEL1, "MaNo.exe in", 8, 8, 64, 16
    CONTROL ADD LABEL,   hDlg, %IDC_LABEL2, " <not found>", 72, 8, 288, 16, _
        %WS_CHILD OR %WS_VISIBLE OR %SS_LEFT OR %SS_SUNKEN OR %SS_PATHELLIPSIS, _
        %WS_EX_LEFT OR %WS_EX_LTRREADING
    CONTROL SET COLOR    hDlg, %IDC_LABEL2, %BLACK, %WHITE
    CONTROL ADD BUTTON,  hDlg, %IDC_BUTTON1, "...", 360, 7, 32, 18

    CONTROL ADD FRAME,   hDlg, %IDC_FRAME1, "Available skins / Send yours to mougino@free.fr !", 8, 32, 384, 184
    CONTROL ADD LISTBOX, hDlg, %IDC_LISTBOX1, , 24, 56, 184, 100
    CONTROL ADD TEXTBOX, hDlg, %IDC_TEXTBOX1, "", 24, 158, 184, 48, _
        %ES_READONLY OR %WS_BORDER OR %ES_MULTILINE OR %ES_WANTRETURN
    CONTROL SET COLOR    hDlg, %IDC_TEXTBOX1, %RGB_NAVY, %WHITE
    CONTROL ADD GRAPHIC, hDlg, %IDC_GRAPHIC1, "", 216, 56, 160, 122, _
        %WS_CHILD OR %WS_VISIBLE OR %SS_SUNKEN
    CONTROL ADD BUTTON,  hDlg, %IDC_BUTTON2, "Apply to MaNo (restart)", 216, 182, 160, 24

    SampleListBox  hDlg, %IDC_LISTBOX1

    DIALOG SHOW MODAL hDlg, CALL MainProc TO lRes

    FUNCTION = lRes
END FUNCTION
'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
TYPE WindowList
   hwnd AS DWORD
   Parent AS LONG
   R AS RECT
END TYPE
'------------------------------------------------------------------------------
MACRO SET_INI_KEY(k) = SetIni mano_path + "MaNo.ini", "editor", k, GetIniS(skin, "editor", k)
'------------------------------------------------------------------------------
FUNCTION ParentCallback (BYVAL hWndChild AS LONG, BYREF wList() AS WindowList) AS LONG
    LOCAL szParentClass     AS ASCIIZ * %MAX_PATH
    LOCAL aResult, iCount   AS LONG

    aResult = GetClassName(hWndChild, szParentClass, SIZEOF(szParentClass))
    iCount = UBOUND(wList) + 1
    REDIM PRESERVE wList(iCount)
    wList(iCount).PARENT = 1
    wList(iCount).hwnd = hWndChild

    FUNCTION = %TRUE ' continue top-level enumeration...
END FUNCTION
'--------------------------------------------------------------------------------
SUB ApplySkin(skin AS STRING)

   LOCAL i AS LONG
   LOCAL e AS STRING
   LOCAL wList() AS WindowList
   LOCAL szClass, szText        AS ASCIIZ * %MAX_PATH

   ' Apply new skin to MaNo.ini
   SET_INI_KEY("TextFont")
   SET_INI_KEY("TextSize")
   SET_INI_KEY("TextForeColor")
   SET_INI_KEY("TextBackColor")
   SET_INI_KEY("LineNbShow")
   SET_INI_KEY("LineNbFont")
   SET_INI_KEY("LineNbSize")
   SET_INI_KEY("LineNbForeColor")
   SET_INI_KEY("LineNbBackColor")

   ' (Re)start MaNo.exe
   EnumWindows(CODEPTR(ParentCallback), BYVAL VARPTR(wList())) ' Retrieve top level window names
   REDIM PRESERVE wList(UBOUND(wList))
   FOR i = 0 TO UBOUND(wList)
      GetClassName wList(i).hwnd, szClass, SIZEOF(szClass)
      IF INSTR(szClass, "MaNo_Class") = 1 THEN
         GetWindowText wList(i).hwnd, szText, SIZEOF(szText)
         EXIT FOR
      END IF
   NEXT
   IF szText <> "" THEN ' MaNo already running > restart1 it
       SendMessage wList(i).hwnd, %WM_CLOSE, 0, 0
   END IF
   i = SHELL(mano_path + "MaNo.exe")

END SUB
'------------------------------------------------------------------------------
