---
title: "logrotate日志切割"
date: 2021-11-09T15:49:47+08:00
draft: false
slug: logrotate
tags: 
- linux
- 笔记
---
### 一、什么是logrotate

 logrotate是一个日志文件管理工具，主要用于简化管理系统生成的大量日志文件。它允许日志的自动切割轮换、压缩、删除等操作。

  通常logrotate作为cron任务被每天执行,并且执行频率不会超过每天一次。除非日志切割是以大小为标准,并且每天多次执行。或者使用-f | --fore 参数。

---

### 二、logrotate安装配置

一般情况logrotate是默认安装的，配置文件在/etc/logrotate.conf。
```bash
# /usr/logrotate.conf
------

weekly # 每周进行一次切割

# keep 4 weeks worth of backlogs
rotate 4 # 保留4周

# create new (empty) log files after rotating old ones
create # 轮转后生成新的空文件。相当于把log先mv再touch 

# use date as a suffix of the rotated file
dateext # 以日期为后缀

# uncomment this if you want your log files compressed
compress # 压缩log

# packages drop log rotation information into this directory
include /etc/logrotate.d

# system-specific logs may be also be configured here.
```
> logrotate默认会读取/etc/logrotate.d 目录下的配置。推荐在此文件下定制化自己的配置。

**常用指令**

完整版可以参考 `man logrotate.conf`

| 配置参数                                 | 说明                                                                         |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| daily                                    | 切割频率，表示每天切割。 其他可用参数weekly、monthly、yearly等。             |
| minsize <u>count</u>                     | 至少到达多少byte才进行切割 。例：size 100 、size 100k 、size100M 、size 100G |
| missingok                                | 如果文件不存在，将继续执行下一个文件不会报错。                                   |
| notifempty                               | 如果文件为空将不会切割。                                                     |
| minage <u>count</u>                      | 至少存在多少天才进行切割。                                                   |
| create <u>user</u> <u>group</u> <u>mod</u> | 切割后立即创建与原文件的同名的空文件。user 用户 group 组 mod 权限            |
| olddir <u>dir</u>                        | 切割后log的存放目录。                                                       |
| copytruncate                             | 先复制log再truncate。这个方法相对于create，文件的inode 不会改变               |
| postrotate/endscript                     | 每个必须单独一行；rotate之后需要执行的命令                                   |
| sharedscript                             | 多个文件时间只会执行一次脚本                                                 |
| compress                                 | 启用压缩                                                                      |
| delaycompress                            | 首次切割将不会压缩。                                                         |


**logrotate 具体流程如下:**

1. crond加载/etc/cron.d/0hourly 每小时的01分执行一次/etc/cron.daily/0anacron
2. 0anacron脚本调用anacron加载/etc/anacrontb 然后根据配置执行 /etc/cron.daily、/etc/cron.monthly、/etc/cron.yearly下的脚本 
3. /etc/cron.daily 调用目录下logrotate脚本 加载/etc/logrotate.conf（lograte.conf 加载/etc/logrotate.d/目录下的所有配置文件）切割log。

```shell
# /etc/cron.daily/logrotate
------

#!/bin/sh 
/usr/sbin/logrotate -s /var/lib/logrotate/logrotate.status /etc/logrotate.conf
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    /usr/bin/logger -t logrotate "ALERT exited abnormally with [$EXITVALUE]"
fi
exit 0
```
--- 

### 实战练习

以mysql为例子创建logrotate的配置

```
vim /etc/logrotate.d/mysqld
------

/var/log/mysqld.log {
        weekly
        missingok
        rotate 2
        notifempty
        compress
        dateext
        dateformat -%Y-%m-%d-%H-%M
        delaycompress
        copytruncate
        minsize 100k
}


-------
```

测试配置是否可用
```bash
logrotate -s /var/lib/logrotate/logrotate.status  /etc/logrotate.d/mysqld -vf
```
![](/images/logrotate.png)















