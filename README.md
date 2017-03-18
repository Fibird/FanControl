# 概述

本程序使用80C51单片机汇编程序编写，开发环境为keil uVision4，80C51单片机型号为Atmel 89S52。该程序的主要功能为控制电风扇转动，可以设置定时，调节风扇转速。

# 硬件组成

- Atmel 89S52
- 并行I/O接口芯片8255
- 数模转换芯片DAC0832
- 直流电动机
- 4位七段数码管
- 4个LED灯

# 使用方法

- 可用K8开关控制转动和停止。
- K1、K2两个开关调节档位，因此，共有4个档位，每个档位对应一个速度，档位越高速度越快。
- LED灯第一位亮表示为1档，第二位亮表示2档，第三位亮表示3档，第四位亮表示4档。
- K7开关设置是否定时，当未设置定时时，即拨到低电平，4位7段数码管显示4个横杠；当设置定时时，即拨到高电平，4位7段数码管就显示定时时间，默认为5分60秒。
- 在设置定时的情况下，K3、K4、K5、K6开关可以调整定时时间，K3、K4调整分钟，前者减少，后者增加；K5、K6调整秒钟，同样前者减少，后者增加。
- 当到达定时时间之后，直流电动机自动停下来；如果未设置定时，则只要总开关不关，电动机便一直转动。
- 七段数码管高两位显示剩余分钟数，低两位显示剩余秒数。

# 设计说明

如果采用直接向直流电动机发送持续脉冲的方式，电动机会出现明显的停顿现象。这是由于直流电动机驱动程序是在主程序中调用的，而存在两个中断：定时器0中断和定时器1中断，不断地打断主程序，这就造成了无法持续地为直流电动机发送方波，于是直流电动机便出现了明显的停顿。

为了解决这个问题，我将直流电动机驱动部分放到中断中调用，而将七段数码管扫描程序放到主程序中调用。当然，此处并不是直接在中断中持续地向直流电动机发送方波，而是采用每次中断发送一个高电平或这低电平，由于每次中断间隔非常之短，所以多次中断的高电平后者低电平就可以看成连续的方波。下面是该中断服务程序的流程图：

![motor-drive](http://p1.bpimg.com/567571/523c7ec282300b36.jpg)

# 电路图

下面是控制器的电路图：

[详细电路图](https://github.com/Sunlcy/FanControl/blob/master/circuit/circuit.PDF)
