---
title: "SSH防护"
date: 2021-10-13T20:31:54+08:00
draft: false
slug: ssh_fail_lock
tags:
- linux
- 笔记
---
好久没登陆云服务器，今天登录就提示有上万条的登录失败记录 执行 `lastb | wc -l ` 查看竟有5万条记录。 于是写了个脚本处理一下。
```shell
#!/usr/bin/env bash

# 读取登录失败超过6次的ip地址
ips=$(lastb | awk '{ip[$3]++}END{ for (i in ip) if (ip[i] > 6) print i }')

# 加入防火墙黑名单
# 将port换成自己实际ssh端口,默认22
for i in ${ips[*]};do
        egrep  $i /root/loginf.txt &>/dev/null || { firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="$i"  port protocol="tcp" port=22 drop" ; echo $i >> /root/loginf.txt ; }
done

firewall-cmd --reload
```
写到crontab 定时执行
