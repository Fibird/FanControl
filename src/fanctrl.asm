;***********************************************************************
; Author: Chaoyang Liu
; E-main: chaoyanglius@outlook.com
;
; Software License Agreement (GPL License)
; A program contolling electric fan
; Copyright (c) 2016, Chaoyang Liu
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;************************************************************************/
;================各端口地址====================
		pa_add equ 0ff28h				
		pb_add equ 0ff29h
		pc_add equ 0ff2ah
		pcon_add equ 0ff2bh
		dac0832_add equ 0ff80h
;===============常用值===================
		int_times equ 0dh	;中断int_times次为1秒
		low_times equ 150	;低脉冲次数
		default_min equ 5	;默认分钟
		default_sec equ 60	;默认秒钟
;===============常用内存空间===================
		sec_value equ 60h	;秒值缓冲区
		min_value equ 61h;分值缓冲区
		buf_add equ 79h		;数码管缓冲区首址
		gear equ 50h		;存储档位
		temp equ 51h		;临时存储区
		bitbuff0 bit 20h.0	;位缓冲区
		bitbuff1 bit 20h.1
		bitbuff2 bit 20h.2
		bitbuff3 bit 20h.3 
		E bit 20h.4			;异或程序的参数
		F bit 20h.5
		NOE bit 20h.6
		NOF bit 20h.7
		tempbit bit 21h.0
;==============================================
		org 0000h
		ljmp main
;=============中断向量表=======================
		org 000bh		;定时器0中断
		ljmp isr_t0
		org 001bh		;定时器1中断
		ljmp motor_driv
;========================================

;***************主程序*********************
;完成各种定时器的初始化设置，中断及其优先
;级的设置，输入输出控制的设置以及8255的初
;始化设置。
;******************************************		
		org 0030h
;-----------------初始化设置----------------
main:	mov sp,#30h				;设置栈顶
		mov r0,#0
		mov dptr,#pcon_add		;初始化8255	 
		mov a,#80h
		movx @dptr,a
		mov p1,#0ffh			;将p1作为输入
		mov buf_add+4,#0ah
		mov buf_add+5,#0ah
	
		mov 30h,#int_times		;设置中断次数
		mov temp+1,#low_times	;低电平次数	
		mov tmod,#21h	 
		mov th0,#0bh			;初始化定时器0	 
		mov tl0,#0cdh
		mov th1,#0fh			;初始化定时器1
		mov tl1,#0fh
		mov ie,#8ah				;允许定时器0和定时器1中断
		setb pt0				;设置定时器1为高优先级
		mov sec_value,#default_sec	;设置默认的分钟
		mov min_value,#default_min	;设置默认的秒钟
		;setb tr0				;打开定时器0
		setb tr1				;启动定时器1				
		clr f0					;开关机状态标志，默认关机
		mov gear,#4h			;关闭LED灯
		mov c,p1.5				;保存初始开关状态
		mov bitbuff0,c			
		mov c,p1.4				;保存初始开关状态
		mov bitbuff1,c
		mov c,p1.3				;保存初始开关状态
		mov bitbuff2,c			
		mov c,p1.2				;保存初始开关状态
		mov bitbuff3,c					
;-----------------------------
;循环检测开关，并扫描七段数码管
here:	nop
		clr f0	
		jnb p1.7,here			;检测是否打开开关
		setb f0
		jnb p1.6,noset			;检测是否设置定时
		call disp
		call set_t				
		jmp get_g						
noset:	call reset
get_g:	mov a,p1				;读取档位
		anl a,#00000011b		;取低两位作为档位
		mov gear,a							
		call disp				;扫描七段数码管和LED灯		  				
		jmp here
;**************时间调节程序***************
;功能：读取开关调节时间
;输入参数：无
;输出参数：无
;*****************************************
set_t: 	
		push psw
		mov c,p1.5				;定时时间设置
		mov E,c
		cpl c
		mov NOE,c
		mov c,bitbuff0
		mov F,c
		cpl c
		mov NOF,c
		call bxrl
		jnc next_s
		mov a,sec_value
		cjne a,#60,inc0
		mov sec_value,#0
		dec sec_value
inc0:	inc sec_value			;开关变化计数值加1	
		mov c,p1.5
		mov bitbuff0,c
next_s:	mov c,p1.4
		mov E,c
		cpl c
		mov NOE,c
		mov c,bitbuff1
		mov F,c
		cpl c
		mov NOF,c
		call bxrl
 		jnc min
		mov a,sec_value
		cjne a,#0,dec0
		mov sec_value,#60
		inc sec_value
dec0:	dec sec_value			;开关变化计数值减1
		mov c,p1.4
		mov bitbuff1,c
		;call disp
min:	mov c,p1.3
		mov E,c
		cpl c
		mov NOE,c
		mov c,bitbuff2
		mov F,c
		cpl c
		mov NOF,c
		call bxrl
 		jnc next_m
		mov a,min_value
		cjne a,#60,inc1
		mov min_value,#0
		dec min_value
inc1:	inc min_value			;开关变化计数值减1
		mov c,p1.3
		mov bitbuff2,c
next_m:	mov c,p1.2
		mov E,c
		cpl c
		mov NOE,c
		mov c,bitbuff3
		mov F,c
		cpl c
		mov NOF,c
		call bxrl
 		jnc goon
		mov a,min_value
		cjne a,#0,dec1
		mov min_value,#60
		inc min_value
