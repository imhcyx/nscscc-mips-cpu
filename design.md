# CPU设计说明

## CPU核心设计

CPU采用静态单发射流水线结构，流水线分为取指（IF）、译码（ID）、执行（EX）、写回（WB）四级，其中取指级内部拆分为两级：取指请求（IF_req）和取指等待（IF_wait），故总体上为五级流水。

### 各级的公共设计

流水线各级有一部分共通的设计，在此统一说明。

** 握手信号 **

流水线上下级之间通过一组valid/ready信号握手，以传递有效信号和实现阻塞控制。

```
|----|         |----|         |----|         |----|
|    |--valid->|    |--valid->|    |--valid->|    |
| IF |         | ID |         | EX |         | WB |
|    |<-ready--|    |<-ready--|    |<-ready--|    |
|----|         |----|         |----|         |----|
```

valid表示来自上一级的指令是有效指令，ready表示下一级可以接收指令。当一对valid/ready信号同时有效时，有效指令从上一级传递给下一级。

需要注意，每相邻两级的级间寄存器存在于上级的模块中，如IF/ID寄存器组存在于IF中，因此逻辑上“位于”ID内的指令实际上存储于IF的输出寄存器中。从IF到ID传递，其实是IF写IF输出寄存器的过程。

在各级模块的接口中，valid_o和ready_i用于和下级握手，valid_i和done_o用于和上级握手（由done_o生成到上一级的ready信号，下述）。

** 前递处理 **

前递的数据路径如下（注意级间寄存器位于上级的模块中，这里为了方便分离了出来）：

```
|----|    |-----|    |----|    |-----|    |----|
|    |    |     |    |    |    |     |    |    |
|    |    |     |    |    |    |     |    |    |
| ID |--->|ID/EX|----| EX |--->|EX/WB|----| WB |--->(reg_file)
|    |    |     |    |    | |  |     |    |    | |
|    |    |     |    |    | |  |     |    |    | |
|----|    |-----|    |----| |  |-----|    |----| |
   |                        |                    |
|-----------|               |                    |
|  Forward  |----------------                    |
|  Process  |-------------------------------------
|-----------|
```

TODO

** 例外处理 **

TODO

** 级内共通设计 **

ID、EX、WB内部均有名为valid和done_o的信号（IF内也有类似信号，但由于IF内为两级流水，信号命名有所区别）。这两个信号的作用如下：

|名称   |描述                                 |
|------|-------------------------------------|
|valid |指示当前指令可以进行处理                |
|done_o|当前指令处理完成，即将在下一周期传递给下级|

不同于valid_i，valid既要求当前指令是上级传递而来的有效指令（valid_i），又要求指令未因发生例外而取消执行。取消包含两种情况，一是当前指令在之前的某级发生过例外（exc_i），另一种是因后面某级的指令发生例外而清空流水线（cancel_i）。

对于某些关键的控制信号（如寄存器堆写使能），这些信号对每条指令只能有效一拍，因此需要由valid和done_o同时控制，在编写RTL代码时需要注意这一点。

** 由done_o生成到上级的ready信号 **

为减少ready链带来的长延迟，各级由输出ready_o变更为输出done_o，并由外层模块生成真正的ready信号。

ready信号有效的情形有两种：下一级的ready信号有效，或者该级的指令为无效指令。对应的逻辑如下：

```
assign wb_ex_ready = wb_done || !ex_wb_valid;
assign ex_id_ready = ex_done && wb_ex_ready || !id_ex_valid;
assign id_if_ready = id_done && ex_id_ready || !if_id_valid;
```

优化时序后的逻辑如下：

```
assign wb_ex_ready = wb_done || !ex_wb_valid;
assign ex_id_ready = ex_done && wb_done || ex_done && !ex_wb_valid || !id_ex_valid;
assign id_if_ready = id_done && ex_done && wb_done || id_done && ex_done && !ex_wb_valid || id_done && !id_ex_valid || !if_id_valid;
```

### PC寄存器

### 取指（IF）

TODO

### 译码（ID）

TODO

### 执行（EX）

TODO

### 写回（WB）

TODO