; do *NOT* use register4 to register7 during time slicing
textStr             EQU     register0
textNum             EQU     register0
textBak             EQU     register0
textLen             EQU     register1
textOfs             EQU     register2
textChr             EQU     register3
textHex             EQU     register8
scanLine            EQU     register11
digitMult           EQU     register12
digitIndex          EQU     register13
clearLoop           EQU     register14
fontId              EQU     register9
fontAddrs           EQU     register10
fontBase            EQU     register11
fontPosXY           EQU     register15

    
%SUB                clearCursorRow
                    ; clears the top giga_yfont lines of pixels in preparation of text scrolling
clearCursorRow      PUSH
                    LDWI    SYS_SetMemory_v2_54
                    STW     giga_sysFn                      ; setup fill memory SYS routine
                    LD      fgbgColour
                    ST      giga_sysArg1                    ; fill value
                    LDWI    giga_videoTable
                    PEEK
                    ST      giga_sysArg3                    ; row0 high byte address
                    LDI     giga_yfont

clearCR_loopy       ST      clearLoop                    
                    LDI     giga_xres
                    ST      giga_sysArg0
                    LDI     0
                    ST      giga_sysArg2                    ; low start address
                    SYS     54                              ; fill memory
                    INC     giga_sysArg3                    ; next line
                    LD      clearLoop
                    SUBI    1
                    BNE     clearCR_loopy
                    CALL    realTimeStubAddr
                    LDWI    printInit
                    CALL    giga_vAC                        ; re-initialise the SYS registers
                    POP
                    RET
%ENDS

%SUB                printInit
printInit           LDWI    SYS_Sprite6_v3_64
                    STW     giga_sysFn
                    LD      cursorXY + 1                    ; xy = peek(256+2*y)*256 + x
                    LSLW
                    INC     giga_vAC + 1
                    PEEK
                    ST      fontPosXY + 1
                    LD      cursorXY
                    ST      fontPosXY                       ; xy position
                    RET
%ENDS
                    
%SUB                printText
                    ; prints text string pointed to by textStr
printText           PUSH
                    LDWI    printInit
                    CALL    giga_vAC

                    ; first byte is length
printT_char         INC     textStr                         ; next char
                    LDW     textStr             
                    PEEK
                    BEQ     printT_exit                     ; check for delimiting zero
                    ST      textChr
                    LDWI    printChar
                    CALL    giga_vAC
                    BRA     printT_char
                    
printT_exit         POP
                    RET
%ENDS   

%SUB                printLeft
                    ; prints left sub string pointed to by textStr
printLeft           PUSH
                    LDWI    printInit
                    CALL    giga_vAC
                    LD      textLen
                    BEQ     printL_exit
    
printL_char         ST      textLen
                    INC     textStr                         ; next char
                    LDW     textStr             
                    PEEK
                    ST      textChr
                    LDWI    printChar
                    CALL    giga_vAC

                    LD      textLen
                    SUBI    1
                    BNE     printL_char
printL_exit         POP
                    RET
%ENDS   

%SUB                printRight
                    ; prints right sub string pointed to by textStr
printRight          PUSH
                    LDWI    printInit
                    CALL    giga_vAC
                    LDW     textStr
                    PEEK                                    ; text length
                    ADDW    textStr
                    SUBW    textLen
                    STW     textStr                         ; text offset
                    LD      textLen
                    BEQ     printR_exit
    
printR_char         ST      textLen
                    INC     textStr                         ; next char
                    LDW     textStr             
                    PEEK
                    ST      textChr
                    LDWI    printChar
                    CALL    giga_vAC

                    LD      textLen
                    SUBI    1
                    BNE     printR_char
printR_exit         POP
                    RET
%ENDS   

%SUB                printMid
                    ; prints sub string pointed to by textStr
printMid            PUSH
                    LDWI    printInit
                    CALL    giga_vAC
                    LDW     textStr
                    ADDW    textOfs
                    STW     textStr                         ; textStr += textOfs
                    LD      textLen
                    BEQ     printM_exit
    
