---
title: "MySQL8安装与配置"
date: 2021-08-07T10:13:13+08:00
draft: false
slug: mysql
categories:
- 技术分享
tags:
- mysql
- tech
- 软件安装
---

环境:
- 操作系统：Fedora 31（CentOS7通用）
- 数据库版本：MySQL 8.0.18
- x86_64
---
##### 准备工作

1. [MySQL官网](https://downloads.mysql.com/archives/community/)下载安装包
![](/images/mysql-dl.png)
>此版本为解压即用免编译版本。

2. 卸载mariadb和mysql的rpm包
```bash
yum list installed | egrep "(mariadb|mysql)" | xargs yum remove -y
```

3. mysql依赖libaio库，如果本地未安装，后续初始化数据目录和启动服务会有问题。
```bash
yum search libaio
yum install libaio -y
# 有的还需要安装 ncurses-compat-libs libxcrypt-compat
```
---
##### 目录结构

|Directory| Contents of Directory|
|----|----|
|bin|[mysqld](https://dev.mysql.com/doc/refman/8.0/en/mysqld.html) server,client and utils programs|
|docs|MySQL manual in info format|
|man|Unix manual pages|
|include|include(header) files|
|lib|Libraries|
|share|Error messages,dictionary,and SQL for database installation|
|support-files|Miscellaneous support files|
---
##### 配置软件

创建用户、组及目录
```bash
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
tar -Jxf mysql-8.0.18-linux-glibc2.12-x86_64.tar.xz -C /usr/local/
ln -s /usr/local/mysql-8.0.18-linux-glibc2.12-x86_64 /usr/local/mysql
mkdir -p /data/mysql/{data,binlog} /var/run/mysqld
chown -R mysql:mysql /data/mysql /usr/local/mysql-8.0.18-linux-glibc2.12-x86_64 /var/run/mysqld
chmod -R 750 /data/mysql
```

设置环境变量
```bash
echo 'export PATH=/usr/local/mysql/bin:$PATH' >> ~/.bashrc
. ~/.bashrc
```

初始化数据
```bash
mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql/data
```

配置文件

```bash
cat > /etc/my.cnf <<EOF
[mysqld]
user=mysql
basedir=/usr/local/mysql
datadir=/data/mysql/data
log_bin=/data/mysql/binlog/mysql-bin
max_binlog_size=100M
port=3306
server_id=1
pid-file=/var/run/mysqld/mysqld.pid
log-error=/var/log/mysqld.log
socket=/tmp/mysql.sock
EOF
```
准备启动脚本

```bash
# CentOS 执行
cp /usr/local/mysql/support-files/mysql.service /etc/init.d/mysqld
chkconfig --add mysqld

# Fedora 执行
cd /usr/local/mysql/support-files
cp mysql.server mysqld
cat > /lib/systemd/system/mysqld.service <<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
Type=forking
User=mysql
Group=mysql
ExecStart=sh -c '/usr/local/mysql/support-files/mysqld start'
ExecReload=sh -c '/usr/local/mysql/support-files/mysqld reload'
ExecStop=sh -c '/usr/local/mysql/support-files/mysqld stop'
Restart=on-failure
RestartSec=15s
EOF
```
>参考: [Systemd 入门教程：命令篇](https://www.ruanyifeng.com/blog/2016/03/systemd-tutorial-commands.html)、[Systemd 入门教程：实战篇](https://www.ruanyifeng.com/blog/2016/03/systemd-tutorial-part-two.html)

启动服务
```bash
# Fedora
systemctl daemon-reload
systemctl start mysqld  --now
# CentOS
chkconfig mysqld on
systemtl start mysqld
```
初始化时使用initialize-insecure 参数并不会生成随机root密码
```sql
mysql -uroot -p 
Enter password:  # 直接回车
```
设置root本地密码
```sql
alter user user() identified by 'password';
```
开启远程连接
```sql
create user root@'%' identified by 'password';
use mysql;
select host from user; 
+-----------+
| host      |
+-----------+
| %         |
| localhost |
| localhost |
| localhost |
| localhost |
+-----------+
```
远程连接测试

![](/images/nav.png)
