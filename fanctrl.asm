		pa_add equ 0FF20h				
		pb_add equ 0FF21h
		pc_add equ 0FF22h
		pcon_add equ 0ff23h
		int_times equ 0ah
		buf_add equ 79h
		gear equ 90h		;存储档位
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
		mov dptr,#pcon_add		;初始化8255	 
		mov a,#81h
		movx @dptr,a
		
		mov buf_add+2,#0ffh
		mov buf_add+3,#0ffh

		mov ie,#8ah				;允许定时器0和定时器1中断
		setb pt1				;设置定时器1为高优先级	
		mov 30h,#int_times		;设置中断次数	
		mov tmod,#11h	 
		mov th0,#0bh			;初始化定时器0	 
		mov tl0,#0cdh
		mov th1,#00h			;初始化定时器1
		mov tl1,#00h
		setb tr1				;启动定时器1				
		setb f0
		clr myflag					

;主程序		
here:	nop
		;call disp
		jnb p1.7,here			;检测是否打开开关
		jb myflag,hset
		jb p1.6,setTime			;检测是否设置定时
		clr myflag
hset:	mov a,p1
		anl a,00000011b			;取低两位作为档位
		mov gear,a
		mov dptr,#gear_led		;根据档位设置LED灯
		movc a,@a+dptr
		mov p3,a						
		call motor_driv		  				
		jmp here
;定时时间设置
setTime:setb myflag 
again:	  


	   	setb tr0				;打开定时器0
		ret
;中断服务子程序0，主要负责定时时间的修改		
isr_t0: jnb f0,ret0			;判断标志位
		mov th0,#0bh
		mov tl0,#0cdh
		mov a,30h
		dec a
		mov 30h,a
		jnz ret0
		
		mov 30h,#int_times		;重置中断次数
		mov a,r1
		mov b,#10
		div ab
		mov buf_add+0,b
		mov buf_add+1,a

check0:	cjne r1,#0,dec_f 		;到达定时时间
		clr f0					;设置标志位
		jmp ret0				
dec_f:	dec r1
ret0:	reti

;中断处理子程序1，主要负责实时显示7段数码管
disp:	mov th1,#00h	  ;重新装载定时器1
		mov tl1,#00h
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
		
		;mov dptr,#pb_add	
		;mov a,#0ffh
		;movx @dptr,a
		mov a,#0ffh			;消隐
		mov dptr,#pa_add
		movx @dptr,a

delay0:	mov r5,#0fh		 	;延时0
loop2:	nop
		djnz r5,loop2

		inc r0
		mov a,r3 
		jnb acc.5,ret1		;判断是否扫描到第5位
		rl a				;移位以扫描下一位
		mov r3,a
		jmp loop1
				
ret1:	reti
;电动机驱动程序
motor_driv:	mov dptr,#gear_value
			mov a,gear			;以gear作为偏移量取出档位
			movc a,@a+dptr
			mov r3,a			;延时2的时间
			mov dptr,#0ff80h
			mov a,#80h
			movx @dptr,a
			mov temp,#150		;延时1的时间
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
unlimited: db 0bfh					;不设置定时时，7段数码管显示的符号
gear_value: db 5,75,150,0  			;四个档位值
gear_led:	db 7fh,0bfh,0dfh,0efh	;四个档位对应的LED灯
		end	
			