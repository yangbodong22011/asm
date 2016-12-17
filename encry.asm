data    segment
        fileKey db 2,?,2 dup(?) ;存储密钥
        fileHandle db 2 dup(?) ;存储文件代号
        filePath db 20,?,20 dup(?),00 ;存储文件路径
        newFilePath db 10,?,10 dup(?),00 ;存储加密或者解密的文件的路径
        temp  db 10 dup(?)             ;定义一段空的空间保存randNum溢出到前面位置
        fileBuffer  db 10000 dup(?) ;定义缓冲区
        randNum1 db 8 dup(0)     ;系统生成的随机数串
        flag db 0                ;随机数的个数
        temp1  db 8 dup(?)       ;将单个字符转换成二进制数码
    	temp2  db 8 dup(?)       ;将二进制数码调换顺序
    	temp3  db 0              ;将temp2的二进制数码转成temp3单个字符
    	nine   db 9              ;定义数字9
    	ten    db 0              ;temp2toSingle小循环cx
    	elev   db 0              ;temp2toSingle大循环cx
        openErrorTip db 'open file error !!$';提示打开文件失败
        readErrorTip db 'read file error !!$' ;提示读文件失败
        encryptErrorTip db 'encrypt file error !!$' ;提示加密文件失败
        encryptTrueTip db 'encrypt file true !!$';提示加密文件成功
        decryptErrorTip db 'decrypt file error!!$';提示解密文件失败
        decryptTrueTip db 'decrypt file true!!$';提示解密文件成功
        choiceTip db 'please input choise:$';提示功能选择
        choiceErrorTip db 'your choice is false ,choice again!!$'
        fileInputTip db 'please input source file path:$';提示源文件路径
        newFileInputTip db 'please input new file path:$';提示加密或者解密后的文件的路径
        keyTip db 'please input Key:$' ;提示输入密钥
        menu1 db '                  1.I want to decrypt $';菜单1，解密文件内容
        menu2 db '                  2.I want to encrypt$';菜单2，加密文件内容
        menu3 db '                  3.exit$';退出本程序
        divide db '                  *-*-*-*-*-*-*-*-*-*-*-*-$';分割符
        randomNumTip db 'the Random num is : $'
        choice db 2,?,2 dup(?) ;存储选择
        fileCount db ? ;定义实际读取的字节数
data    ends
code    segment
        assume ds:data,cs:code
main:
        ;展示菜单
        call displayMenu
        ;选择功能号
        call getChoice
        ;返回dos
        call returnDos
;***************
;展示本软件功能
displayMenu proc near
        mov ax,data
        mov ds,ax
        ;9号功能调用，显示分隔符
        mov dx,offset divide
        mov ah,9
        int 21h
        ;换行处理
        call nextLine
        ;9号功能调用，显示菜单1
        mov dx,offset menu1
        mov ah,9
        int 21h
        ;换行处理
        call nextLine
        ;9号功能调用，显示菜单2
        mov dx,offset menu2
        mov ah,9
        int 21h
        ;换行处理
        call nextLine
        ;显示菜单3
        mov dx,offset menu3
        mov ah,9
        int 21h
        ;换行处理
        call nextLine
        ;显示分隔符
        mov dx,offset divide
        mov ah,9
        int 21h
        ;换行处理
        call nextLine
        ret
displayMenu endp
;***************

;***************
;记录选择
getChoice proc near
        ;9号功能调用，提示选择
        mov dx,offset choiceTip
        mov ah,9
        int 21h
        ;10号功能调用,将选择的序号保存在choice中
        mov dx,offset choice
        mov ah,10
        int 21h
        ;换行处理
        call nextLine
        ;取得choice缓冲区中实际存储的ascall码，即选择的数
        lea bx,choice+2
        ;清空ax
        xor ax,ax
        ; 将choice缓冲区中的值送给al
        mov al,[bx]
        ;比较choice是不是和1相等
        cmp al,31h
        ;相等，则跳转getChoice1
        je getChoice1
        ; 不相等，则判断是不是和2相等
        cmp al,32h
        ;相等，则跳转getChoice2
        je getChoice2
        ;不相等，则判断是不是和3相等
        cmp al,33h
        ;相等，则跳转getChoice3
        je getChoice3
        ;不相等，则跳转choiceError，提示选择错误,并重新选择
        jmp choiceError
