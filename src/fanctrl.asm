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
;================���˿ڵ�ַ====================
		pa_add equ 0ff28h				
		pb_add equ 0ff29h
		pc_add equ 0ff2ah
		pcon_add equ 0ff2bh
		dac0832_add equ 0ff80h
;===============����ֵ===================
		int_times equ 0dh	;�ж�int_times��Ϊ1��
		low_times equ 150	;���������
		default_min equ 5	;Ĭ�Ϸ���
		default_sec equ 60	;Ĭ������
;===============�����ڴ�ռ�===================
		sec_value equ 60h	;��ֵ������
		min_value equ 61h;��ֵ������
		buf_add equ 79h		;����ܻ�������ַ
		gear equ 50h		;�洢��λ
		temp equ 51h		;��ʱ�洢��
		bitbuff0 bit 20h.0	;λ������
		bitbuff1 bit 20h.1
		bitbuff2 bit 20h.2
		bitbuff3 bit 20h.3 
		E bit 20h.4			;������Ĳ���
		F bit 20h.5
		NOE bit 20h.6
		NOF bit 20h.7
		tempbit bit 21h.0
;==============================================
		org 0000h
		ljmp main
;=============�ж�������=======================
		org 000bh		;��ʱ��0�ж�
		ljmp isr_t0
		org 001bh		;��ʱ��1�ж�
		ljmp motor_driv
;========================================

;***************������*********************
;��ɸ��ֶ�ʱ���ĳ�ʼ�����ã��жϼ�������
;�������ã�����������Ƶ������Լ�8255�ĳ�
;ʼ�����á�
;******************************************		
		org 0030h
;-----------------��ʼ������----------------
main:	mov sp,#30h				;����ջ��
		mov r0,#0
		mov dptr,#pcon_add		;��ʼ��8255	 
		mov a,#80h
		movx @dptr,a
		mov p1,#0ffh			;��p1��Ϊ����
		mov buf_add+4,#0ah
		mov buf_add+5,#0ah
	
		mov 30h,#int_times		;�����жϴ���
		mov temp+1,#low_times	;�͵�ƽ����	
		mov tmod,#21h	 
		mov th0,#0bh			;��ʼ����ʱ��0	 
		mov tl0,#0cdh
		mov th1,#0fh			;��ʼ����ʱ��1
		mov tl1,#0fh
		mov ie,#8ah				;����ʱ��0�Ͷ�ʱ��1�ж�
		setb pt0				;���ö�ʱ��1Ϊ�����ȼ�
		mov sec_value,#default_sec	;����Ĭ�ϵķ���
		mov min_value,#default_min	;����Ĭ�ϵ�����
		;setb tr0				;�򿪶�ʱ��0
		setb tr1				;������ʱ��1				
		clr f0					;���ػ�״̬��־��Ĭ�Ϲػ�
		mov gear,#4h			;�ر�LED��
		mov c,p1.5				;�����ʼ����״̬
		mov bitbuff0,c			
		mov c,p1.4				;�����ʼ����״̬
		mov bitbuff1,c
		mov c,p1.3				;�����ʼ����״̬
		mov bitbuff2,c			
		mov c,p1.2				;�����ʼ����״̬
		mov bitbuff3,c					
;-----------------------------
;ѭ����⿪�أ���ɨ���߶������
here:	nop
		clr f0	
		jnb p1.7,here			;����Ƿ�򿪿���
		setb f0
		jnb p1.6,noset			;����Ƿ����ö�ʱ
		call disp
		call set_t				
		jmp get_g						
noset:	call reset
get_g:	mov a,p1				;��ȡ��λ
		anl a,#00000011b		;ȡ����λ��Ϊ��λ
		mov gear,a							
		call disp				;ɨ���߶�����ܺ�LED��		  				
		jmp here
;**************ʱ����ڳ���***************
;���ܣ���ȡ���ص���ʱ��
;�����������
;�����������
;*****************************************
set_t: 	
		push psw
		mov c,p1.5				;��ʱʱ������
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
inc0:	inc sec_value			;���ر仯����ֵ��1	
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
dec0:	dec sec_value			;���ر仯����ֵ��1
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
inc1:	inc min_value			;���ر仯����ֵ��1
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
dec1:	dec min_value			;���ر仯����ֵ��1
		mov c,p1.2
		mov bitbuff3,c
goon:  	setb tr0				;�򿪶�ʱ��0
		pop psw
		ret

;**************λ������*****************
;���ܣ�������λ�������
;���������E��F, NOE, NOF
;���������CY
;*****************************************
bxrl:	
		mov c,F
		anl c,NOE
		mov tempbit,c
		mov c,E
		anl c,NOF
		orl c,tempbit
		ret

