# Windows 命令行的转义

## 百分号%

`%` 号在命令行里要转义成 `%%`。 在双引号里，百分号不一定需要转义，要试一下才能确定。

## 常规转义符 ^

以下字符不一定需要转义，但加了转义也不影响使用。

- `^`
- `&`
- `<`
- `>`
- `|`

例如：





参考文档：

https://www.robvanderwoude.com/battech.php

https://www.robvanderwoude.com/escapechars.php

https://stackoverflow.com/questions/6828751/batch-character-escaping

https://stackoverflow.com/questions/4094699/how-does-the-windows-command-interpreter-cmd-exe-parse-scripts/4095133#4095133

