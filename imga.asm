; Impulse Model Guitar Amplifier, targets DSP56002EVM.
;
; Copyright (c) 2020-2021 Gordon Mills
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

                PAGE    132
                OPT     CC,MU,MEX,NOPS  ; Cyc count, Mem usage, Macro Exp, String Exp

; Configuration constants
IMPULSE_LEN     EQU     384                     ; Amp. model impulse response length
OP_BUFF_LEN     EQU     4                       ; Output buffer length, in samples
IP_BUFF_LEN     EQU     IMPULSE_LEN+OP_BUFF_LEN ; Input buffer length, in samples
SIZEOF_STACK    EQU     16                      ; Software stack size
FRAME_TICKS     EQU     40-1                    ; UI frame period (ms)

; Memory map constants
ROM_BASE        EQU     $E000           ; EEPROM base address
P_OVERLAY       EQU     $0200           ; P space constant area start

; I/O map constants
IPR             EQU     $FFFF           ; Interrupt Priority Register
BCR             EQU     $FFFE           ; Bus Control Register
PCTL            EQU     $FFFD           ; PLL Control Register
SSIDR           EQU     $FFEF           ; SSI Data Register
SSISR           EQU     $FFEE           ; SSI Status Register
CRB             EQU     $FFED           ; SSI Control Register B
CRA             EQU     $FFEC           ; SSI Control Register A
PCD             EQU     $FFE5           ; Port C Data Register
PBD             EQU     $FFE4           ; Port B Data Register
PCDDR           EQU     $FFE3           ; Port C Data Direction Register
PBDDR           EQU     $FFE2           ; Port B Data Direction Register
PCC             EQU     $FFE1           ; Port C Control Register
PBC             EQU     $FFE0           ; Port B Control Register
TCR             EQU     $FFDF           ; Timer Count Register
TCSR            EQU     $FFDE           ; Timer Control/Status Register

; Bit field constants
CLB             EQU     18              ; Codec control latch bit
TDE             EQU     6               ; SSI transmit data empty flag
OVR             EQU     21              ; ADC overrange flag

; Enumerations.
NUM_MENU        EQU     4               ; Number of menu pages
NUM_TYPE        EQU     6               ; Number of model types
PAGE_MENU       EQU     NUM_MENU        ; Menu page numer
PAGE_OVER       EQU     NUM_MENU+1      ; Over page number
PAGE_BLNK       EQU     NUM_MENU+2      ; Blanking page number

; Internal Y memory
                ORG     Y:$0000
impulseY        DSM     IMPULSE_LEN/2   ; Amplifier model impulse response kernel
impulseEndY
                ORG     Y:impulseEndY,PH:P_OVERLAY
startOvlyY
tabEncdr        DC      $000000         ; Encoder delta table
                DC      $010000         ;
                DC      $FF0000         ;
                DC      $000000         ;
                DC      $FF0000         ;
                DC      $000000         ;
                DC      $000000         ;
                DC      $010000         ;
                DC      $010000         ;
                DC      $000000         ;
                DC      $000000         ;
                DC      $FF0000         ;
                DC      $000000         ;
                DC      $FF0000         ;
                DC      $010000         ;
                DC      $000000         ;
pinSwtch        DC      0               ; Previous switch pin state
pinEncdr        DC      0               ; Previous encoder pin states
frmTicks        DC      FRAME_TICKS     ; Frame tick counter
endOvlyY

; Internal X memory
                ORG     X:$0000
impulseX        DSM     IMPULSE_LEN/2   ; Amplifier model impulse response kernel
impulseEndX

; Internal overlaid X memory. Beware, most addresses are modulo constrained.
                ORG     X:impulseEndX,PH:
startOvlyX
bufdscRx        DC      IP_BUFF_LEN-1                   ; Rx slot 0 buffer descriptor
                DC      1                               ;