printM_char         ST      textLen
                    INC     textStr                         ; next char
                    LDW     textStr             
                    PEEK
                    ST      textChr
                    LDWI    printChar
                    CALL    giga_vAC

                    LD      textLen
                    SUBI    1
                    BNE     printM_char
printM_exit         POP
                    RET
%ENDS   
        
%SUB                printDigit
                    ; prints single digit in textNum
printDigit          PUSH
                    LDW     textNum
printD_index        SUBW    digitMult
                    BLT     printD_cont
                    STW     textNum
                    INC     digitIndex
                    BRA     printD_index
    
printD_cont         LD      digitIndex
                    BEQ     printD_exit
                    ORI     0x30
                    ST      textChr
                    LDWI    printChar
                    CALL    giga_vAC
                    LDI     0x30
                    ST      digitIndex
printD_exit         POP
                    RET
%ENDS   
    
%SUB                printInt16
                    ; prints 16bit int in textNum
printInt16          PUSH
                    LDWI    printInit
                    CALL    giga_vAC
                    LDI     0
                    ST      digitIndex
                    LDW     textNum
                    BGE     printI16_pos
                    LDI     0x2D
                    ST      textChr
                    LDWI    printChar
                    CALL    giga_vAC
                    LDI     0
                    SUBW    textNum
                    STW     textNum    
    
printI16_pos        LDWI    10000
                    STW     digitMult
                    LDWI    printDigit
                    CALL    giga_vAC
                    LDWI    1000
                    STW     digitMult
                    LDWI    printDigit
                    CALL    giga_vAC
                    LDI     100
                    STW     digitMult
                    LDWI    printDigit
                    CALL    giga_vAC
                    LDI     10
                    STW     digitMult
                    LDWI    printDigit
                    CALL    giga_vAC
                    LD      textNum
                    ORI     0x30
                    ST      textChr
                    LDWI    printChar
                    CALL    giga_vAC
                    POP
                    RET
%ENDS

%SUB                printHexByte
                    ; print hex byte in textHex
printHexByte        PUSH
                    LDWI    SYS_LSRW4_50                    ; shift right by 4 SYS routine
                    STW     giga_sysFn
                    LD      textHex
                    SYS     50
                    SUBI    10
                    BLT     printH_skip0
                    ADDI    7
printH_skip0        ADDI    0x3A
                    ST      textChr
                    LDWI    printInit
                    CALL    giga_vAC
                    LDWI    printChar
                    CALL    giga_vAC
                    LD      textHex
                    ANDI    0x0F
                    SUBI    10
                    BLT     printH_skip1
                    ADDI    7
printH_skip1        ADDI    0x3A
                    ST      textChr
                    LDWI    printChar
                    CALL    giga_vAC
                    POP
                    RET
%ENDS                    
        
%SUB                printHexWord     
                    ; print hex word in textHex
printHexWord        PUSH
                    LD      textHex
                    ST      textBak
                    LD      textHex + 1
                    ST      textHex
                    LDWI    printHexByte
                    CALL    giga_vAC
                    LD      textBak
                    ST      textHex
                    LDWI    printHexByte
                    CALL    giga_vAC
                    POP
                    RET
%ENDS   

%SUB                printChr
                    ; prints char in textChr for standalone calls
printChr            PUSH
                    LDWI    printInit
                    CALL    giga_vAC
                    LDWI    printChar
                    CALL    giga_vAC
                    POP
                    RET
%ENDS

%SUB                printChar
                    ; prints char in textChr
printChar           LD      textChr
                    ANDI    0x7F                            ; char can't be bigger than 127
                    SUBI    32
                    BLT     printC_exit
                    STW     textChr                         ; char-32                    

                    LDWI    _fontId_
                    PEEK
                    STW     fontId
                    LDWI    _fontsLut_                      ; fonts table
                    ADDW    fontId
                    ADDW    fontId
                    DEEK
                    STW     fontAddrs                       ; get font address table
                    INC     fontAddrs
                    INC     fontAddrs
                    DEEK                                    ; get font mapping table
                    BEQ     printC_noMap                    ; no mapping table means font contains all chars 32 -> 127 in the correct order
                    ADDW    textChr
                    PEEK
                    STW     textChr                         ; get mapped char
                    
