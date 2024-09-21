.global main
// TODO:  fix chunk reading
//CONSTANTES PARA LLAMADAS AL SISTEMA
.equ    SYS_open,  5 //Opens a file, returns file descriptor
.equ    SYS_read,  3 //reads data from file descriptor
.equ    SYS_write, 4 //write data to a file descriptor
.equ    SYS_close, 6 //closes a files descriptor
.equ    SYS_exit,  1 //terminates program
.equ    SYS_creat, 8 //creates file

.equ    SPACE,      32
//CONSTANTES PARA SIZE DEL BUFFER Y DICCIONARIO
.equ    FILE_BUFF_SIZE,     4096        //BUFFER DE PAGINA DE ARCHIVO DE 4KB
.equ    WORD_BUFF_SIZE,     64         //BUFFER PALABRA DE 128B
.equ    DICTIONARY_SIZE,    200000       //Size of dictionary alberta 25mil palabras en par puntero-frecuencia
.equ    COUNTED_WORD_SIZE,  250000     //Size for word string
.section .data 
    file_name:  .asciz      "tokenized_text.txt"
    word_count: .space      DICTIONARY_SIZE
    freq_file:  .asciz      "frequencies.txt"

.section .bss
    file_buffer:     .space      FILE_BUFF_SIZE
    words_buffer:    .space      WORD_BUFF_SIZE
    counted_words:   .space      COUNTED_WORD_SIZE
.section .text

_start:
    ldr r0, =file_name      //puntero a nombre de archivo
    mov r1, #0              //flags:    0_RDONLY
    mov r7, #SYS_open        //system call to open files
    swi 0                   //trigger system call
    mov r6, r0              //Save file descriptor in R6

    //read chunk
    ldr r1, =file_buffer
    mov r2, #FILE_BUFF_SIZE
read_chunk:
    mov r0, r6              //file descriptor to r0
    ldr r1, =file_buffer
    mov r2, #FILE_BUFF_SIZE
    mov r7, #SYS_read        //read file descriptor system call
    swi 0                   //trigger system call

    cmp r0, #0              //check if eof
    beq save_count

    ldr r0, =file_buffer        //file buffer addr to r0
    ldr r1, =word_count          //load addr to word dictionary
    ldr r2, =words_buffer       //words buffer addr to r0
    bl count_words

    b read_chunk

