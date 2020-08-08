assume cs:codesg,ds:datasg

;-----------------------------------------------------------------------------------------
datasg segment
  ; 全局变量,16 bytes
  db 16 dup(0)

  ; 0 ~ 83   bytes
  db '1975', '1976', '1977', '1978', '1979', '1980', '1981', '1982', '1983'
  db '1984', '1985', '1986', '1987', '1988', '1989', '1990', '1991', '1992'
  db '1993', '1994', '1995'

  ; 84 ~ 167 bytes
  dd 16, 22, 382, 1356, 2390, 8000, 16000, 24486, 50065, 97479, 140417, 197514
  dd 345980, 590827, 803530, 1183000, 1843000, 2759000, 3753000, 4649000, 5937000

  ; 168 ~ 208 bytes
  dw 3, 7, 9, 13, 28, 38, 130, 220, 476, 778, 1001, 1442, 2258, 2793, 4037, 5635, 8226
  dw 11542, 14430, 15257, 17800
datasg ends
;-----------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------
codesg segment
   start: mov ax,datasg
          mov ds,ax

          mov ax,0b800H
          mov es,ax

          mov word ptr ds:[0],0       ; 0 ~ 1 bytes: 4字节的偏移，针对年份和收入属性的偏移   
          mov word ptr ds:[2],0       ; 2 ~ 3 bytes: 2字节的偏移，针对雇员的偏移
          mov word ptr ds:[4],0       ; 4 ~ 5 bytes: 记录行数，16 位乘法的默认乘数     
          mov word ptr ds:[6],160     ; 6 ~ 7 bytes: 显示缓冲区中每一行的偏移，每一行由 160 bytes
          
          mov cx,0015h                ; 一共有 21 组数据，故需要循环 21 次

       l: ; 计算本次循环对应行数在显示缓冲区的起始偏移量
          mov ax,ds:[4]               ; 取出缓冲区中所保存的行数  
          mul word ptr ds:[6]         ; 计算此行(此次循环)所依赖的偏移
          mov bx,ax
          
          mov di,ds:[0]               ; 取出缓冲区所保存的针对4字节成员数据的偏移

          ; 写入年份() {
          mov bp,0
          push cx
          mov cx,4
   syear: mov dl,ds:[di+bp+16]
          mov es:[bx+0],dl            ; char
          mov byte ptr es:[bx+1],2    ; color
          add bx,2
          inc bp
          loop syear
          pop cx
          ; }

          add bx,10                   ; to next property

          ; 写入收入() {
          mov ax,ds:[di+84+16]        ; low  16 bit
          mov dx,ds:[di+86+16]        ; high 16 bit
          call ddtoc
          add bx,0014H                ; 补全函数调用后写入的最终偏移
          ; }

          add bx,10                   ; to next property

          ; 写入雇员数() {
          mov di,ds:[2]               ; 取出缓冲区所保存的针对2字节成员数据的偏移
          mov ax,ds:[di+168]
          call dtoc
          add bx,000EH
          ; }

          add bx,10
          
          ; 写入平均数() {
          push cx

          mov di,ds:[0]               ; 取出缓冲区所保存的针对4字节成员数据的偏移
          mov ax,ds:[di+84+16]        ; low  16 bit
          mov dx,ds:[di+86+16]        ; high 16 bit

          mov di,ds:[2]               ; 取出缓冲区所保存的针对2字节成员数据的偏移
          mov cx,ds:[di+168+16]       ; 除数

          call divdw                  ; 该函数调用完毕后
                                      ; (ax) = low 16 bit ret
                                      ; (dx) = hig 16 bit ret
                                      ; (cx) = remainder

          call ddtoc
          
          pop cx
          ; }


          
          ; 4 byte 偏移量 + 4
          ; 2 byte 偏移量 + 2

          ; 行数加1
          ; 列数清0
          ;           

          loop l

          mov ax,4c00H
          int 21H



divdw: push bx
       push ax

       ; 先计算高 16 bit
       mov ax,dx
       mov dx,0000
       div cx
       mov bx,ax ; bx 存放着 H/N 的商
                 ; dx 存放着 H/N 的余

       ; 还原 ax 寄存器，ax寄存器存储着原来被除数的低16位
       pop ax

       ; 根据公式，dx此时为 H/N 的余，以下面的出发为基准，作为
       ; 高位存放在 dx 中，而弹出 ax 后其原始就作为被除数的低位
       ; 故可以直接使用
       div cx

       mov cx,dx
       mov dx,bx

       pop bx
       ret


; void dtoc(ax num, bx idx) {
    dtoc: push cx       
          push si       
          push ax       
                 
          mov dl,000AH                ; 初始化除数，指定除法为 16 位除法
          mov di,000EH                ; 写入内存段中的偏移量
             
   dsmon: div dl             
          mov cl,ah                   ; 获取余数
          mov ch,0
          jcxz d_ret               
          add cl,30H                  ; 计算余数所映射的 ASCII 码
          mov es:[bx+di],cl           ; 字符写入显存，从偶数开始，并在下一行机器码中开始递减偏移位以写入颜色属性至显存
          sub si,1
          mov byte ptr es:[bx+di],2   ; 颜色写入显存
          sub si,1
          mov ah,0
          jmp short dsmon

   d_ret: pop ax
          pop si
          pop cx
          ret
; }

; void ddtoc(ax low,dx high, bx idx) {
   ddtoc: push cx       
          push si       
          push ax       
          push dx       
          
          
          mov ax,000AH                ; 初始化除数，指定除法为 16 位除法
          mov di,0014H                ; 写入内存段中的偏移量
            
  ddsmon: div ax             
          mov cx,dx                   ; 获取余数
          jcxz d_ret               
          add cl,30H                  ; 计算余数所映射的 ASCII 码
          mov es:[bx+di],cl           ; 字符写入显存，从偶数开始，并在下一行机器码中开始递减偏移位以写入颜色属性至显存
          sub si,1
          mov byte ptr es:[bx+di],2   ; 颜色写入显存
          sub si,1
          mov dx,0
          jmp short ddsmon

  dd_ret: pop dx
          pop ax
          pop si
          pop cx
          ret
; }

codesg ends
;-----------------------------------------------------------------------------------------

end start