ptrSSIRx        DC      bufAudioIP+IMPULSE_LEN-1        ;
                DC      -1                              ; Rx slot 1 buffer descriptor
                DC      0                               ;
                DC      cdcRxRight                      ;
                DC      -1                              ; Rx slot 2 buffer descriptor
                DC      0                               ;
                DC      cdcRxDat56                      ;
                DC      -1                              ; Rx slot 3 buffer descriptor
                DC      0                               ;
                DC      cdcRxDat78                      ;
cdcControl      DC      $309C00         ; Mic amp off, HPF on, 32 kHz, stereo, 16-bit
                DC      $A20000         ; ITS, XTAL2, 64-bit frame, master, txen
                DC      $C00000         ; PIO tristate
                DC      0               ; Reserved
bufdscTx        DC      2*OP_BUFF_LEN-1                 ; Tx slot 0 buffer descriptor
                DC      2                               ;
                DC      bufAudioOP                      ;
                DC      2*OP_BUFF_LEN-1                 ; Tx slot 1 buffer descriptor
                DC      2                               ;
                DC      bufAudioOP+1                    ;
                DC      -1                              ; Tx slot 2 buffer descriptor
                DC      0                               ;
                DC      cdcTxDat56                      ;
                DC      -1                              ; Tx slot 3 buffer descriptor
                DC      0                               ;
                DC      cdcTxDat78                      ;
cdcTxDat56      DC      $D01000         ; HP + line op on, spkr off, attn LR = 24 dB
cdcTxDat78      DC      $F8F800         ; PIO tri, mic in, mon. mute, gain LR = 12 dB
cdcRxDat56      DC      0               ; Status bytes 5 and 6
cdcRxDat78      DC      0               ; Status bytes 7 and 8
tabType         DC      modNone+3                       ; Impulse model pointer table
                DC      modAC30+3                       ;
                DC      modJCM9+3                       ;
                DC      modLC50+3                       ;
                DC      modOrng+3                       ;
                DC      modVntg+3                       ;
tabFunc         DC      funcAttn                        ; Menu function pointer table
                DC      funcGain                        ;
                DC      funcType                        ;
                DC      funcInfo                        ;
                DC      funcMenu                        ;
                DC      funcOver                        ;
                DC      funcBlnk                        ;
tabStr          DC      strAttn+3                       ; Menu string pointer table
                DC      strGain+3                       ;
                DC      strType+3                       ;
                DC      strInfo+3                       ;
tabNavi         DC      PAGE_MENU                       ; Menu navigation table
                DC      PAGE_MENU                       ;
                DC      PAGE_MENU                       ;
                DC      PAGE_MENU                       ;
posMenu         DC      0                               ;
posOver         DC      PAGE_MENU                       ;
posBlnk         DC      PAGE_MENU                       ;
posPage         DC      PAGE_MENU               ; Current page number
posType         DC      NUM_TYPE-1              ; Model type number
posInfo         DC      0                       ; Info string position
prvEncdr        DC      0                       ; Previous encoder position
posEncdr        DC      0                       ; Encoder position
cdcRxRight      DC      0                       ; Right input channel bin
                DS      2                       ; Spare

; External overlaid X memory
strImga         DC      'I.M.G.A. Ver 1.0 (c) G. Mills 2021  I.M'       ;
strAttn         DC      'Attn'                  ; Display strings
strGain         DC      'Gain'                  ;
strType         DC      'Type'                  ;
strInfo         DC      'Info'                  ;
strOver         DC      'OVR!'                  ;
strBlnk         DC      '    '                  ;
strParam        DC      '????'                  ;

modAC30                                         ; Amplifier models
                INCLUDE 'ac30.inc'
modJCM9
                INCLUDE 'jcm9.inc'
modLC50
                INCLUDE 'lc50.inc'
modOrng
                INCLUDE 'orng.inc'
modVntg
                INCLUDE 'vntg.inc'
modNone
                DC      'NONE'
                DC      -1.0                    ; Passthrough coefficient
endOvlyX

