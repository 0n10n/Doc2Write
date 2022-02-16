# Windows 命令行注入

继续整理一下Windows命令注入的问题。

## 可以注入的位置？ 

要利用Windows命令注入，首先要确定可以利用的是命令的哪个部分，因为不同位置的利用和绕过方式会有差异。当然要熟练利用Windows命令注入，重点还是要熟悉Batch语法和各Windows命令。

最简单说，Windows命令分为`命令本身`和`参数`两部分。比如 `dir C:\Windows`，就是`dir` 部分属于命令本身，`C:\Windows`属于参数。当然严格说来还有`选项`的部分，比如 `dir /OD C:\Windows ` 里的 `/OD`，严格说来是选项（options），不过我们都统一把不是命令行本身的部分，划分为`参数`。

在命令注入的场景里，要先搞清楚能注入的是`命令`还是`参数`的部分。

如以下的DVWA的命令注入环境，可注入的位置，明显就是`参数`的位置，前面已经有一个固定的命令了，就是`ping `，我们可以利用的，是`ping `的参数部分。

```php
$target = $_REQUEST[ 'ip' ];
if( stristr( php_uname( 's' ), 'Windows NT' ) ) {
	// Windows
	$cmd = shell_exec( 'ping  ' . $target );
}
else {
	// *nix
	$cmd = shell_exec( 'ping  -c 4 ' . $target );
}
```

但如果代码是类似下面这样，那可以利用的就是`命令+参数`了。

```php
$target = $_REQUEST[ 'cmd' ];
if( stristr( php_uname( 's' ), 'Windows NT' ) ) {
	// Windows
	$cmd = shell_exec( $target );
}
```

第二种情况的利用明显更容易：如果完全没有任何过滤，那就可以直接执行命令了；如果有，则只要绕过对命令的过滤，就可以获得执行。而第一种情况，则需要利用好参数所在的位置，构造出能执行成功的`自定义命令`写法。

下一节就是讨论怎么在参数部分，执行自定义的命令。

## 利用逻辑运算，执行自定义命令

如果只有参数部分可以被利用，command1 args，利用的思路肯定是在args部分夹带自己的命令。这里可以利用Windows的以下几种单行命令的写法（`One-Liners`），用 `&` `&&` `||`等连接符，在一句话里，同时执行两条命令。更具体的解释参见：https://www.robvanderwoude.com/condexec.php

|          语法          |                        描述                         |                  相当于                  |
| :-------------------- | :-------------------------------- | :-------------------------------------- |
| `command1 & command2`  |   command1 命令执行完成后，继续执行command1 命令    |           command1<br>command2           |
| `command1 && command2` |  只有command1 执行成功后，才继续执行 command2 命令  | command1<br>IF %ErrorLevel% EQU 0 <br>command2 |
| `command1 || command2` | 只有command1 无法执行成功，才继续执行 command2 命令 | command1<br>IF %ErrorLevel% NEQ 0 <br>command2 |

 所以在原本是`参数`的位置，通过拼接 `&` 和 `&&`，就能获得第二个命令的执行，第二个命令就可以自定义了。所以类似DVWA的那个场景，在输入IP地址的位置，如果输入 ` localhost & ipconfig`，拼接后，就获得了类似以下命令的执行：

> C:\temp>ping localhost & ipconfig
>
> 正在 Ping DESKTOP-8LBU2AB [127.0.0.1] 具有 32 字节的数据:
> 来自 127.0.0.1 的回复: 字节=32 时间<1ms TTL=128
> 来自 127.0.0.1 的回复: 字节=32 时间<1ms TTL=128
> 来自 127.0.0.1 的回复: 字节=32 时间<1ms TTL=128
> 来自 127.0.0.1 的回复: 字节=32 时间<1ms TTL=128
>
> 127.0.0.1 的 Ping 统计信息:
>     数据包: 已发送 = 4，已接收 = 4，丢失 = 0 (0% 丢失)，
> 往返行程的估计时间(以毫秒为单位):
>     最短 = 0ms，最长 = 0ms，平均 = 0ms
>
> Windows IP 配置
>
>
> 以太网适配器 vEthernet (Default Switch):
>
>    连接特定的 DNS 后缀 . . . . . . . :
>    本地链接 IPv6 地址. . . . . . . . : fe80::bc2f:2172:3c8f:489f%25
>    IPv4 地址 . . . . . . . . . . . . : 172.24.96.1
>    子网掩码  . . . . . . . . . . . . : 255.255.240.0
>    默认网关. . . . . . . . . . . . . :

## 百分号%

`%` 号在命令行里要转义成 `%%`。 在双引号里，百分号不一定需要转义，要试一下才能确定。

## 常规转义符 ^

以下字符不一定需要转义，但加了转义也不影响使用。

- `^`
- `&`
- `<`
- `>`
- `|`



参考文档：

https://www.robvanderwoude.com/battech.php

https://www.robvanderwoude.com/escapechars.php

https://stackoverflow.com/questions/6828751/batch-character-escaping

https://stackoverflow.com/questions/4094699/how-does-the-windows-command-interpreter-cmd-exe-parse-scripts/4095133#4095133

Ref:

https://www.robvanderwoude.com/battech.php
