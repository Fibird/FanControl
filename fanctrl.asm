		pa_add equ 0FF20h				
		pb_add equ 0FF21h
		pc_add equ 0FF22h
		pcon_add equ 0ff23h
		int_times equ 0ah
		buf_add equ 79h
		gear equ 90h		;�洢��λ
		temp equ 91h
		myflag equ 2fh  
		
		org 0000h
		ljmp main

		org 000bh
		ljmp isr_t0

		org 001bh
		ljmp disp
		
		org 1000h
main:	mov r0,#0
		mov dptr,#pcon_add		;��ʼ��8255	 
		mov a,#81h
		movx @dptr,a
		
		mov buf_add+2,#0ffh
		mov buf_add+3,#0ffh

		mov ie,#8ah				;����ʱ��0�Ͷ�ʱ��1�ж�
		setb pt1				;���ö�ʱ��1Ϊ�����ȼ�	
		mov 30h,#int_times		;�����жϴ���	
		mov tmod,#11h	 
		mov th0,#0bh			;��ʼ����ʱ��0	 
		mov tl0,#0cdh
		mov th1,#00h			;��ʼ����ʱ��1
		mov tl1,#00h
		setb tr1				;������ʱ��1				
		setb f0
		clr myflag					

;������		
here:	nop
		;call disp
		jnb p1.7,here			;����Ƿ�򿪿���
		jb myflag,hset
		jb p1.6,setTime			;����Ƿ����ö�ʱ
		clr myflag
hset:	mov a,p1
		anl a,00000011b			;ȡ����λ��Ϊ��λ
		mov gear,a
		mov dptr,#gear_led		;���ݵ�λ����LED��
		movc a,@a+dptr
		mov p3,a						
		call motor_driv		  				
		jmp here
;��ʱʱ������
setTime:setb myflag 
again:	  


	   	setb tr0				;�򿪶�ʱ��0
		ret
;�жϷ����ӳ���0����Ҫ����ʱʱ����޸�		
isr_t0: jnb f0,ret0			;�жϱ�־λ
		mov th0,#0bh
		mov tl0,#0cdh
		mov a,30h
		dec a
		mov 30h,a
		jnz ret0
		
		mov 30h,#int_times		;�����жϴ���
		mov a,r1
		mov b,#10
		div ab
		mov buf_add+0,b
		mov buf_add+1,a

check0:	cjne r1,#0,dec_f 		;���ﶨʱʱ��
		clr f0					;���ñ�־λ
		jmp ret0				
dec_f:	dec r1
ret0:	reti

;�жϴ����ӳ���1����Ҫ����ʵʱ��ʾ7�������
disp:	mov th1,#00h	  ;����װ�ض�ʱ��1
		mov tl1,#00h
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
		
		;mov dptr,#pb_add	
		;mov a,#0ffh
		;movx @dptr,a
		mov a,#0ffh			;����
		mov dptr,#pa_add
		movx @dptr,a

delay0:	mov r5,#0fh		 	;��ʱ0
loop2:	nop
		djnz r5,loop2

		inc r0
		mov a,r3 
		jnb acc.5,ret1		;�ж��Ƿ�ɨ�赽��5λ
		rl a				;��λ��ɨ����һλ
		mov r3,a
		jmp loop1
				
ret1:	reti
;�綯����������
motor_driv:	mov dptr,#gear_value
			mov a,gear			;��gear��Ϊƫ����ȡ����λ
			movc a,@a+dptr
			mov r3,a			;��ʱ2��ʱ��
			mov dptr,#0ff80h
			mov a,#80h
			movx @dptr,a
			mov temp,#150		;��ʱ1��ʱ��
delay1:		nop
			nop
			nop
			nop
			djnz temp,delay1
			mov a,#0ffh
			movx @dptr,a
delay2:		nop
			nop
			nop
			nop
			djnz r3,delay2
			ret

disdata: db 0c0h,0f9h,0a4h,0b0h,99h,92h,82h,0f8h,80h,90h,0c0h
unlimited: db 0bfh					;�����ö�ʱʱ��7���������ʾ�ķ���
gear_value: db 5,75,150,0  			;�ĸ���λֵ
gear_led:	db 7fh,0bfh,0dfh,0efh	;�ĸ���λ��Ӧ��LED��
		end	
			