; External unified data memory
                ORG     X:endOvlyX

                DS      IMPULSE_LEN-1           ; Passthrough response tail
bufAudioOP      DSM     2*OP_BUFF_LEN           ; Stereo audio output buffer
bufAudioIP      DSM     IP_BUFF_LEN             ; Mono audio input buffer
endBssX

; Internal P memory
                ORG     P:$0000
                                        ; Exception vector table
                jmp     <reset                  ; $00 - Hardware reset
                nop                             ;

                DUP     5
                move    #<*,y1                  ; $02 to $0A - Unexpected
                jmp     <excUnexpeced           ;
                ENDM

                jsr     <isrSSIRx               ; $0C - SSI receive data
                nop                             ;

                jsr     <isrSSIRx               ; $0E - SSI receive data w/exc
                nop                             ;

                jsr     <isrSSITx               ; $10 - SSI transmit data
                nop                             ;

                jsr     <isrSSITx               ; $12 - SSI transmit data w/exc
                nop                             ;

                DUP     20
                move    #<*,y1                  ; $14 to $3A - Unexpected
                jmp     <excUnexpeced           ;
                ENDM

                jsr     <isrTimer               ; $3C - Timer
                nop                             ;

                move    #<*,y1                  ; $3E - Unexpected
                jmp     <excUnexpeced           ;

                                        ; Reset entrypoint
reset           movep   #$262009,x:PCTL         ; PLL enabled, 4.0 MHz * 10 = 40.0 MHz
                                                ; CKOUT = 40.0 MHz / 4 = 10.0 MHz
                movep   #$023000,x:IPR          ; SSI IP level 2, Timer IP level 1

                                        ; Initialise on-chip peripherals
                movep   #$000080,x:BCR          ; 0 WS for XY SRAM, 8 WS for P EEPROM
                movep   #$000C00,x:PBD          ; Port B = DNCE | DNWR | !DNBL
                movep   #$000FFF,x:PBDDR        ; Display control pins to output mode
                movep   #0,x:PCC                ; Disable (reset) SSI port
                movep   #$004303,x:CRA          ; Wlen = 16, 4 W/frame, SCLK = 2.5 MHz
                movep   #$003B30,x:CRB          ; En tx+rx, netwk, sync, bit frm, mstr
                movep   #0,x:PCD                ; Clear port C output data register
                movep   #$000014,x:PCDDR        ; PC4 (CRST~), PC2 (D/C~) output mode
                movep   #20000-1,x:TCR          ; Timer rate = 20 MHz / 20000 = 1 kHz
                movep   #$00000B,x:TCSR         ; Timer and interrupt enabled, mode 1

                                        ; Initialise memory overlays
                move    #ROM_BASE+3*P_OVERLAY,r0        ; r0 = overlay ROM address

                move    #startOvlyY,r1                  ; r1 = Y mem load address
                do      #endOvlyY-startOvlyY,loopOvlyY  ; Repeat for number of words
                jsr     <readROMWord                    ;   a1 = *r0, r0 += 3
                move    a1,y:(r1)+                      ;   *r1++ = a1
loopOvlyY
                move    #startOvlyX,r1                  ; r1 = X mem load address
                do      #endOvlyX-startOvlyX,loopOvlyX  ; Repeat for number of words
                jsr     <readROMWord                    ;   a1 = *r0, r0 += 3
                move    a1,x:(r1)+                      ;   *r1++ = a1
loopOvlyX
                                        ; Initialise bss section
                clr     a                               ;
                do      #endBssX-endOvlyX,loopBssX      ; Repeat for number of words
                move    a1,x:(r1)+                      ;   *r1++ = 0
loopBssX
                                        ; Initialise previous encoder state
                move    #>$6000,x0                      ; x0 = encoder pin mask
                movep   x:PBD,a                         ; a = port B
                and     x0,a                            ;
                move    a1,y:pinEncdr                   ; pinEncdr = enc pins

                                        ; Initialise codec
                do      #500,loopCrst           ; Assert CRST~ for 500 * ...
                rep     #2000                   ;   * 2000 * 50 ns = 50 ms
                nop                             ;