getChoice1:
        ; 调用解密
        call decrypt
        ret
getChoice2:
        ;调用加密
        call encrypt
        ret
getChoice3:
        ;返回dos，退出程序
        call returnDos
        ret
choiceError:
        ;9号功能调用，提示选择错误
        mov dx,offset choiceErrorTip
        mov ah,9
        int 21h
        ;换行处理
        call nextLine
        ;重新调用getChoice, 重新选择
        call getChoice
        ret
getChoice endp
;***************
;***************
;创建文件，cf＝0，返回文件代号，保存在ax中；cf＝1,创建失败
createFile proc near
create:
        ;9号功能调用，提示输入新的文件名加路径
        mov dx,offset newFileInputTip
        mov ah,9
        int 21h
        ;10号功能调用，将新文件名艺伎路径保存在newFilePath中
        mov dx,offset newFilePath
        mov ah,10
        int 21h
        ;换行处理
        call nextLine
        ;取得newFilePath缓冲区中实际输入的字符的个数
        lea bx,newFilePath+1
        ;清空cx
        xor cx,cx
        ;将newFilePath缓冲区实际存储的个数送给cx
        mov cl,[bx]
        ;判断是否输入
        cmp cx,00h
        ;如果输入的不为空，则跳转continue
        jnz continue
        ;如果输入的为空，则重新输入
        jmp create
continue:
        ;取得实际的存储路径
        lea bx,newFilePath+2
        ;处理enter的ascall码
        call findEnter
        ;系统调用，创建文件
        mov ah,3ch
        mov cx,00
        lea dx,newFilePath+2
        int 21h
        ; 将文件代号保存在fileHandle中
        lea si,fileHandle
        mov [si],ax
        ret
createFile endp
;***************

;***************
;打开文件，Cf＝0，返回文件代号，保存在ax中；cf＝1，打开失败
openFile proc near
        ;9号功能调用，提示输入文件名
        mov dx,offset fileInputTip
        mov ah,9
        int 21h
        ;10号功能调用，将文件名存储在filePath中
        mov dx,offset filePath
        mov ah,10
        int 21h
        ;换行处理
        call nextLine
        ;取得键盘上输入的实际的个数
        lea bx,filePath+1
        ; 清空cx
        xor cx,cx
        ;将键盘上实际输入的个数送给cx
        mov cl,[bx]
        ;取得文件实际的存储路径
        lea bx,filePath+2
        ;处理enter的ascall码
        call findEnter
        ;系统调用，打开文件
        mov ah,3dh
        mov al,00
        lea dx,filePath+2
        int 21h
        ; 若CF为1，打开失败
        jc  openError
        ;若CF为0，打开成功，获取返回的ax中的文件代号
        jmp getFileHandle
getFileHandle:
        ;取得fileHandle的地址空间
        lea bx,fileHandle
        ;将文件代号保存在fileHandle中
        mov [bx],ax
        ret
openError:
        ;9号功能调用，提示打开文件失败
        mov dx,offset openErrorTip
        mov ah,9
        int 21h
        ;返回dos
        call returnDos
        ret
openFile endp
;***************

;***************
;读文件
readFile proc near
        ;系统调用，读文件
        mov ah,3fh
        lea si,fileHandle
        mov bx,[si]
        mov cx,10000
        lea dx,fileBuffer
        int 21h
        ;cf＝1，读文件失败，cf＝0，读文件成功
        ;提示读取文件失败
        jc readError
        jmp getFileCount
getFileCount:
        ;将实际读取的字节数放在fileCount中
        lea bx,fileCount
        mov [bx],ax
        ret
readError:
        ;9号功能调用，提示读文件失败
        mov dx,offset readErrorTip
        mov ah,9
        int 21h
        ;返回dos
        call returnDos
        ret
readFile endp
;***************




;***************
;向文件写数据
writeFile proc near
        ;系统调用，写文件
        mov ah,40h
        lea si,fileHandle
        mov bx,[si]
        lea di,fileCount
        mov cx,[di]
        lea dx,fileBuffer
        int 21h
        ;cf＝1，写文件错误
        jc writeError
        jmp writeTrue
