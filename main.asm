    DOSSEG
    .MODEL SMALL
    .STACK 32
    .DATA
encoded     DB  80 DUP(0)
temp        DB  '0x', 160 DUP(0)
fileHandler DW  ?
filename    DB  'in/in.txt', 0          ; Trebuie sa existe acest fisier 'in/in.txt'!
outfile     DB  'out/out.txt', 0        ; Trebuie sa existe acest director 'out'!
message     DB  80 DUP(0)
msglen      DW  ?
padding     DW  0
iterations  DW  0 
x           DW  ?
x0          DW  ?
a           DW  0
b           DW  0
var         DW  0
lastName    DB  'Avram'
lastNameLength equ $-lastName
firstName   DB  'Mara'
firstNameLength equ $-firstName
cod64       DB  'Bqmgp86CPe9DfNz7R1wjHIMZKGcYXiFtSU2ovJOhW4ly5EkrqsnAxubTV03a=L/d'

    .CODE
START:

    MOV     AX, @DATA
    MOV     DS, AX
   
    CALL    FILE_INPUT                  ; NU MODIFICATI!
    
    CALL    SEED                        ; TODO - Trebuie implementata

    CALL    ENCRYPT                     ; TODO - Trebuie implementata
    
    CALL    ENCODE                      ; TODO - Trebuie implementata
    
                                        ; Mai jos se regaseste partea de
                                        ; afisare pe baza valorilor care se
                                        ; afla in variabilele x0, a, b, respectiv
                                        ; in sirurile message si encoded.
                                        ; NU MODIFICATI!
    MOV     AH, 3CH                     ; BIOS Int - Open file
    MOV     CX, 0
    MOV     AL, 1                       ; AL - Access mode ( Write - 1 )
    MOV     DX, OFFSET outfile          ; DX - Filename
    INT     21H
    MOV     [fileHandler], AX           ; Return: AX - file handler or error code

    CALL    WRITE                       ; NU MODIFICATI!

    MOV     AH, 4CH                     ; Bios Int - Terminate with return code
    MOV     AL, 0                       ; AL - Return code
    INT     21H

FILE_INPUT:
    MOV     AH, 3DH                     ; BIOS Int - Open file
    MOV     AL, 0                       ; AL - Access mode ( Read - 0 )
    MOV     DX, OFFSET fileName         ; DX - Filename
    INT     21H
    MOV     [fileHandler], AX           ; Return: AX - file handler or error code

    MOV     AH, 3FH                     ; BIOD Int - Read from file or device
    MOV     BX, [fileHandler]           ; BX - File handler
    MOV     CX, 80                      ; CX - Number of bytes to read
    MOV     DX, OFFSET message          ; DX - Data buffer
    INT     21H
    MOV     [msglen], AX                ; Return: AX - number of read bytes

    MOV     AH, 3EH                     ; BIOS Int - Close file
    MOV     BX, [fileHandler]           ; BX - File handler
    INT     21H

    RET
SEED:
    MOV     AH, 2CH                     ; BIOS Int - Get System Time
    INT     21H
    ;CH*60
    MOV     AH,CH                       ;pun CH in AH
    MOV     AL,60                       ;pun 60 in AH
    MUL     AH                          ;inmultesc AH cu 60 rezultatul se pune in AX(AX=CH*60)
    MOV     BL,CL
    MOV     BH,0                        ;inmultesc AH cu 60 rezultatul se pune in AX(AX=CH*60)
    ; + CL
    ADD     AX,BX                       ;in BX este CL, se aduna CL cu CH*60
    MOV     BX,60
    MOV     CX,DX                       ; se salveaza DX in CX pentru a nu pierde valorile din DX
    ; *60
    MUL     BX                          ; deoarece inmultirea va rezulta pe DX:AX
    MOV     BL,CH                       
    MOV     BH,0
    ; +DH
    ADD     AX,BX                       ;adunam BX(DH)
    ADC     DX,0                        ;adunam carry-ul la DX deoarece rezultatul il avem pe DX:AX
   ; * 100
    MOV     BX,100
    MUL     BX                          ;DX:AX MOD 255, rezultatul(restul) se pune in DX
    ;;;;;;;;;;;;;;;;;;
    MOV     CH,0
    ADD     AX,CX
    ADC     DX,0
    MOV     CX,255
    DIV     CX
    MOV     x,DX
    MOV     x0,DX

    RET                                     ;TODO1