printC_noMap        LDW     fontAddrs
                    DEEK
                    STW     fontBase                        ; baseline address, shared by all chars in a font
                    INC     fontAddrs
                    INC     fontAddrs
                    LDW     textChr
                    LSLW
                    ADDW    fontAddrs
                    DEEK                                    ; get char address
                    STW     giga_sysArg0
                    LDW     fontPosXY                       ; XY pos generated in printInit
                    SYS     64                              ; draw char
                    STW     fontPosXY
                    
                    LDW     fontBase
                    STW     giga_sysArg0
                    LDWI    0x0F00
                    ADDW    cursorXY
                    SYS     64                              ; draw baseline for char
                    
                    PUSH
                    CALL    realTimeStubAddr
                    LD      cursorXY
                    ADDI    giga_xfont
                    ST      cursorXY
                    SUBI    giga_xres - giga_xfont          ; last possible char on line
                    BLE     printC_pop
                    LDWI    newLineScroll                   ; next row, scroll at bottom
                    CALL    giga_vAC
                    
printC_pop          POP

printC_exit         RET
%ENDS

%SUB                newLineScroll
                    ; print from top row to bottom row, then start scrolling 
newLineScroll       LDI     giga_CursorX                    ; cursor x start
                    ST      cursorXY
                    ST      fontPosXY
                    LDI     ENABLE_SCROLL_BIT
                    ANDW    miscFlags
                    BNE     newLS_cont0                     ; is scroll on or off?
                    RET
                    
newLS_cont0         PUSH
                    LDI     ON_BOTTOM_ROW_BIT
                    ANDW    miscFlags                       ; is on bottom row flag?
                    BNE     newLS_cont1
                    LD      cursorXY + 1
                    ADDI    giga_yfont
                    ST      cursorXY + 1
                    SUBI    giga_yres
                    BLT     newLS_exit
                    LDI     giga_yres - giga_yfont
                    ST      cursorXY + 1
                    
newLS_cont1         LDWI    clearCursorRow
                    CALL    giga_vAC
                    LDWI    giga_videoTable
                    STW     scanLine
    
newLS_scroll        CALL    realTimeStubAddr
                    LDW     scanLine
                    PEEK
                    ADDI    giga_yfont
                    ANDI    0x7F
                    SUBI    giga_yfont
                    BGE     newLS_adjust
                    ADDI    giga_yfont
                    
newLS_adjust        ADDI    giga_yfont
                    POKE    scanLine
                    INC     scanLine                        ; scanline pointers are 16bits
                    INC     scanLine
                    LD      scanLine
                    SUBI    0xF0                            ; scanline pointers end at 0x01EE
                    BLT     newLS_scroll
                    
                    LDI     ON_BOTTOM_ROW_BIT
                    ORW     miscFlags
                    STW     miscFlags                       ; set on bottom row flag
                    
newLS_exit          LDWI    printInit
                    CALL    giga_vAC                        ; re-initialise the SYS registers
                    POP
                    RET
%ENDS   

%SUB                atTextCursor
atTextCursor        LD      cursorXY
                    SUBI    giga_xres - giga_xfont
                    BLE     atTC_checkY
                    LDI     0
                    ST      cursorXY
                    
atTC_checkY         LD      cursorXY + 1
                    SUBI    giga_yres - giga_yfont
                    BLT     atTC_resbot
                    LDI     giga_yres - giga_yfont
                    ST      cursorXY + 1
                    LDI     ON_BOTTOM_ROW_BIT
                    ORW     miscFlags
                    STW     miscFlags                       ; set on bottom row flag
                    RET
                    
atTC_resbot         LDWI    ON_BOTTOM_ROW_MSK
                    ANDW    miscFlags
                    STW     miscFlags                       ; reset on bottom row flag
                    RET
%ENDS