writeTrue:
        ;提示写文件成功
        lea bx,choice+2
        xor ax,ax
        mov al,[bx]
        cmp ax,31h
        je  decryptTrue
        jmp encryptTrue
decryptTrue:
        ;解密成功
        mov dx,offset decryptTrueTip
        mov ah,9
        int 21h
        ret
encryptTrue:
        ;加密成功
        mov dx,offset encryptTrueTip
        mov ah,9
        int 21h
        ret
writeError:
decryptFalse:
        ;解密失败
        mov dx,offset decryptErrorTip
        mov ah,9
        int 21h
        ret
encryptFalse:
        ;加密失败
        mov dx,offset encryptErrorTip
        mov ah,9
        int 21h
        ret
writeFile endp
;***************

;加密后向文件写数据
jiawriteFile proc near
        ;系统调用，写文件
        xor ax,ax
        xor bx,bx
        xor cx,cx

        mov ah,40h
        lea si,fileHandle
        mov bx,[si]
        lea di,fileCount
        mov cx,[di]
        add cx,8
        lea dx,fileBuffer-8
        int 21h
        ;cf＝1，写文件错误
        jc jiawriteError
        jmp jiawriteTrue
jiawriteTrue:
        ;提示写文件成功
        lea bx,choice+2
        xor ax,ax
        mov al,[bx]
        cmp ax,31h
        je  jiadecryptTrue
        jmp jiaencryptTrue
jiadecryptTrue:
        ;解密成功
        mov dx,offset decryptTrueTip
        mov ah,9
        int 21h
        ret
jiaencryptTrue:
        ;加密成功
        mov dx,offset encryptTrueTip
        mov ah,9
        int 21h
        ret
jiawriteError:
jiadecryptFalse:
        ;解密失败
        mov dx,offset decryptErrorTip
        mov ah,9
        int 21h
        ret
jiaencryptFalse:
        ;加密失败
        mov dx,offset encryptErrorTip
        mov ah,9
        int 21h
        ret
jiawriteFile endp


;解密后向文件写数据
jiewriteFile proc near
        ;系统调用，写文件
        xor ax,ax
        xor bx,bx
        xor cx,cx

        mov ah,40h
        lea si,fileHandle
        mov bx,[si]
        lea di,fileCount
        mov cx,[di]
        sub cx,8
        lea dx,fileBuffer+8
        int 21h
        ;cf＝1，写文件错误
        jc jiewriteError
        jmp jiewriteTrue
jiewriteTrue:
        ;提示写文件成功
        lea bx,choice+2
        xor ax,ax
        mov al,[bx]
        cmp ax,31h
        je  jiedecryptTrue
        jmp jieencryptTrue
jiedecryptTrue:
        ;解密成功
        mov dx,offset decryptTrueTip
        mov ah,9
        int 21h
        ret
jieencryptTrue:
        ;加密成功
        mov dx,offset encryptTrueTip
        mov ah,9
        int 21h
        ret
jiewriteError:
jiedecryptFalse:
        ;解密失败
        mov dx,offset decryptErrorTip
        mov ah,9
        int 21h
        ret
jieencryptFalse:
        ;加密失败
        mov dx,offset encryptErrorTip
        mov ah,9
        int 21h
        ret
jiewriteFile endp


;***************
;关闭文件
closeFile proc near
        mov ah,3eh
        int 21h
        ret
closeFile endp
;***************

;***************
;返回dos
returnDos proc near
        mov ah,4ch
        int 21h
        ret
returnDos endp
;***************

;***************
;换行处理
nextLine proc near
        mov dl,0dh
        mov ah,2
        int 21h
        mov dl,0ah
        mov ah,2
        int 21h
        ret
nextLine endp
;***************


;***************
;创建随机数并存入文件
createRandNum:
      lea si,randNum1
      mov cx,8
      doRand:
        push cx
        doRand1:
            call getRand
        
            xor di,di
            xor cx,cx

            lea di,randNum1
            mov cx,8
            createRandNumdo2:
                mov bh,[di]
                cmp bh,al
                jz doRand1
                inc di
                loop createRandNumdo2
        
        mov bh,flag[0]
        add bh,1
        mov flag[0],bh

        cmp bh,9
        jz mRet

        mov [si],al
        inc si

        
        pop cx
    loop doRand