loopCrst
                movep   #$000010,x:PCD          ; CRST~ = 1
                movep   #$0001E8,x:PCC          ; Enable all SSI pins

                move    #cdcControl,r0          ; r0 = codec ctrl word buffer
                move    #4-1,m0                 ; m0 = buffer length
                do      #5*4,loopCini0          ; Send ctrl timeslots 5x with CLB = 0
                movep   x:(r0)+,x:SSIDR         ; Transmit control timeslot
                jclr    #TDE,x:SSISR,*          ; Wait for transfer
                nop                             ; DO restriction
loopCini0
                bset    #CLB,x:cdcControl       ;
                do      #2*4,loopCini1          ; Send ctrl timeslots 2x with CLB = 1
                movep   x:(r0)+,x:SSIDR         ; Transmit control timeslot
                jclr    #TDE,x:SSISR,*          ; Wait for transfer
                nop                             ; DO restriction
loopCini1
                rep     #8*16-8                 ; Wait for completion
                nop                             ;
                movep   #0,x:PCC                ; Disable (reset) SSI port

                                        ; Initialise address registers
                move    #bufAudioOP,r0          ; r0 = output buffer address
                move    #2*OP_BUFF_LEN-1,m0     ;

                move    #bufAudioIP,r1          ; r1 = input buffer address
                move    #IP_BUFF_LEN-1,m1       ;
                move    #OP_BUFF_LEN+1,n1       ;

                move    #bufdscTx,r2            ; r2 = SSI transmit buffer descriptors
                move    #12-1,m2                ;

                move    #bufdscRx,r3            ; r3 = SSI receive buffer descriptors
                move    #12-1,m3                ;

                move    #impulseY,r5            ; r5 = impulse kernel address
                move    #IMPULSE_LEN/2-1,m5     ;

                move    #tabEncdr,r7            ; r7 = encoder delta table address

                                        ; Initialise impulse response
                move    #<1,x0                  ; x0 = encoder chg = +1
                jsr     <funcType               ;

                                        ; Enable interrupts and codec
                movep   #$00FB00,x:CRB          ; Int tx+rx, ntwk, sync, bit frm, slv
                movep   #$0001E8,x:PCC          ; Enable all SSI pins
                andi    #$FC,mr                 ; Enable interrupts
                movep   #$000014,x:PCD          ; DNOTC = 1, codec data mode

; Main procesing loop
loopMain                                        ; Check for sufficient nof ip samples
                move    x:ptrSSIRx,a                            ; a = SSI pointer
                move    r1,x0                                   ; x0 = input process pointer
                sub     x0,a            #>IMPULSE_LEN,y0        ; a = SSI ptr - input ptr
                jge     <testBufLen                             ;
                move    #>IP_BUFF_LEN,x0                        ; if (a < 0)
                add     x0,a                                    ;   a += buff length
testBufLen      cmp     y0,a                                    ; if (a < IMPULSE_LEN)
                jlt     <checkUI                                ;   skip audio proc

                                                ; Process audio
                clr     a               x:(r1)+,x0      y:(r5)+,y0      ; a = 0
                do      #IMPULSE_LEN/2-1,loopConvolveY                  ; k = N-1, N-2, ..., N/2
                mac     x0,y0,a         x:(r1)+,x0      y:(r5)+,y0      ; a += x(n-k) * h(k)
loopConvolveY
                mac     x0,y0,a         x:(r5)+,x0      y:(r1)+,y0      ; switch to X kernel
                do      #IMPULSE_LEN/2-1,loopConvolveX                  ; k = N/2-1, N/2-2, ..., 0
                mac     x0,y0,a         x:(r5)+,x0      y:(r1)+,y0      ; a += h(k) * x(n-k)
