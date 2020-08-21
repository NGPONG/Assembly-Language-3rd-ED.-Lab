assume cs:codesg

codesg segment

start: mov ax,1000h
       mov bh,1
       div bh

       mov ax,4c00H
       int 21H

codesg ends
end start