count_words:
    push {r4-r7, lr}
    mov r3, #0          //current buffer index
    mov r4, #0          //current word buffer index

    next_char_processing:
        ldrb r5, [r0, r3]   //read next character from buffer
        cmp r5, #0          //check if buffer has reached its end
        beq finish_counting

        cmp r5, #SPACE       //check if its space (word divider)
        beq store_word      //if space, store word

        strb r5, [r2, r4]   //store the character in the word buffer
        add r4, r4, #1      //increment word buffer index
        add r3, r3, #1      //increment buffer index
        b next_char_processing

    store_word:
        mov r5, #0          //null terminator
        strb r5, [r2, r4]   //add null character to the word buffer
        mov r4, #0          //reset word buffer index

        bl check_word_exists

        add r3, r3, #1      //increment buffer index, skip null character
        b next_char_processing
    
    check_word_exists:
        push {r0-r3, lr}

        mov r6, r1                  //load the dict addr
        ldr r7, =words_buffer       //load the word buffer address
        mov r8, #0                  //dictionary index

    check_dictionary:
        lsl r10, r8, #3
        ldr r9, [r6, r10]           //load next word from dictionary
        cmp r9, #0                  //check if its the end of the dicitonary
        beq add_new_word            //if a free space is reached, add new word

        bl find_n_word
        
        
        mov r0, r7                  //load word buffer
        mov r1, r9                  //load dictionary word
        
        
        bl strcmp                   //compare strings

        beq increment_count

        //else
        add r8, r8, #1              //move to next word in dictionary
        b check_dictionary          //continue checking

    add_new_word:
        bl find_n_word
        mov r7, r9
        ldr r9, =word_count          //load dictionary array to r9
        add r9, r9, r8, LSL #3      //point to new slot in dictionary r8*8

        str r7, [r9]                //store new word in the new dictionary slot

        bl strcpy

        mov r10, #1
        str r10, [r9, #4]           //stores 1, as the word count

        pop {r0-r3,lr}             //restore registers
        bx lr
    
    increment_count:
        ldr r9, =word_count          //load dictionary into r9
        add r9, r9, r8, LSL #3       //point to the word entry in the dictionary
        ldr r10, [r9, #4]           //load the current count
        add r10, r10, #1            //increment counter
        str r10, [r9, #4]           //store updated count

        pop {r0-r3,lr}
        bx lr

    finish_counting:
        pop {r4-r7, lr}
        bx lr

    strcmp:
        push {r4-r6, lr}
        cmp r0, r1
        beq end_strcmp  
        mov r4, #0
    
        compare_loop:
            ldrb r5, [r0,r4]       //load byte from string1 and increment pointer
            ldrb r6, [r1,r4]       //load byte from string 2 and increment pointer

            add r4, r4, #1
            cmp r5, r6
            bne end_strcmp
            cmp r5, #0
            bne compare_loop
        end_strcmp:
            pop {r4-r6, lr}
            bx lr
    strcpy:
        push {r4-r6, lr}
        mov r4, #0
        mov r5, #0
    
        mov r5, #0

        loop_characters_cw:
            ldrb r6, [r2, r4]
            strb r6, [r7, r5]
            add r4, r4, #1
            add r5, r5, #1
            cmp r6, #0
            bne loop_characters_cw
            b finish_copy
        finish_copy:
            mov r6, #0
            strb r6, [r7, r5] //adds the null character at the end
            pop {r4-r6, lr}
            bx lr
    find_n_word:
    //saves the pointer to the nth word saved in counted words. Returns to r9, takes n from r8
        push {r4-r6,lr}
        mov r4, #0              //local index
        ldr r5, =counted_words  //array donde se almacenan los strings del diccionario
        cmp r8, #0
        beq first_word
        loop_words:
            cmp r4, r8          //compare current word index to dictionary index
            beq word_found
            loop_characters:
                ldrb r6, [r5], #1
                cmp r6, #0
                bne loop_characters
                add r4, r4, #1
                b loop_words
        
        word_found:
            
            first_word:
            mov r9, r5
            pop {r4-r6, lr}
            bx lr

save_count:
    ldr r4, =word_count     //diccionario con frecuencias
    ldr r5, =words_buffer   //buffer para guardar numero en ascii
    ldr r7, =file_buffer   //buffer para guardar string a guardar en texto
    mov r8, #0              //indice de diccionario
    mov r9, #0              //indice de buffer
    
    sweep_dictionary:
        add r10, r4, r8, lsl #3
        ldr r6, [r10]
        cmp r6, #0
        beq save_to_file
        //copy word to file buffer
        mov r2, r6
        ldr r7, =file_buffer
        bl strcpy_buffer
        add r9, r9, #1
        //copy frequency in ascii to file buffer
        ldr r0, [r10, #4]
        ldr r1, =words_buffer
        bl int_to_ascii
        ldr r2, =words_buffer
        ldr r7, =file_buffer
        bl strcpy_buffer
        add r9, r9, #1

        add r8, r8, #1
        b sweep_dictionary
        
        
strcpy_buffer:
        push {r4-r6, lr}
        mov r4, #0

        loop_characters_fb:
            ldrb r6, [r2, r4]
            strb r6, [r7, r9]
            add r4, r4, #1
            add r9, r9, #1
            cmp r6, #0
            bne loop_characters_fb
            b finish_copy_fb
        finish_copy_fb:
            add r9, r9, #-1
            mov r6, #SPACE
            strb r6, [r7, r9] //adds SPACE character at the end
            pop {r4-r6, lr}
            bx lr        

int_to_ascii:
    push {r2-r5, lr}
    //number in r0
    //buffer in r1
    add r1, r1, #11             //mover al final del buffer para máximo 11 dígitos
    mov r3, #0
    strb r3, [r1], #-1
    conver_to_ascii:
        mov r3, r0              //number to r3
        mov r4, #10             //divisor para lsd
        bl __divmod
        add r5, r5, #48         //suma 48 al dítito dígito 0 = ascii(48)
        strb r5, [r1], #-1      //almacenar con postindice
        cmp r3, #0              //comprobación de número finalizado
        bne conver_to_ascii     //iterar

        add r1, r1, #1
        mov r2, r1
        ldr r7, =words_buffer

        bl strcpy
        pop {r2-r5, lr}
        bx lr
        
    __divmod:
        push {lr}
        udiv r0, r3, r4         //cociente de r3 /10
        mls r5, r0, r4,r3          //residuo = r3 - (cociente*10)
        pop {lr}
        bx lr   
save_to_file:
    //null character to end string
    mov r6, #0
    strb r6, [r7, r9]
    ldr r0, =freq_file
    mov r1, #0777              //seteo de permisos a todos
    mov r7, #SYS_creat         //create file
    swi 0  

    mov r7, #SYS_write         //write to file
    ldr r1, =file_buffer       //file name
    mov r2, r9                 // r9 has the string size
    swi 0

    mov r7, #SYS_close         
    swi 0
end_program:
    mov r7, #SYS_exit           //system call to exit program
    mov r7, #SYS_exit           //system call to exit program
    swi #0
