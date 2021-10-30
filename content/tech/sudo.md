---
title: "sudo 执行脚本找不到变量"
date: 2021-10-29T23:39:42+08:00
draft: false
tags:
- 笔记
- linux
---
习惯了使用root用户的我，一次使用普通用户执行sudo ./xxxx.sh 发现报错找不到java.切换到root用户下执行 
```shell
java
```
![](/images/java.png)
完全没问题，但是每次执行sudo时 就会报错java找不到.
```shell
sudo java
```
![](/images/jnf.png)
查找资料发现执行sudo时会将变量重置为minimal
![](images/env_reset.png)
![](/images/env_reset2.png)
如果需要保存变量/etc/sudoers 添加
`Defaults 	env_keep = "JAVA_HOME"`
然后修改`secure_path` 将JAVA_HOME路径添加到最后即可.
![](/images/suend.png)

结果验证：
![](/images/sures.png)