;**************��ʱ��0���жϷ����ӳ���*****************
;���ܣ�ÿ��1s�޸ļ���ֵ
;���������min_value, sec_value
;���������buf_add+0�� buf_add+1, buf_add+2, buf_add+3
;******************************************************		
isr_t0: 
;------------�����ֳ�--------------
		push acc
		push psw
;----------------------------------
		mov r1,sec_value		;���»������ڵ�ֵ
		mov a,r1
		mov b,#10
		div ab
		mov buf_add+0,b
		mov buf_add+1,a

		mov r7,min_value		;���»������ڵ�ֵ
		mov a,r7
		mov b,#10
		div ab
		mov buf_add+2,b
		mov buf_add+3,a

		jnb f0,ret0				;�жϱ�־λ
		mov th0,#0bh
		mov tl0,#0cdh		
		mov r6,30h
		dec r6
		mov 30h,r6
		cjne r6,#0,ret0			;�жϴﵽint_times�βŸ���ֵ��һ

next1:	mov 30h,#int_times		;�����жϴ���

check0:	cjne r1,#0,dec_s 		;���ﶨʱʱ��
		
check1:	cjne r7,#0,dec_m
		jmp ret0
dec_m:	dec r7
		mov r1,#60				
dec_s:	dec r1
		mov sec_value,r1
		mov min_value,r7
;------------�ָ��ֳ�--------------
ret0:	pop psw
		pop acc
;----------------------------------
		reti

;********************�߶������ɨ�����**********************
;���ܣ���Ҫ����ɨ���߶�����ܵı�֤��ʱʱ���������ʾ������Ҳ
;����ɨ��LED�ƣ���֤��λ��������ʾ
;���������buf_add
;�����������
;************************************************************

disp:
;-----------�����ֳ�---------------	
		push psw
;----------------------------------
		mov r3,#0feh	  ;���λ��
		mov r0,#buf_add	  ;��Ŷ���ĵ�ַ
loop1:	mov a,@r0	
		mov dptr,#disdata
		movc a,@a+dptr		 
		mov dptr,#pb_add		
		movx @dptr,a		;���Ͷ���
		mov dptr,#pa_add	 
		mov a,r3			  
		movx @dptr,a		;����λ�� 

		mov a,#0ffh			;����
		mov dptr,#pa_add
		movx @dptr,a

		inc r0
		mov a,r3 
		jnb acc.5,ret1		;�ж��Ƿ�ɨ�赽��5λ
		rl a				;��λ��ɨ����һλ
		mov r3,a
		mov a,gear
		mov dptr,#gear_led		;���ݵ�λ����LED��
		movc a,@a+dptr
		mov dptr,#pc_add
		movx @dptr,a
		jmp loop1
;--------�ָ��ֳ�---------		
ret1:	pop psw
;-------------------------
		ret

;***********��ʱ��1�жϷ����ӳ���**************
;���ܣ���Ҫ���������綯��
;���������gear
;�����������
;**********************************************
motor_driv:	
;------------�����ֳ�--------------
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
;------------�͵�ƽ����--------------			
movit:		mov a,temp+1
			jz send_h			
			mov dptr,#gear_value
			mov a,gear			;��gear��Ϊƫ����ȡ����λ
			movc a,@a+dptr
			mov r4,a			;�ߵ�ƽ�Ĵ���
			mov temp,r4

			mov dptr,#dac0832_add		;���͵͵�ƽ
			mov a,#80h
			movx @dptr,a
			
			dec temp+1
			jmp ret2
;------------�ߵ�ƽ����--------------
send_h:		mov dptr,#gear_value
			mov a,gear			;��gear��Ϊƫ����ȡ���µ�λ
			movc a,@a+dptr
							
			clr c				 ;����У׼�ߵ�ƽ����
			subb a,temp
			add a,r4

			mov dptr,#dac0832_add		;���͸ߵ�ƽ
			mov a,#0ffh
			movx @dptr,a

			dec r4
			cjne r4,#0,ret2
			mov temp+1,#low_times
;------------ֹͣ����--------------
mstop:		mov dptr,#dac0832_add
			mov a,#0h
			movx @dptr,a
;------------�ָ��ֳ�--------------
ret2:		pop psw
			pop dph
			pop dpl
			pop acc
			reti

;***************�����ӳ���*********************
;���ܣ������ʾ���������رն�ʱ��0
;���������buf_add
;���������buf_add
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

;====================������===========================
disdata: db 0c0h,0f9h,0a4h,0b0h,99h,92h,82h,0f8h,80h,90h,0ffh	;�����������
reset_sym: db 0bfh					;�����ö�ʱʱ��7���������ʾ�ķ���
gear_value: db 5,75,150,0  			;�ĸ���λֵ
gear_led: db 7fh,0bfh,0dfh,0efh,0ffh	;�ĸ���λ��Ӧ��LED��
;=====================================================
		end	