;***************
;获取随机数 范围1-8
getRand:
    xor al,al
    mov ax, 0h;间隔定时器
    out 43h, al;通过端口43h
    in al, 40h;
    in al, 40h;
    in al, 40h;访问3次，保证随机性

    mov bl, 8
    div bl 

    mov al, ah
    mov ah, 0

    inc al

    ret

;***************
;返回
mRet:
      ret
;***************
; 输出生成的随机数

outRandom:
		lea di,randNum1
        mov cx,8
        xor bx,bx
        outRandomdo:
        	mov dl,[di+bx]
        	inc bx
        	add dl,30h
        	xor ah,ah
        	mov ah,02
        	int 21h   
    	loop outRandomdo
    	ret


;***************
;将一个字符转换成二进制存入变量temp1
fetchBinary:
    push bx;
    push cx;

    xor dx,dx;

    lea si,temp1 
    mov dl,[bx]

    mov dh,dl;  
    and dh,10000000B
    cmp dh,00H
    jz _1
    mov dh,01h
    _1:
    mov [si],dh
    inc si

    mov dh,dl  
    and dh,01000000B
    cmp dh,00H
    jz _2
    mov dh,01H
    _2:
    mov [si],dh
    inc si

    mov dh,dl  
    and dh,00100000B
    cmp dh,0
    jz _3
    mov dh,01H
    _3:
    mov [si],dh
    inc si

    mov dh,dl 
    and dh,00010000B
    cmp dh,00H
    jz _4
    mov dh,01h
    _4:
    mov [si],dh
    inc si

    mov dh,dl  
    and dh,00001000B
    cmp dh,00H
    jz _5
    mov dh,01h
    _5:
    mov [si],dh
    inc si

    mov dh,dl  
    and dh,00000100B
    cmp dh,00H
    jz _6
    mov dh,01h
    _6:
    mov [si],dh
    inc si

    mov dh,dl  
    and dh,00000010B
    cmp dh,00H
    jz _7
    mov dh,01h
    _7:
    mov [si],dh
    inc si

    mov dh,dl  
    and dh,00000001B
    cmp dh,00H
    jz _8
    mov dh,01h
    _8:
    mov [si],dh

    pop cx;
    pop bx;

    ret

;***************
;根据生成的随机值IP置换将temp1中内容保存至temp2
ipDisplace:
   	push bx;
    push cx;

    xor cx,cx
    mov cx,8

    lea si,temp1
    lea di,randNum1
    xor bx,bx
    lea bx,temp2
    ipDisplacedo2: 
        mov al,[di]

        ;mov dl,ah
        ;mov ah,2
        ;int 21h

        mov dl,[si]
        push si
        mov ah,0
        mov si,ax
        mov [bx+si-1],dl
        ;call M
        ;call S
        pop si
        ; mov [bx+ah],[si]
        inc di;
        inc si;
        loop ipDisplacedo2

    pop cx;
    pop bx;
    ret

;***************
;将temp2中的串转换成单个字符保存
temp2ToSingle:
   	push bx
    push cx
    
    xor cx,cx
    xor ax,ax
    xor dx,dx

    mov cx,8

    lea si,temp2

    do3:
        mov al,[si]

        push cx;
        dec cx           ;给cx减去一
        cmp cx,0
        jz down
        do4:
            shl al,1
            loop do4

down:   pop cx;
    
        lea di,temp3
        mov dl,[di]
        add dl,al
        mov [di],dl


        ;mov dl,temp3
        ;add dl,al
        ;mov temp3,dl

        ;mov dl,al
        ;mov ah,2
        ;int 21h
        
        inc si
        loop do3

    pop cx
    pop bx
    ret

;***************
;根据之前解密的随机数随机值IP置换将temp1中内容保存至temp2
ipDisplace2:
   	push bx;
    push cx;
    push ax;

    xor cx,cx
    xor bx,bx
    xor ax,ax

    mov cx,8
    
    

   	ipDisplace2do2: 
   		xor di,di
    	lea di,randNum1

		xor ax,ax
    	mov ten[0],cl
    	push cx

    	xor cx,cx
    	mov cx,8


    	ipDisplace2do3:
    		mov elev[0],cl

    		xor bx,bx
    		xor ax,ax

    		mov bx,[di]
    		
    		mov al,ten[0]


       		sub ax,bx
    		cmp al,0
    		jz mrecord

    		inc di
    	loop ipDisplace2do3