ENCRYPT:
    
    MOV     CX, [msglen]
    MOV     SI, OFFSET message
    encrypt_label:
    MOV     AX,x
    MOV     BL,byte ptr [SI]
    XOR     BX,AX
    MOV     byte ptr [SI],BL
    PUSH    SI
    PUSH    CX
    CALL    RAND
    POP     CX
    POP     SI
    INC SI
    LOOP encrypt_label

                                            ; TODO3: Completati subrutina ENCRYPT
                                            ; astfel incat in cadrul buclei sa fie
                                            ; XOR-at elementul curent din sirul de
                                            ; intrare cu termenul corespunzator din
                                            ; sirul generat, iar mai apoi sa fie generat
                                            ; si termenul urmator
    RET
RAND:
    MOV     AX,0
    MOV     DX,0
    ;;calculez suma literelor din prenume "Mara"
    MOV     CX,firstNameLength
    MOV     SI,OFFSET firstName
    firstNameSum:
   
    MOV     BX,0
    MOV     BL,byte ptr[SI]
    ADD     AX, BX
    INC     SI
    LOOP firstNameSum

    MOV     CL,255
    DIV     CL
    MOV     AL,AH
    MOV     AH,0
    MOV     a,AX

    ;;calculez suma literelor din nume "Avram"
    MOV     AX,0
    MOV     DX,0
    MOV     CX,lastNameLength
    MOV     SI,OFFSET lastName
    lastNameSum:
  
    MOV     BX,0
    MOV     BL,byte ptr[SI]
    ADD     AX, BX
    INC     SI
    LOOP lastNameSum

    MOV     CL,255
    DIV     CL
    MOV     AL,AH
    MOV     AH,0
    MOV     b,AX
    
    MOV     AX,[x]
    MUL     a
    ADD     AX,b
    MOV     CL,255
    DIV     CL
    MOV     AL,AH
    MOV     AH,0
    MOV     x,AX
    RET
                                            ; TODO2


ENCODE:
    ;;adaugare padding CAZUL 0
    MOV     AX,[msglen]
    MOV     CH,0
    MOV     CL,3
    DIV     CL                         ;se calculeaza restul si catul impartirii
    MOV     BL,3                       ;lui msglen la 3
    MOV     BH,0
    MOV     DL,AL
    MOV     DH,0
    MOV     [iterations],DX         ;iterations = numarul de it. care nu includ paddingul
    MOV     AL,AH
    MOV     AH,0
    CMP     AX,0
    JZ      else1
    SUB     BL,AL
    MOV     padding,BX             ;padding = numarul de it. pt padding
 
else1:
    MOV     CX,iterations
    MOV     SI,OFFSET message
    MOV     DI,OFFSET encoded
    blocks_encoding_label:
    ;;shiftare cu 2 la dreapta(primul caracter din bloc)
    MOV     DL,00000011B
    MOV     BL,[SI]
    AND     DL,BL                       ;DL = bitii shiftati(se pastreaza pt urmatoarea shiftare)
    SHR     BL,2                        ;se iau primii 6 biti din primul octet
    PUSH    SI
    MOV     SI,OFFSET cod64
    ADD     SI,BX
    MOV     AL,[SI]                     ;se calculeaza caracterul asociat din COD64
    MOV     [DI],AX                     ;se pune pe pozitia asociata din encoded
    POP     SI
    INC     SI
    INC     DI

    ;;shiftare cu 4 la dreapta(al doilea caracter din bloc)
    MOV     AL,DL                       ;in DL se afla restul de biti din octetul anterior
    MOV     DL,00001111B
    MOV     BL,[SI]
    AND     DL,BL
    SHR     BL,4
    SHL     AL,4
    ADD     BL,AL
    PUSH    SI
    MOV     SI,OFFSET cod64
    ADD     SI,BX
    MOV     AL,[SI]
    MOV     [DI],AX
    POP     SI
    INC     SI
    INC     DI

    ;;shiftare cu 6 la dreapta(al treilea caracter din bloc)
    MOV     AL,DL
    MOV     DL,00111111B
    MOV     BL,[SI]
    AND     DL,BL
    SHR     BL,6
    SHL     AL,2
    ADD     BL,AL
    PUSH    SI
    MOV     SI,OFFSET cod64
    ADD     SI,BX
    MOV     AL,[SI]
    MOV     [DI],AX
    POP     SI
    INC     SI
    INC     DI

    ;;au ramas 6 biti din ultimul octet din bloc, nu mai trebuie shiftati
    PUSH    SI
    MOV     SI,OFFSET cod64
    ADD     SI,DX
    MOV     AL,[SI]
    MOV     [DI],AX
    POP     SI
    ;INC     SI
    INC     DI
    
    MOV     AX,0
    MOV     BX,0
    MOV     DX,0
    LOOP blocks_encoding_label
    
    ;INC     SI
    CMP     padding,0
    JNE     bun
    JMP      padding_0
    bun:
    MOV     DL,00000011B
    MOV     BL,[SI]
    AND     DL,BL                       ;DL = bitii shiftati(se pastreaza pt urmatoarea shiftare)
    SHR     BL,2                        ;se iau primii 6 biti din primul octet
    PUSH    SI
    MOV     SI,OFFSET cod64
    ADD     SI,BX
    MOV     AL,[SI]                     ;se calculeaza caracterul asociat din COD64
    MOV     [DI],AX                     ;se pune pe pozitia asociata din encoded
    POP     SI
    INC     SI
    INC     DI

    ;;shiftare cu 4 la dreapta(al doilea caracter din bloc)
    MOV     AL,DL                       ;in DL se afla restul de biti din octetul anterior
    MOV     DL,00001111B
    MOV     BL,[SI]
    CMP     BL,0
    JZ      zero_oct1
    AND     DL,BL
    SHR     BL,4
