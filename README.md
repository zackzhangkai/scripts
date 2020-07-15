# Before install K8s

```
curl https://raw.githubusercontent.com/zackzhangkai/scripts/master/k8sInstallPre.sh | bash
```

# After install K8s

```
curl https://raw.githubusercontent.com/zackzhangkai/scripts/master/k8sInstallPost.sh | bash
```

# 对于国内用户

1. docker 配置镜像加速器

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



2. yum用aliyu源安装docker

```
sudo yum install -y yum-utils device-mapper-persistent-data lvm2  ebtables ipset tmux nfs-utils socat  conntrack ceph-common glusterfs-client
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo yum makecache fast
sudo yum -y install docker-ce
sudo service docker start

```


# 批量执行

```
for i in {2..105};do sshpass -p "Zhu88jie" ssh-copy-id 192.168.11.$i ;done

ansible node -m copy -a "src=/root/aa.sh dest=/root/aa.sh mode=0755"

ansible node -m shell -a "/root/importImages.sh" -f 100  # 同时100个进程并发
```

# 批量导出镜像

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
sh +x ...
```

导入
```
[root@i-ye5hijl6 ~]# cat importImages.sh
for image_name in `ls /root/bak/*.tar`;do docker load < ${image_name};done
```