loopConvolveX
                mac     x0,y0,a         (r1)+n1         ; Advance input pointer
                move    a,x:(r0)+                       ; *left output++ = a
                move    a,x:(r0)+                       ; *right output++ = a

                                                ; Check for UI frame period
checkUI         clr     a               y:frmTicks,y0   ; x0 = frame tick counter
                cmp     y0,a                            ; if (frame ticks != 0)
                jne     <loopMain                       ;   skip UI proc

                                                ; UI Processing
                move    #>FRAME_TICKS,y0                ; restart frame tick counter
                move    y0,y:frmTicks                   ;

                                                ; Test for over events
                move    x:posPage,a                     ; a = posPage
                move    #>PAGE_OVER,x0                  ; x0 = PAGE_OVER
                cmp     x0,a                            ;
                jeq     <testSwitch                     ; if (posPage != PAGE_OVER)
                btst    #OVR,x:cdcRxDat78               ;
                jcc     <testLimit                      ;   if (OVR)
                bclr    #OVR,x:cdcTxDat78               ;     clear OVR
                move    a1,x:posOver                    ;     posOver = posPage
                move    x0,x:posPage                    ;     posPage = PAGE_OVER
testLimit       jlc     <testSwitch                     ;   if (L)
                andi    #$BF,ccr                        ;     clear L
                move    a1,x:posOver                    ;     posOver = posPage
                move    x0,x:posPage                    ;     posPage = PAGE_OVER

                                                ; Test for switch press
testSwitch      move    #>$1000,x0                      ; x0 = switch mask
                movep   x:PBD,a                         ; a = port B
                and     x0,a            y:pinSwtch,y0   ; a = new state, y0 = previous
                cmp     y0,a            a1,y:pinSwtch   ; if (new - previous < 0)
                jge     <updateEnc                      ;   falling edge, change page
                move    #tabNavi,r6                     ;   r6 = tabNavi
                move    x:posPage,n6                    ;   n6 = posPage
                bset    #OVR,x:cdcTxDat78               ;   (re)enable OVR detect
                move    x:(r6+n6),n6                    ;   n6 = tabNavi[posPage]
                move    n6,x:posPage                    ;   posPage = n6

                                                ; Update encoder parameter
updateEnc       move    x:posEncdr,a                    ; a = current enc position
                move    x:prvEncdr,x0                   ; x0 = previous enc position
                move    #tabFunc,r6                     ; r6 = tabFunc
                move    x:posPage,n6                    ; n6 = posPage
                sub     x0,a            a1,x:prvEncdr   ; a = curr - prev, prev = curr
                move    x:(r6+n6),r6                    ; r6 = tabFunc[posPage]
                move    a1,x0                           ; x0 = encoder chg
                jsr     (r6)                            ; call current page function

                                                ; Update display
                move    #>$000480,a                     ; a = !DNCE | DNWR | DNBL
                move    #>$100,x0                       ; x0 = display address inc
                move    #>$FFFF80,y0                    ; y0 = data mask

                do      #4,loopDisp                     ; for each display digit..
                and     y0,a            x:(r6)-,y0      ;   a = !DNCE | DNWR, y0 = *r6--
                or      y0,a            #>$FFFBFF,y0    ;   a = !DNCE | DNWR | y0, y0 = !DNWR
                move    a1,x:PBD                        ;   port B = a
                and     y0,a            #>$000400,y0    ;   a = !DNCE | !DNWR | y0, y0 = DNWR
                move    a1,x:PBD                        ;   port B = a
                or      y0,a            #>$FFFF80,y0    ;   a = !DNCE | DNWR | y0, y0 = mask
                move    a1,x:PBD                        ;   port B = a
                add     x0,a                            ;   increment address
loopDisp
                movep   #$000C80,x:PBD                  ; port B = DNCE | DNWR | DNBL

                jmp     <loopMain                       ;


