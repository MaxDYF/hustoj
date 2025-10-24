#!/bin/bash

OSRS=`lsb_release -rs`
 
cd /home/judge/src/install || exit 1
dpkg --configure -a
while ! apt-get install -y docker.io containerd
do
		service docker start
		echo "Network fail, retry... you might want to make sure docker.io is available in your apt source"
done

cat > /etc/docker/daemon.json <<EOF
{
	"registry-mirrors": [
	        "https://docker.1ms.run",
	        "https://docker.xuanyuan.me"
    	],
	"live-restore": true,
	"log-opts": {
		"max-size": "512m",
		"max-file": "3"
	}
}
EOF

bash add_dns_to_docker.sh

systemctl enable docker
service docker restart

# 最大尝试次数
max_attempts=5
# 当前尝试次数
attempt=0

# 循环尝试构建
while [ $attempt -lt $max_attempts ]; do
    echo "Attempt $((attempt + 1)) of $max_attempts"
    if docker build -t hustoj . ; then
        echo "Docker build succeeded"
	sed -i "s/OJ_USE_DOCKER=0/OJ_USE_DOCKER=1/g" /home/judge/etc/judge.conf
	sed -i "s/OJ_PYTHON_FREE=0/OJ_PYTHON_FREE=1/g" /home/judge/etc/judge.conf
	sed -i "s|OJ_DOCKER_PATH=/usr/bin/podman|OJ_DOCKER_PATH=/usr/bin/docker|g" /home/judge/etc/judge.conf
	pkill -9 judged
	/usr/bin/judged
        exit 0
    else
        echo "Docker build failed, retrying..."
        attempt=$((attempt + 1))
    fi
done

echo "Failed after $max_attempts attempts"

echo "Network fail, retry... you might want to make sure https://hub.docker.com/ is available"
echo "Docker image failed, try download from temporary site ... "
while ! wget -O hustoj.docker.tar.bz2 http://dl3.hustoj.com/docker/hustoj.docker.$OSRS.tar.bz2; do
    echo "Download from dl3.hustoj.com failed, trying mirror dl.hustoj.com..."
    # 尝试从镜像站点下载，如果成功则退出循环
    if wget -O hustoj.docker.tar.bz2 http://dl.hustoj.com/docker/hustoj.docker.$OSRS.tar.bz2; then
        break
    fi
    echo "Both downloads failed, trying again..."
done
bzip2 -d hustoj.docker.tar.bz2
#docker load < hustoj.docker.tar
if docker load -i hustoj.docker.tar 
then
    	sed -i "s/OJ_USE_DOCKER=0/OJ_USE_DOCKER=1/g" /home/judge/etc/judge.conf
	sed -i "s/OJ_PYTHON_FREE=0/OJ_PYTHON_FREE=1/g" /home/judge/etc/judge.conf
	sed -i "s|OJ_DOCKER_PATH=/usr/bin/podman|OJ_DOCKER_PATH=/usr/bin/docker|g" /home/judge/etc/judge.conf
	pkill -9 judged
	/usr/bin/judged
fi
rm hustoj.docker.tar

 

