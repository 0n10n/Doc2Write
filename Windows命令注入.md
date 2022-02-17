# Windows 命令行注入

继续整理一下Windows命令注入的问题。

## 1. 可以注入的位置？ 

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

## 2. 利用管道命令连接符 `| `

Batch里的管道符`|`，可以连接两个命令，如`command1 & command2`，它会把第一个命令的执行结果，传给第二个命令作为参数执行。 如：

- tasklist | find "notepad"
- dir c:\ /s /b | find "TXT" | more

虽然第一个命令的执行结果，作为第二个命令的输入，在渗透测试的场景里未必有用，但这个写法在一些场景里，能成功执行第二条命令，所以依然有利用的价值。


## 3. 利用逻辑运算  `&` `&&` `||`

如果只有参数部分可以被利用，command1 args，利用的思路肯定是在args部分夹带自己的命令。这里可以利用Windows的以下几种单行命令的写法（`One-Liners`），用 `&` `&&` `||`等连接符，在一句话里，同时执行两条命令。更具体的解释参见：https://www.robvanderwoude.com/condexec.php

|          语法          |                        描述                         |                  相当于                  |
| :-------------------- | :-------------------------------- | :-------------------------------------- |
| `command1 & command2`  |   command1 命令执行完成后，继续执行command1 命令    |           command1<br>command2           |
| `command1 && command2` |  只有command1 执行成功后，才继续执行 command2 命令  | command1<br>IF %ErrorLevel% EQU 0 <br>command2 |
| `command1 || command2` | 只有command1 无法执行成功，才继续执行 command2 命令 | command1<br>IF %ErrorLevel% NEQ 0 <br>command2 |

所以在原本是`参数`的位置，通过拼接 `&` 、 `&&`或`||`（先刻意让前面的命令失败），就能获得第二个命令的执行，第二个命令就可以自由操控了。所以类似DVWA的那个场景，在原本输入IP地址的位置，如果输入 ` localhost & ipconfig`，拼接后，就相当于输入了类似以下命令：

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

当然，同理地，还可以执行类似以下组合，成功操控执行后半部分的命令。

> ping localhost && ipconfig
>
> dir not_exist || ipconfig



## 4. 规避过滤

既然有上面这些问题，最容易想到的防守方式，当然是服务器端会过滤常见命令的字符串组合。但这些过滤，也依然存在一定的绕过可能性。以下总结一下规避过滤的常见套路。

总结前，大致列一下Windows命令行里具有含义的一些特殊字符：

- %：用于变量表达，如：`%SystemDrive%` `%PATH%`

- < | > ：重定向符号

- " "：双引号

- !：在启用了延迟变量展开的场景里，用于变量的表示：`!VAR!`

- ^：Batch命令里最常用的转义符，这也是最常利用的规避命令行黑名单的方式

  

### 4.1 在命令里加常规转义符 ^

 `^` 转义符，原本用于转义各种特殊字符，如上面提到的重定向符号 < | > ，都可以用^进行转义，写成  `^<`  `^|` `^>` 等。如以下例子，需要一定的转义才能把我们想要的内容，写入到 `i.php`文件里：

> echo ^<?php phpinfo() ?^> > i.php

虽然常规的字母数字，原本并不需要转义，但如果在它们前面硬是多加一个 `^` 转义符，往往也无伤大雅，依然会保持原义。但这样就能对一些正则或者单纯的字符串匹配造成困难，导致模式绕过了。

以下命令写法都可以顺利获得执行：

> ip^config
>
> d^Ir  d^:\

另外，Windows特殊字符的转义处理并不止用^，还有一些特定场合的特定字符，需要用到其他的转义方式，具体可参见老外这篇总结 ： https://www.robvanderwoude.com/escapechars.php

### 4.2 命令和参数之间的混淆字符

通常，在Windows命令行里，`命令`和`参数` 之间的位置，是用空格分隔的，如 `dir d:\`。但中间这个空格，也是可以用以下其他方式填充的：

- 分号：`;`，举例：`dir;d:\`

- 逗号：`,`，举例：`dir,d:\`

- 等号：`=`，举例： `dir=d:\`

- TAB键，举例：`dir[tab]d:\`

更极端的用法，是在这个位置可以塞入超过一个的此类字符，甚至，多种字符搭配起来使用，所以这些写法也都是可以的，都等价于`dir d:\`：

-  dir;;;;d:\
-  dir======d:\
-  dir====ddd==,,,d:\

> D:\temp>dir====;;;;==,,,d:\
>  驱动器 D 中的卷没有标签。
>  卷的序列号是 C44D-7600
>
>  d:\ 的目录
>
> 2014/07/11  15:52    <DIR>          360Downloads
> 2021/12/31  11:23    <DIR>          appservers
> 2019/11/06  11:52    <DIR>          backup
> 2019/01/15  14:28    <DIR>          cvsroot
> 2016/09/14  15:28    <DIR>          cygwin64

关于这个主题，可以参阅：https://www.robvanderwoude.com/parameters.php

### 4.3 通配符的使用

Batch里的通配符有两种，`*` 和 `?`。

- `*`通配任意字符，从0次到多次，包括NULL字符。
- `?` 通配任意单个字符wildcard（或在文件名末尾的NULL字符）

以下是支持通配符使用的命令（并不是所有命令都支持通配符）：

ATTRIB, CACLS, CIPER, COMPACT, COPY, DEL, DIR, EXPAND, EXTRACT, FIND, FINDSTR, FOR, FORFILES, FTP, ICACLS, IF EXIST, MORE, MOVE, MV, NET (*号代表任意驱动盘), PERMS, PRINT, REN, REPLACE, ROBOCOPY, ROUTE, TAKEOWN, TYPE, WHERE, XCACLS, XCOPY

更详细的介绍参见：[https://ss64.com/nt/syntax-wildcards.html](https://ss64.com/nt/syntax-wildcards.html)

有时候，可以通过搭配通配符使用文件和目录相关参数，就不那么容易通过正则或者单纯的字符串匹配出来。

### 本章小结

需要把这些知识点综合起来使用。比如 ping 命令后面的参数利用，可以写成：`localhost &&di^r==c:\^Win^Dows`

Windows命令的注入，当然还需要掌握各具体命令的使用，这个就更广泛了，不在此文的范围内覆盖了。

------

参考文档：

https://www.robvanderwoude.com/battech.php

https://www.robvanderwoude.com/escapechars.php