mrecord: 
		lea si,temp1
		xor bx,bx
		mov bl,ten[0]
        mov dl,[si+bx-1]    ;将si的内容移动到dl

        xor ax,ax
        mov al,nine[0]
        sub al,elev[0]


        pop cx

        xor bx,bx
		lea bx,temp2

        mov si,ax
        mov [bx+si-1],dl

        loop ipDisplace2do2

    pop ax
    pop cx
    pop bx
    ret
;***************
;***************
;***************
;***************
;***************
;***************
;***************

;***************
;加密文件内容
encrypt proc near
		call createRandNum

		lea dx,randomNumTip
		mov ah,9
		int 21h

		call outRandom
		call nextLine


        call openFile
        call readFile
        call closeFile
        

        ;清cx
        xor cx,cx
        ;将实际读取的子节数送至cx

        lea si,fileCount
        mov cx,[si]
        lea bx,fileBuffer
        call saveKey
        ;加密文件内容

        push cx

        ;将生成的随机数保存进文件前八个字节
        
        mov cx,8
        sub bx,8
        lea si,randNum1
        saveRand:
            xor ax,ax
        	mov al,[si]
        	mov [bx],al
        	inc si;
        	inc bx
        loop saveRand

        pop cx

do:

		mov dl,[bx]
        mov di,offset fileKey+2
        mov al,[di]
        add al,dl
        mov [bx],al

       
		call fetchBinary
		call ipDisplace
		call temp2ToSingle


		lea  si,temp3
		mov  al,[si]
		mov [bx],al


		lea di,temp3    ;每使用完一次将temp3置0
        mov dl,[di]
        mov dl,0
        mov [di],dl


        inc bx
       	loop do



        call createFile
        call jiawriteFile
        call closeFile
        ret
encrypt endp
;***************

;***************
;解密文件内容
decrypt proc near
        ; 打开文件
        call openFile
        ;读文件
        call readFile
        ;关闭文件
        call closeFile
        ;清cx
        xor cx,cx
        ;将文件实际的字节数送至cx
        lea si,fileCount
        mov cx,[si]
        sub cx,8
        ;取缓冲区的地址
        lea bx,fileBuffer
        ;保存密钥
        call saveKey


        push cx
        ;将读出的随机数串保存入randNum
        mov cx,8
        lea si,randNum1
        getRandFromFile:
            xor ax,ax
        	mov al,[bx]
        	mov [si],al
        	inc si
        	inc bx
        loop getRandFromFile

        pop cx

undo:
        ;解密文件内容
        ;mov al,[bx]
        ;mov dl,al
        ;mov ah,02
        ;int 21h

        call fetchBinary
        call ipDisplace2
        call temp2ToSingle
      

        lea  si,temp3
		mov  al,[si]
		mov [bx],al


		lea di,temp3    ;每使用完一次将temp3置0
        mov dl,[di]
        mov dl,0H
        mov [di],dl


        push dx

        xor dx,dx
        xor ax,ax

        mov al,[bx]
        mov di,offset fileKey+2
        mov dl,[di]
        sub al,dl
        mov [bx],al

        pop dx

        

        inc bx
       	loop undo

        call createFile
        call jiewriteFile
        call closeFile
        ret
decrypt endp
;***************

;***************
;将回车所占的地址空间的值设为00h
findEnter proc near
next1:
        inc bx
        loop next1
        mov al,00h
        mov [bx],al
        ret
findEnter endp
;***************

;***************
;提示输入密钥，并保存在fileKey中
saveKey proc near
        ;9号功能调用，提示输入密码
        mov dx,offset keyTip
        mov ah,9
        int 21h
        ;10号功能调用，将密钥保存在fileKey中
        mov dx,offset fileKey
        mov ah,10
        int 21h
        call nextLine

        xor dx,dx
        xor ax,ax

        ret
saveKey endp
;***************
code    ends
    end     main
