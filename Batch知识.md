## 字符的转义

https://www.robvanderwoude.com/escapechars.php

|    Escape Characters    |                 |                                                              |
| :---------------------: | :-------------: | :----------------------------------------------------------: |
| Character to be escaped | Escape Sequence |                            Remark                            |
|           `%`           |      `%%`       |                                                              |
|           `^`           |      `^^`       | May not always be required in doublequoted strings, but it won't hurt |
|           `&`           |      `^&`       |                                                              |
|           `<`           |      `^<`       |                                                              |
|           `>`           |      `^>`       |                                                              |
|           `|`           |      `^|`       |                                                              |
|           `'`           |      `^'`       | Required only in the [FOR /F](https://www.robvanderwoude.com/ntfor.php#FOR_F) "subject" (i.e. between the parenthesis), *unless* `backq` is used |
|           ```           |      `^``       | Required only in the [FOR /F](https://www.robvanderwoude.com/ntfor.php#FOR_F) "subject" (i.e. between the parenthesis), *if* `backq` is used |
|           `,`           |      `^,`       | Required only in the [FOR /F](https://www.robvanderwoude.com/ntfor.php#FOR_F) "subject" (i.e. between the parenthesis), even in doublequoted strings |
|           `;`           |      `^;`       |                                                              |
|           `=`           |      `^=`       |                                                              |
|           `(`           |      `^(`       |                                                              |
|           `)`           |      `^)`       |                                                              |
|           `!`           |      `^^!`      | Required only when [delayed variable expansion](https://www.robvanderwoude.com/variableexpansion.php) is active |
|           `"`           |      `""`       | Required only inside the search pattern of [FIND](https://www.robvanderwoude.com/find.php) |
|           `\`           |      `\\`       | Required only inside the regex pattern of [FINDSTR](https://www.robvanderwoude.com/findstr.php) |
|           `[`           |      `\[`       |                                                              |
|           `]`           |      `\]`       |                                                              |
|           `"`           |      `\"`       |                                                              |
|           `.`           |      `\.`       |                                                              |
|           `*`           |      `\*`       |                                                              |
|           `?`           |      `\?`       |                                                              |

 

### Windows 系统环境变量

[Windows Environment Variables - Windows CMD - SS64.com](https://ss64.com/nt/syntax-variables.html)

## 百分号%

`%` 号在命令行里要转义成 `%%`。 在双引号里，百分号不一定需要转义，要试一下才能确定。

### 字符串截取

[DOS - String Manipulation (dostips.com)](https://www.dostips.com/DtTipsStringManipulation.php)



### 命令行参数

https://www.robvanderwoude.com/parameters.php



As an additional info to Joey's answer, which isn't described in the help of `set /?` nor `for /?`.

`%~0` expands to the name of the own batch, exactly as it was typed.
So if you start your batch it will be expanded as

```
%~0   - mYbAtCh
%~n0  - mybatch
%~nx0 - mybatch.bat
```