; UI parameter update functions, x0 = encoder change
funcMenu        move    #>$80,y0                        ; y0 = 1 / 2**16
                mpy     x0,y0,a         x:posMenu,x0    ; a = enc chg >> 16, x0 = posMenu
                add     x0,a            #>@CVI(NUM_MENU*@POW(2,7)),x0   ; a = posMenu + change
                andi    #$FE,ccr                        ; x0 = NUM_MENU, clear carry flag
                rep     #8                              ; divide, a = a / x0
                div     x0,a                            ;   ...
                add     x0,a            #>$8000,y0      ; restore, y0 = 1 / 2**8
                move    a1,x0                           ; x0 = remainder
                mpy     x0,y0,a         #tabStr,r6      ; a = (posMenu + change) % NUM_MENU
                move    a1,n6                           ; n6 = a
                move    n6,x:posMenu                    ; posMenu = n6
                move    x:(r6+n6),r6                    ; r6 = tabStr[posMenu]
                rts                                     ;


funcAttn        clr     a               #<$3F,y0        ; a = 0, y0 = R attn mask
                move    x:cdcTxDat56,a1                 ; a = cdcTxDat56
                and     y0,a                            ; a = prev R attn
                sub     x0,a            #<0,x0          ; a = prev R attn - encoder chg
                tlt     x0,a                            ; if (a < 0) a = 0
                cmp     y0,a            #>$C0FFFF,x0    ; if (a > $3F0000), x0 = R mask
                tgt     y0,a                            ;   a = $3F0000
                move    a1,y0                           ; y0 = curr R attn
                move    x:cdcTxDat56,a1                 ; a = cdcTxDat56
                and     x0,a                            ; a = cdcTxDat56 with R attn = 0
                or      y0,a            #>$8000,x0      ; a = cdcTxDat56 | R attn, x0 = 1 / 2**8
                move    a1,x:cdcTxDat56                 ; save cdcTxDat56
                mpy     x0,y0,a         #>$FFC0FF,x0    ; a = R attn >> 8, x0 = L mask
                move    a1,y0                           ; y0 = curr L attn
                move    x:cdcTxDat56,a1                 ; a = cdcTxDat56
                and     x0,a                            ; a = cdcTxDat56 with L attn = 0
                or      y0,a            #strParam,r6    ; a = cdcTxDat56 | L attn
                move    a1,x:cdcTxDat56                 ; update cdcTxDat56
                move    y0,a                            ; a = attn
                jsr     <dbs2str                        ; write parameter string
                rts                                     ;


funcGain        clr     a               #<$0F,y0        ; a = 0, y0 = R gain mask
                move    x:cdcTxDat78,a1                 ; a = cdcTxDat78
                and     y0,a                            ; a = prev R gain
                add     x0,a            #<0,x0          ; a = prev R gain + encoder chg
                tlt     x0,a                            ; if (a < 0) a = 0
                cmp     y0,a            #>$F0FFFF,x0    ; if (a > $0F0000), x0 = R mask
                tgt     y0,a                            ;   a = $0F0000
                move    a1,y0                           ; y0 = curr R gain
                move    x:cdcTxDat78,a1                 ; a = cdcTxDat78
                and     x0,a                            ; a = cdcTxDat78 with R gain = 0
                or      y0,a            #>$8000,x0      ; a = cdcTxDat78 | R gain, x0 = 1 / 2**8
                move    a1,x:cdcTxDat78                 ; save cdcTxDat78
                mpy     x0,y0,a         #>$FFF0FF,x0    ; a = R gain >> 8, x0 = L mask
                move    a1,y0                           ; y0 = curr L gain
                move    x:cdcTxDat78,a1                 ; a = cdcTxDat78
                and     x0,a                            ; a = cdcTxDat78 with L gain = 0
                or      y0,a            #strParam,r6    ; a = cdcTxDat78 | L gain
                move    a1,x:cdcTxDat78                 ; update cdcTxDat78
                move    y0,a                            ; a = curr gain
                jsr     <dbs2str                        ; write parameter string
                rts                                     ;


