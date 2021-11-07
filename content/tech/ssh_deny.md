---
title: "SSH爆破防护"
date: 2021-10-13T20:31:54+08:00
draft: false
slug: ssh_deny
tags:
- linux
- 笔记
---
好久没登陆云服务器，最近登录提示竟有数万条失败记录。 如果不及时处理肯定有失守的一天。空闲时间写了个小脚本处理一下。
```shell
#!/usr/bin/env bash

# 读取登录失败超过4次的ip地址
ips=$(lastb | awk '{ip[$3]++}END{ for (i in ip) if (ip[i] > 4) print i }')

# 加入防火墙黑名单
# 将port换成自己实际ssh端口,默认22
for i in ${ips[*]};do
        egrep  $i /root/loginf.txt &>/dev/null || { firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="$i"  port protocol="tcp" port=22 drop" ; echo $i >> /root/loginf.txt ; }
done

firewall-cmd --reload
```
写到crontab 定时执行

---

11月4日更

抽空完善了一下脚本，通过定时任务很难及时有效的阻止爆破行为。
这次改动是将脚本写成了守护进程,并且由systemd来管理。

编写脚本
```bash
vim /usr/local/bin/sshdeny
```
CentOS7 lastb版本问题没有--since参数将ips变量替换为以下即可
```bash
ips=$(lastb | grep "$(date | cut -d ' ' -f2-4)" | awk '{ip[$3]++}END{ for (i in ip) if (ip[i] > 4) print i }') 
```
```shell
#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset

[ -f /tmp/loginf.txt ] || { lastb | awk '{ip[$3]++}END{ for (i in ip) if (ip[i] > 4) print i }' > /tmp/loginf.txt && while read line ;do  firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="$line"  port protocol="tcp" port=22 drop" >/dev/nul 2>&1 ;done < /tmp/loginf.txt; }
while :;do
ips=$(lastb --since today | awk '{ip[$3]++}END{ for (i in ip) if (ip[i] > 4) print i }')
# lastb 版本太低的话没有--since 参数。 可以使用以下命令替代
# ips=$(lastb | grep "$(date | cut -d ' ' -f2-4)" | awk '{ip[$3]++}END{ for (i in ip) if (ip[i] > 4) print i }')
for i in ${ips[*]};do
    if  [ x"$i" == "x" ];then
            continue
    elif egrep "$i" /tmp/loginf.txt &>/dev/null ;then
            continue
    fi
    echo "IP:$i SSH connection denied"
    firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="$i"  port protocol="tcp" port=22 drop" >/dev/nul 2>&1
    echo $i >> /tmp/loginf.txt
    firewall-cmd --reload
done
sleep 1
done
```

创建service文件
CentOS7 需要将MemoryMax=1G 更换为 MemoryLimit=1G
```bash
cat >/usr/lib/systemd/system/sshdeny.service <<EOF
[Unit]
Description=Multiple login failures will deny SSH connections

[Service]
User=root
Type=simple
ExecStart=/usr/local/bin/sshdeny
ExecReload=/usr/bin/kill -HUP $MAINPID
ExecStop=/usr/bin/kill -TERM $MAINPID
TimeoutStartSec=30s
Restart=on-failure
CPUQuota=30%
MemoryMax=1G

[Install]
WantedBy=multi-user.target

EOF
```
> 参考：[systemd.index 中文手册](http://www.jinbuguo.com/systemd/systemd.index.html)

重载systemd service
```bash
systemctl daemon-reload
```
启动服务
```bash
systemctl start sshdeny
```
检查测试
```bash
systemctl status sshdeny
```
![](/images/sshdeny.png)

防止ssh爆破其实网上有很多现成的轮子比如fail2ban、DenyHosts等，本文只做这里只做一个思考。实际中避免重复做轮子。