zero_oct1:
    SHL     AL,4
    ADD     BL,AL
    PUSH    SI
    MOV     SI,OFFSET cod64
    ADD     SI,BX
    MOV     AL,[SI]
    MOV     [DI],AX
    POP     SI
    INC     SI
    INC     DI

    CMP     padding,2
    JZ      caz1

caz2:
    MOV     AL,DL
    MOV     DL,00111111B
    MOV     BL,[SI]
    CMP     BL,0
    JZ      zero_oct2
    AND     DL,BL
    SHR     BL,6
zero_oct2:
    SHL     AL,2
    ADD     BL,AL
    PUSH    SI
    MOV     SI,OFFSET cod64
    ADD     SI,BX
    MOV     AL,[SI]
    MOV     [DI],AX
    POP     SI
    INC     SI
    INC     DI
    
caz1:  
    MOV     CX,padding
    ;SUB     CX,1
    ADD     iterations,1
    MOV     AL,2Bh
    MOV     AH,0
    padding_loop:
    MOV     [DI],AX
    INC     DI
    LOOP padding_loop
    
padding_0:
    
                                            ; TODO4: Completati subrutina ENCODE, astfel incat
                                            ; in cadrul acesteia va fi realizata codificarea
                                            ; sirului criptat pe baza alfabetului COD64 mentionat
                                            ; in enuntul problemei si rezultatul va fi stocat
                                            ; in cadrul variabilei encoded
    RET
WRITE_HEX:
    MOV     DI, OFFSET temp + 2
    XOR     DX, DX
DUMP:
    MOV     DL, [SI]
    PUSH    CX
    MOV     CL, 4

    ROR     DX, CL
    
    CMP     DL, 0ah
    JB      print_digit1

    ADD     DL, 37h
    MOV     byte ptr [DI], DL
    JMP     next_digit

print_digit1:  
    OR      DL, 30h
    MOV     byte ptr [DI] ,DL
next_digit:
    INC     DI
    MOV     CL, 12
    SHR     DX, CL
    CMP     DL, 0ah
    JB      print_digit2

    ADD     DL, 37h
    MOV     byte ptr [DI], DL
    JMP     AGAIN

print_digit2:    
    OR      DL, 30h
    MOV     byte ptr [DI], DL
AGAIN:
    INC     DI
    INC     SI
    POP     CX
    LOOP    dump
    
    MOV     byte ptr [DI], 10
    RET
WRITE:
    MOV     SI, OFFSET x0
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21h

    MOV     SI, OFFSET a
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET b
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET x
    MOV     CX, 1
    CALL    WRITE_HEX    
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET message
    MOV     CX, [msglen]
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, [msglen]
    ADD     CX, [msglen]
    ADD     CX, 3
    INT     21h

    MOV     AX, [iterations]
    MOV     BX, 4
    MUL     BX
    MOV     CX, AX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET encoded
    INT     21H

    MOV     AH, 3EH                     ; BIOS Int - Close file
    MOV     BX, [fileHandler]           ; BX - File handler
    INT     21H
    RET
    END START