funcType        clr     a               #tabType,r6     ; r6 = tabType
                cmp     x0,a            x:posType,n6    ;
                jne     <changeType                     ; if (enc chg == 0)
                move    x:(r6+n6),r6                    ;   r6 = tabType[posType]
                rts                                     ; else

changeType      move    #>$80,y0                        ;   y0 = 1 / 2**16
                mpy     x0,y0,a         x:posType,x0    ;   a = enc chg >> 16, x0 = posType
                add     x0,a            #>@CVI(NUM_TYPE*@POW(2,7)),x0   ; a = posType + change
                andi    #$FE,ccr                        ;   x0 = NUM_TYPE, clear carry flag
                rep     #8                              ;   divide, a = a / x0
                div     x0,a                            ;     ...
                add     x0,a            #>$8000,y0      ;   restore, y0 = 1 / 2**8
                move    a1,x0                           ;   x0 = remainder
                mpy     x0,y0,a                         ;   a = (posType + change) % NUM_TYPE
                move    a1,n6                           ;   n6 = a
                move    n6,x:posType                    ;   posType = n6
                move    x:(r6+n6),r6                    ;   r6 = tabType[posType]

                move    #>IMPULSE_LEN,n6                ;   n6 = IMPULSE_LEN
                nop                                     ;   stall
                move    (r6)+n6                         ;   r6 = h(N-1) address
                do      #IMPULSE_LEN/2,loopTypeY        ;   copy Y mem impulse response
                move    y:(r6)-,y0                      ;   k = N-1, N-2, ..., N/2
                move    y0,y:(r5)+                      ;     Y mem *r5++ = h(k)
loopTypeY
                do      #IMPULSE_LEN/2,loopTypeX        ;   copy X mem impulse response
                move    x:(r6)-,x0                      ;   k = N/2-1, N/2-2, ..., 0
                move    x0,x:(r5)+                      ;     X mem *r5++ = h(k)
loopTypeX
                rts                                     ;


funcInfo        move    #>$80,y0                        ; y0 = 1 / 2**16
                mpy     x0,y0,a         x:posInfo,x0    ; a = enc chg >> 16, x0 = posInfo
                add     x0,a            #>@CVI((strAttn-strImga-3)*@POW(2,7)),x0        ;
                andi    #$FE,ccr                        ; x0 = strlen, clear carry flag
                rep     #8                              ; divide, a = a / x0
                div     x0,a                            ;   ...
                add     x0,a            #>$8000,y0      ; restore, y0 = 1 / 2**8
                move    a1,x0                           ; x0 = remainder
                mpy     x0,y0,a         #strImga+3,r6   ; a = (posInfo + change) % strlen
                move    a1,n6                           ; n6 = a
                move    n6,x:posInfo                    ; posInfo = n6
                move    (r6)+n6                         ; r6 = strImga + 3 + posInfo
                rts                                     ;


funcOver        move    #>strOver+3,r6                  ; r6 = string final char address
                rts                                     ;


funcBlnk        move    #>strBlnk+3,r6                  ; r6 = string final char address
                rts                                     ;


