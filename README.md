# meltdown-poc-for-windows
a simple meltdown poc for windows using setjmp and longjmp.

It should be noted that the so called “poc” is not strictly a real poc that can does abnomal things, and the leaking target is in user-mode address space. This is merely an evidence of the CPU’s out-of-order execution.  Note that out-of-order execution mechanism is not harmful in nature. It is the hardware realization of this mechanism that leads to the backdoor-like defect. However, the realization details are kept by Intel.  


email me if you have any questions: phylimo@163.com