dec1:	dec min_value			;开关变化计数值减1
		mov c,p1.2
		mov bitbuff3,c
goon:  	setb tr0				;打开定时器0
		pop psw
		ret

;**************位异或程序*****************
;功能：对两个位进行异或
;输入参数：E，F, NOE, NOF
;输出参数：CY
;*****************************************
bxrl:	
		mov c,F
		anl c,NOE
		mov tempbit,c
		mov c,E
		anl c,NOF
		orl c,tempbit
		ret

;**************定时器0的中断服务子程序*****************
;功能：每隔1s修改计数值
;输入参数：min_value, sec_value
;输出参数：buf_add+0， buf_add+1, buf_add+2, buf_add+3
;******************************************************		
isr_t0: 
;------------保护现场--------------
		push acc
		push psw
;----------------------------------
		mov r1,sec_value		;更新缓冲区内的值
		mov a,r1
		mov b,#10
		div ab
		mov buf_add+0,b
		mov buf_add+1,a

		mov r7,min_value		;更新缓冲区内的值
		mov a,r7
		mov b,#10
		div ab
		mov buf_add+2,b
		mov buf_add+3,a

		jnb f0,ret0				;判断标志位
		mov th0,#0bh
		mov tl0,#0cdh		
		mov r6,30h
		dec r6
		mov 30h,r6
		cjne r6,#0,ret0			;中断达到int_times次才给秒值减一

next1:	mov 30h,#int_times		;重置中断次数

check0:	cjne r1,#0,dec_s 		;到达定时时间
		
check1:	cjne r7,#0,dec_m
		jmp ret0
dec_m:	dec r7
		mov r1,#60				
dec_s:	dec r1
		mov sec_value,r1
		mov min_value,r7
;------------恢复现场--------------
ret0:	pop psw
		pop acc
;----------------------------------
		reti

;********************七段数码管扫描程序**********************
;功能：主要负责扫描七段数码管的保证计时时间的正常显示，另外也
;负责扫描LED灯，保证档位的正常显示
;输入参数：buf_add
;输出参数：无
;************************************************************

disp:
;-----------保护现场---------------	
		push psw
;----------------------------------
		mov r3,#0feh	  ;存放位码
		mov r0,#buf_add	  ;存放段码的地址
loop1:	mov a,@r0	
		mov dptr,#disdata
		movc a,@a+dptr		 
		mov dptr,#pb_add		
		movx @dptr,a		;发送段码
		mov dptr,#pa_add	 
		mov a,r3			  
		movx @dptr,a		;发送位码 

		mov a,#0ffh			;消隐
		mov dptr,#pa_add
		movx @dptr,a

		inc r0
		mov a,r3 
		jnb acc.5,ret1		;判断是否扫描到第5位
		rl a				;移位以扫描下一位
		mov r3,a
		mov a,gear
		mov dptr,#gear_led		;根据档位设置LED灯
		movc a,@a+dptr
		mov dptr,#pc_add
		movx @dptr,a
		jmp loop1
;--------恢复现场---------		
ret1:	pop psw
;-------------------------
		ret

;***********定时器1中断服务子程序**************
;功能：主要负责驱动电动机
;输入参数：gear
;输出参数：无
;**********************************************
motor_driv:	
;------------保护现场--------------
			push acc
			push dpl
			push dph
			push psw
;----------------------------------
			jnb f0,mstop
			jnb p1.6,movit
			mov a,sec_value
			add a,min_value
			jz mstop
;------------低电平脉冲--------------			
movit:		mov a,temp+1
			jz send_h			
			mov dptr,#gear_value
			mov a,gear			;以gear作为偏移量取出档位
			movc a,@a+dptr
			mov r4,a			;高电平的次数
			mov temp,r4

			mov dptr,#dac0832_add		;发送低电平
			mov a,#80h
			movx @dptr,a
			
			dec temp+1
			jmp ret2
;------------高电平脉冲--------------
send_h:		mov dptr,#gear_value
			mov a,gear			;以gear作为偏移量取出新档位
			movc a,@a+dptr
							
			clr c				 ;更新校准高电平次数
			subb a,temp
			add a,r4

			mov dptr,#dac0832_add		;发送高电平
			mov a,#0ffh
			movx @dptr,a

			dec r4
			cjne r4,#0,ret2
			mov temp+1,#low_times
;------------停止脉冲--------------
mstop:		mov dptr,#dac0832_add
			mov a,#0h
			movx @dptr,a
;------------恢复现场--------------
ret2:		pop psw
			pop dph
			pop dpl
			pop acc
			reti

;***************重置子程序*********************
;功能：清除显示缓冲区，关闭定时器0
;输入参数：buf_add
;输出参数：buf_add
;**********************************************
reset:		
			clr tr0
			mov min_value,#default_min
			mov sec_value,#default_sec
			mov buf_add,#11
			mov buf_add+1,#11
			mov buf_add+2,#11
			mov buf_add+3,#11
			ret 

;====================数据区===========================
disdata: db 0c0h,0f9h,0a4h,0b0h,99h,92h,82h,0f8h,80h,90h,0ffh	;数码管字形码
reset_sym: db 0bfh					;不设置定时时，7段数码管显示的符号
gear_value: db 5,75,150,0  			;四个档位值
gear_led: db 7fh,0bfh,0dfh,0efh,0ffh	;四个档位对应的LED灯
;=====================================================
		end	