; Convert 6-bit 3/2 dB value, in a[13:8], to a 2.1 digit display string, pointed to by r6
dbs2str         move    #>@CVI(20*@POW(2,7+8)/3),x0     ; x0 = 20 / 3 justified
                andi    #$FE,ccr                        ; clear carry flag
                rep     #8                              ; divide, a = a / x0
                div     x0,a                            ;   ...
                add     x0,a            #>'0',y0        ; restore. y0 = ASCII 0
                move    a1,x0                           ; x0 = remainder
                move    a0,a                            ; a = quotient (tens)
                add     y0,a                            ; a = tens + '0'
                cmp     y0,a            #>' ',y0        ; if (tens = 0)
                teq     y0,a                            ;   blank leading zero
                move    a,x:(r6)+       x0,a            ; *buf++ = tens, a = remain

                move    #>@CVI(2*@POW(2,7+8+5)/3),x0    ; x0 = 2 / 3 justified
                andi    #$FE,ccr                        ; clear carry flag
                rep     #5                              ; divide, a = a / x0
                div     x0,a                            ;   ...
                add     x0,a            #>'0',y0        ; restore. y0 = ASCII 0
                move    a1,x0                           ; x0 = remainder
                move    a0,a                            ; a = quotient (ones)
                add     y0,a            #>'.',y0        ; a = ones + '0'
                move    a,x:(r6)+       x0,a            ; *buf++ = ones, a = remain

                move    y0,x:(r6)+                      ; *buf++ = '.'

                move    #>@CVI(2*@POW(2,7+8+5+4)/30),x0 ; x0 = 2 / 30 justified
                andi    #$FE,ccr                        ; clear carry flag
                rep     #4                              ; divide, a = a / x0
                div     x0,a                            ;   ...
                add     x0,a            #>'0',y0        ; restore. y0 = ASCII 0
                move    a0,a                            ; a = quotient (tenths)
                add     y0,a                            ; a = tenths + '0'
                move    a,x:(r6)                        ; *buf = tenths
                rts                                     ;


; Read 24-bit word from byte-wide P memory
readROMWord     do      #3,loopROMWord          ; Repeat for each of 3 bytes
                movem   p:(r0)+,a2              ;   a2 = ROM byte
                rep     #8                      ;   Shift byte into a1
                asr     a                       ;   a >>= 8
loopROMWord
                rts                             ;


; Timer interrupt service routine
isrTimer        move    #<0,x1                  ; Update frame tick counter
                move    y:frmTicks,b                    ; b = frmTicks
                cmp     x1,b            #>1,y1          ; if (b != 0)
                teq     y1,b                            ;   b--
                sub     y1,b            #>$6000,x1      ; x1 = encoder pin mask
                move    b1,y:frmTicks                   ; frmTicks = b

                                                ; Update rotary encoder position counter
                movep   x:PBD,b                         ; b = port B
                and     x1,b            y:pinEncdr,y1   ; b = enc pins, y1 = pinEncdr
                lsr     b               b1,y:pinEncdr   ; pinEncdr = enc pins
                lsr     b                               ; b = enc pins >> 2
                or      y1,b            #>$1000,x1      ; x1 = 1 / 2**11
                move    b1,y1                           ; y1 = pinEncdr | (enc pins >> 2)
                mpy     x1,y1,b                         ; b = y1 >> 11
                move    b1,n7                           ; n7 = delta offset
                move    x:posEncdr,b                    ; b = posEncdr
                move    y:(r7+n7),y1                    ; y1 = delta
                add     y1,b                            ; b = posEncdr + delta
                move    b1,x:posEncdr                   ; posEncdr += delta
                rti                                     ;


; SSI receive interrupt service routine
isrSSIRx        move    x:(r3)+,m4              ; m4 = *r3++, rx_length - 1
                move    x:(r3)+,n4              ; n4 = *r3++, rx_offset
                move    x:(r3),r4               ; r4 = *r3, rx_address
                nop                             ; Stall
                movep   x:SSIDR,x:(r4)+n4       ; *r4++ = SSIRX
                move    r4,x:(r3)+              ; *r3++ = r4, rx_address
                rti                             ;


; SSI transmit interrupt service routine
isrSSITx        move    x:(r2)+,m4              ; m4 = *r2++, tx_length - 1
                move    x:(r2)+,n4              ; n4 = *r2++, tx_offset
                move    x:(r2),r4               ; r4 = *r2, tx_address
                nop                             ; Stall
                movep   x:(r4)+n4,x:SSIDR       ; SSITX = *r4++
                move    r4,x:(r2)+              ; *r2++ = r4, tx_address
                rti                             ;


; Unexpected exception handler
excUnexpeced    jmp     <*

                END
