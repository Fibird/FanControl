		pa_add equ 0ff28h				
		pb_add equ 0ff29h
		pc_add equ 0ff2ah
		pcon_add equ 0ff2bh
		dac0832_add equ 0ff80h
		int_times equ 0ah
		low_times equ 150
		buf_add equ 79h
		gear equ 50h		;�洢��λ
		temp equ 51h		;��ʱ�洢��

		haveCount bit 2dh  
		
		org 0000h
		ljmp main

		org 000bh
		ljmp isr_t0

		org 001bh
		ljmp motor_driv
;***************������*********************
;��ɸ��ֶ�ʱ���ĳ�ʼ�����ã��жϼ�������
;�������ã�����������Ƶ������Լ�8255�ĳ�
;ʼ�����á�
;******************************************		
		org 0030h
;��ʼ������
main:	mov sp,#30h				;����ջ��
		mov r0,#0
		mov dptr,#pcon_add		;��ʼ��8255	 
		mov a,#80h
		movx @dptr,a
		mov p1,#0ffh			;��p1��Ϊ����
		mov buf_add+4,#0ah
		mov buf_add+5,#0ah
	
		mov 30h,#int_times		;�����жϴ���
		mov temp+1,#low_times			;�͵�ƽ����	
		mov tmod,#21h	 
		mov th0,#0bh			;��ʼ����ʱ��0	 
		mov tl0,#0cdh
		mov th1,#0fh			;��ʼ����ʱ��1
		mov tl1,#0fh
		mov ie,#8ah				;����ʱ��0�Ͷ�ʱ��1�ж�
		setb pt0				;���ö�ʱ��1Ϊ�����ȼ�
		mov r1,#60		;test
		;setb tr0		;test
		setb tr1				;������ʱ��1				
		clr f0					;���ػ�״̬��־��Ĭ�Ϲػ�
		clr haveCount					
;-----------------------------
;ѭ����⿪�أ���ɨ���߶������
here:	nop
		clr f0	
		jnb p1.7,here			;����Ƿ�򿪿���
		setb f0
		jnb p1.6,hset			;����Ƿ����ö�ʱ
		call setTime
		jmp get_g						
hset:	call reset
get_g:	mov a,p1				;��ȡ��λ
		anl a,#00000011b		;ȡ����λ��Ϊ��λ
		mov gear,a							
		call disp		  				
		jmp here
;-------------------------------
;��ʱʱ������
setTime: 
	 
	   	setb tr0			;�򿪶�ʱ��0				
		ret
;***********��ʱ����*********************
;�жϷ����ӳ���0����Ҫ����ʱʱ����޸�
;
;****************************************		
isr_t0: push acc
		jnb f0,ret0			;�жϱ�־λ
		mov th0,#0bh
		mov tl0,#0cdh		
		mov r6,30h
		dec r6
		mov 30h,r6
		cjne r6,#0,ret0

next1:	mov 30h,#int_times		;�����жϴ���
		mov a,r1
		mov b,#10
		div ab
		mov buf_add+0,b
		mov buf_add+1,a
check0:	cjne r1,#0,dec_f 		;���ﶨʱʱ��
		clr f0					;���ñ�־λ
		clr tr0
		jmp ret0				
dec_f:	dec r1
ret0:	pop acc
		reti
;**************�߶������ɨ�����****************
;��Ҫ����ɨ���߶�����ܵı�֤��ʱʱ���������ʾ��
;����Ҳ����ɨ��LED�ƣ���֤��λ��������ʾ
;************************************************
disp:	mov r3,#0feh	  ;���λ��
		mov r0,#buf_add	  ;��Ŷ���ĵ�ַ
loop1:	mov a,@r0	
		mov dptr,#disdata
		movc a,@a+dptr		 
		mov dptr,#pb_add		
		movx @dptr,a		;���Ͷ���
		mov dptr,#pa_add	 
		mov a,r3			  
		movx @dptr,a		;����λ�� 

delay0:	mov r5,#10h		 	;��ʱ0
loop2:	nop
		djnz r5,loop2
		
		mov dptr,#pb_add	
		mov a,#0ffh
		movx @dptr,a
		mov a,#00h			;����
		mov dptr,#pa_add
		movx @dptr,a

		mov r5,#10h		 	;��ʱ0
loop3:	nop
		djnz r5,loop3

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
		
ret1:	ret
;***********�綯����������**************
;�жϷ����ӳ���2����Ҫ���������綯��
;
;***************************************
motor_driv:	
;------------�����ֳ�--------------
			push acc
			push dpl
			push dph
			push psw
			jnb f0,mstop
			jnb p1.6,movit
			mov a,r1
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
;------------�жϷ���--------------
ret2:		pop psw
			pop dph
			pop dpl
			pop acc
			reti
;����ʱʱ����λ����ȫ����Ϊ���
reset:		clr tr0
			mov buf_add,#11
			mov buf_add+1,#11
			mov buf_add+2,#11
			mov buf_add+3,#11
			ret 

disdata: db 0c0h,0f9h,0a4h,0b0h,99h,92h,82h,0f8h,80h,90h,0ffh	;�����������
reset_sym: db 0bfh					;�����ö�ʱʱ��7���������ʾ�ķ���
gear_value: db 5,75,150,0  			;�ĸ���λֵ
gear_led: db 7fh,0bfh,0dfh,0efh	;�ĸ���λ��Ӧ��LED��
		end	