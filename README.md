# Before install K8s

```
curl https://raw.githubusercontent.com/zackzhangkai/scripts/master/k8sInstallPre.sh | bash
```

# After install K8s

```
curl https://raw.githubusercontent.com/zackzhangkai/scripts/master/k8sInstallPost.sh | bash
```



# 在国内安装100个节点的k8s集群

接到了个任务，需要在pek3b安装100个节点的K8s集群。由于之前机器是在ap2a，所以镜像都没有问题。现在在国内安装，镜像成了大问题，需要解决以下问题：
1. 从docker.io拉镜像慢的问题  
2. 这100台机器肯定是在一个私有网络vxnet里面，然后对router统一配置eip，让它能够访问外网。每个Node节点都要初始化，拉镜像，只有一个eip出口，网络会更慢。  
3. 如何批量化操作的问题，如需要对100个机器环境初始化，安装一些基础的包，如 docker、ipset、socat等。  

思路：安装国内镜像源；安装镜像加速器；网先一台机器装后，把镜像导出，先给每个节点把镜像导入，避免每个节点都从公网下载；用ansbile统一执行管理。
 
为了实现这个，思路如下：

1. 通过脚本统一配置免密登陆
```
for i in {2..105};do sshpass -p "Zhu88jie" ssh-copy-id 192.168.11.$i ;done
```

2. 换yum源为阿里镜像源

```
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo yum makecache fast
sudo yum -y install docker-ce
sudo service docker start
sudo yum install -y yum-utils device-mapper-persistent-data lvm2  ebtables ipset tmux nfs-utils socat  conntrack ceph-common glusterfs-client
```

3. docker 配置镜像加速器

```
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://xebue7n6.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

4. ansible批量操作

如：把上述步骤2、步骤3的命令写到一个脚本里面，然后批量执行

```
ansible node -m copy -a "src=/root/aa.sh dest=/root/aa.sh mode=0755"

ansible node -m shell -a "/root/importImages.sh" -f 100  # 同时100个进程并发，如果不加-f默认是5个并发，太慢了，直接开到100，但是此时cpu会飙满。
```

5. 在一个节点上装完kubesphere，并开启所有的插件，然后把镜像全部导出来后，分发到所有的的节点后，导入到每个节点。

导出第一个节点的所有的镜像：

```
[root@i-ye5hijl6 ~]# cat ExportImg.sh
LIST=""
TXT=/root/tmp.txt
BAKDIR=/usr/local/bak
LOGDIR=/usr/local/bak/log
LOGFILE=$LOGDIR/bak.`date +%Y%m%d`.log

[ ! -d $BAKDIR ] && mkdir -p $BAKDIR
[ ! -d $LOGDIR ] && mkdir -p $LOGDIR

if [ -n "$LIST" ]
then
        for list in $LIST
        do
                RESLIST=`docker images |grep $list | awk '{print $1}'`
                for reslist in $RESLIST
                do
                RESTAG=`docker images |grep "$reslist" |awk '{a=$1":"$2;print a }'`
                BAKNAME=`docker images |grep "$reslist" |awk '{a=$1":"$2;print a }'|sed 's/\//_/g'`
                /usr/bin/docker save $RESTAG -o $BAKDIR/$BAKNAME.tar  >> $LOGFILE 2>&1
                done
        done
else
        REC=`docker images |awk '{print $1,$2,$3}'|sed 1d >> $TXT`
        RESLIST=`cat $TXT|awk '{print $1}'`
        for reslist in $RESLIST
        do
                RESTAG=`docker images |grep "$reslist" |awk '{a=$1":"$2;print a }'`
                BAKNAME=`docker images |grep "$reslist" |awk '{a=$1":"$2;print a }'|sed 's/\//_/g'`
                /usr/bin/docker save $RESTAG -o $BAKDIR/$BAKNAME.tar  >> $LOGFILE 2>&1
        done
        /usr/bin/rm -f $TXT
fi

if [ -s $LOGFILE ]
then
        echo -e "\033[31mERROR:Images Backup Failed!\033[0m"
        echo -e "\033[31mPlease View The Log Lile : $LOGFILE\033[0m"
else
        /usr/bin/rm -f $LOGFILE
fi
```
直接执行
```
sh +x ExportImg.sh
```

用ansible分发到每个节点后，导入

```
[root@i-ye5hijl6 ~]# cat importImages.sh
for image_name in `ls /root/bak/*.tar`;do docker load < ${image_name};done
```
