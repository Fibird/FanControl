;*************************************************
;Copyright(c) 2017 ����ũ�ֿƼ���ѧ��Ϣ����ѧԺ
;���ƣ�����ȿ��Ƴ���
;���ߣ�������
;*************************************************
;================���˿ڵ�ַ====================
		pa_add equ 0ff28h				
		pb_add equ 0ff29h
		pc_add equ 0ff2ah
		pcon_add equ 0ff2bh
		dac0832_add equ 0ff80h
;===============�����ڴ�ռ�===================
		int_times equ 04h	;�ж�int_times��Ϊ1��
		low_times equ 150	;���������
		count_value equ 60h	;����ֵ������
		count_value1 equ 61h	;����
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
;=============�ж�������=================
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
		mov count_value,#60		;����Ĭ�϶�ʱʱ��
		mov count_value1,#2	;----test
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
set_t: 	mov c,p1.5				;��ʱʱ������
		mov E,c
		cpl c
		mov NOE,c
		mov c,bitbuff0
		mov F,c
		cpl c
		mov NOF,c
		call bxrl
		jnc next_s
		inc count_value			;���ر仯����ֵ��1	
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
		dec count_value			;���ر仯����ֵ��1
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
		inc count_value1			;���ر仯����ֵ��1
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
		dec count_value1			;���ر仯����ֵ��1
		mov c,p1.2
		mov bitbuff3,c
goon:  	setb tr0				;�򿪶�ʱ��0				
		jmp get_g						
noset:	call reset
get_g:	mov a,p1				;��ȡ��λ
		anl a,#00000011b		;ȡ����λ��Ϊ��λ
		mov gear,a							
		call disp				;ɨ���߶�����ܺ�LED��		  				
		jmp here
;-------------------------------
;**************λ������*****************
;���ܣ�������λ�������
;���������E��F, NOE, NOF
;���������CY
;*****************************************
bxrl:	mov c,F
		anl c,NOE
		mov tempbit,c
		mov c,E
		anl c,NOF
		orl c,tempbit
		ret

;**************��ʱ��0���жϷ����ӳ���*****************
;���ܣ�ÿ��1s�޸ļ���ֵ
;���������count_value
;���������buf_add+0�� buf_add+1
;******************************************************		
isr_t0: 
;------------�����ֳ�--------------
		push acc
		push psw
;----------------------------------
		mov r1,count_value		;���»������ڵ�ֵ
		mov a,r1
		mov b,#10
		div ab
		mov buf_add+0,b
		mov buf_add+1,a

		mov r7,count_value1		;���»������ڵ�ֵ
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
		mov count_value,r1
		mov count_value1,r7
;------------�ָ��ֳ�--------------
ret0:	pop psw
		pop acc
		reti
;********************�߶������ɨ�����**********************
;���ܣ���Ҫ����ɨ���߶�����ܵı�֤��ʱʱ���������ʾ������Ҳ
;����ɨ��LED�ƣ���֤��λ��������ʾ
;���������buf_add
;�����������
;************************************************************
disp:	push psw
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
		
ret1:	pop psw
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
			mov a,count_value
			add a,count_value1
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
;�����������
;�����������
;**********************************************
reset:		clr tr0
			mov count_value1,#2
			mov count_value,#60
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