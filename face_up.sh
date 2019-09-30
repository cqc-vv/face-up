#!/bin/bash

# stop localserver
systemctl stop localserver
systemctl disable localserver

# svn and tar
# cd /home/oeasy/
# svn checkout svn://zimg.0easy.com/face_node_v3  /home/oeasy/face_node
# sleep 10
# cd face_node && unzip face_node_svn_comp_both.zip &&  mv face_node_svn/* .



oeasycfg=/home/oeasy/OeasyProxy/oeasycfg.ini
OeasyP=/home/oeasy/OeasyProxy
oeasy=/home/oeasy


oeasyid(){
area_id=`cat  /home/oeasy/OeasyProxy/oeasycfg.ini  | grep proxyId= | awk -F"000000" '{print $2}'`
if [ ! $area_id ];then
	area_id=`cat  /home/oeasy/OeasyProxy/oeasycfg.ini  | grep proxyId= | awk -F"000" '{print $2}'`
	if [ $area_id = 9999 ] || [ ! -n "$area_id" ];then
		read -p "因为目前获取不到id，请输入小区ID:" area_id
	fi
else
	if [ $area_id = 9999 ] || [ ! -n "$area_id" ];then
		read -p "因为目前获取不到id，请输入小区ID:" area_id
	fi
fi
}

net(){
A=`ip add | gawk '{print $2}' | grep en | sed  's/://g'`
A1=`cat /etc/network/interfaces | gawk '/en/{print $2}' | sed -n '1p'`
a1=`ifconfig | grep "inet addr:" | gawk '{print $2}' | sed 's/addr://g'| sed -n "1p"`
a2=`ifconfig | grep "Mask" | gawk '{print $4}' | sed 's/Mask://g' | sed -n "1p"`
a3=`ip route show  | gawk '{print $3}' | sed -n '1p'`
n1=`cat /etc/network/interfaces | gawk '/static/{print $4}'`
#检测网络连接
ping -c 1 114.114.114.114 > /dev/null 2>&1
if [ $? -ge 1 ];then
    echo "检测网络连接异常"
	echo "执行配置网卡信息"
	sed -i  's/'$A1'/'$A'/g'  /etc/network/interfaces
	sed -i  's/static/dhcp/'  /etc/network/interfaces
	sed -i '/^address/,$d'  /etc/network/interfaces
	/etc/init.d/networking restart
	echo  "网卡名称已更新"	
	echo  "网卡信息已更新"
	ip add
	elif [ ! -n "$n1" ] ;then
	sed -i  's/dhcp/static/'  /etc/network/interfaces
	sed -i '/^address/,$d'  /etc/network/interfaces
	sed -i '$aaddress '$a1'' /etc/network/interfaces
	sed -i '$anetmask '$a2'' /etc/network/interfaces
	sed -i '$agateway '$a3'' /etc/network/interfaces
	sed -i '$adns-nameserver 114.114.114.114' /etc/network/interfaces
	/etc/init.d/networking restart
	echo "网卡信息已固定"
	ip add
	else
	echo "检测网络配置正常无需改动"
	fi
}



function OeasyProxy(){
cd ${OeasyP}
svn info | grep OeasyProxy_4.X
if [[ $? = 0 ]];then
	svn up
else
	cd ${oeasy}/
	svn co svn://zimg.0easy.com/OeasyProxy_4.X
	echo 'oeasy' | sudo -S /etc/init.d/oproxy stop
	mv ${OeasyP}  ${OeasyP}3b
	mv ${OeasyP}_4.X  ${OeasyP}
	hh=`cat /home/oeasy/OeasyProxy/oeasycfg.ini | grep -n "\[log\]" |awk -F: '{print $1}'`
    size=`cat /home/oeasy/OeasyProxy/oeasycfg.ini |grep size| grep -v channel |awk -F= 'NR==2{print $2}'`
	size1=`cat /home/oeasy/OeasyProxy3b/oeasycfg.ini|grep size| grep -v channel |awk -F= 'NR==2{print $2}'`
	let hhh=hh-3
	sed -i ''$hhh','$hh's!size='$size'!size='$size1'!g'  ${oeasycfg}
fi

echo 'oeasy' | sudo -S sed -r -i '1,80s!(//)[^:]*(:9317)!\1127.0.0.1\2!' ${oeasycfg}
rm -rf /etc/systemd/system/OeasyProxy.service
rm -rf /etc/systemd/system/UploadOpenDoorInfor.service
cp ${OeasyP}/OeasyProxy.service  /etc/systemd/system/OeasyProxy.service
cp ${OeasyP}/UploadOpenDoorInfor.service /etc/systemd/system/UploadOpenDoorInfor.service

for it in OeasyProxy.service UploadOpenDoorInfor.service ; do systemctl enable $it;systemctl start $it;done
systemctl daemon-reload
killall OeasyProxy UploadOpenDoorInfor
sleep 10

chmod 775 ${OeasyP}/run.sh
chmod 775 ${OeasyP}/OeasyProxy
chmod 775 ${OeasyP}/UploadOpenDoorInfor

# set OeasyProxy id

if [[ -d "/home/oeasy/OeasyProxy3b" ]];then
		area_id=`cat  /home/oeasy/OeasyProxy3b/oeasycfg.ini  | grep proxyId= | awk -F"000000" '{print $2}'`
		sed -r -i '1,$s!(proxyId=)[^*]*!\1000000'$area_id'!'  ${oeasycfg}
		echo 'oeasy' | sudo -S sed -r -i '1,'$hh's!(//)[^:]*(:9317)!\1127.0.0.1\2!' ${oeasycfg}		
		k=1
		hhj=`cat ${oeasycfg} | grep -n size= | grep -v channel |awk -F: 'NR==2{print $1}'`
		#1eed1901143d 192.168.5.99 oeasy123
cat ${OeasyP}3b/oeasycfg.ini | grep -e ip= -e Mac -e pass -e cameraId= -e NVRChannel=| awk -F= '{print $2}' | awk '{if(NR%5!=0)ORS=" ";else ORS="\n"}1'| while read line
do
			nc=$(echo $line |awk '{print $1}')
			id=$(echo $line |awk '{print $2}'| awk -F_ '{print $2}')
			mac=$(echo $line |awk '{print $3}')
			ip=$(echo $line |awk '{print $4}')
			passwaed=$(echo $line |awk '{print $5}')
			
			sed -r -i '1,'$hhj's!('$k'\\ip=)[^*]*!\1'$ip'!'  ${oeasycfg}
			sed -r -i '1,$s!('$k'\\channels\\1\\NVRChannel=)[^*]*!\1'$nc'!'  ${oeasycfg}
			sed -r -i '1,$s!('$k'\\channels\\1\\cameraId=)[^*]*!\1'$id'!'  ${oeasycfg}
			sed -r -i '1,$s!('$k'\\channels\\1\\intercomMac=)[^*]*!\1'$mac'!'  ${oeasycfg}
			sed -r -i '1,$s!('$k'\\password=)[^*]*!\1'$passwaed'!'  ${oeasycfg}
			k=$(expr $k + 1)
        done
fi

oeasyid

sed -r -i '1,$s!(proxyId=)[^*]*!\1000000'$area_id'!'  ${oeasycfg}
nv=`cat /home/oeasy/OeasyProxy3b/oeasycfg.ini  | grep IsUseNvr= | awk -F= '{print $2}'`
if [[ $nv = true ]];then
			sed -r -i '1,$s!(IsUseNvr=)[^*]*!\11!'  ${oeasycfg}
			killall OeasyProxy
			sleep 3
			oeasycfg=/home/oeasy/OeasyProxy/oeasycfg.ini
			hh1=`cat ${oeasycfg} | grep -n size= | grep -v channel |awk -F: 'NR==3{print $1}'`
			hh2=`grep -n 'nvr' ${oeasycfg} |awk -F":" '{print $1}'`
			let nvrh=hh1-hh2
			j=1
			grep -A $nvrh 'nvr' ${oeasycfg} | grep -e ip=  -e pass -e IPChanNum | awk -F= '{print $2}'| awk '{if(NR%3!=0)ORS=" ";else ORS="\n"}1'| while read line
			do
			nvrs=$(echo $line |awk '{print $1}')
			nvr=$(echo $line |awk '{print $2}')
			nvrp=$(echo $line |awk '{print $3}')
			sed -r -i ''$hh2','$hh1's!('$j'\\IPChanNum=)[^*]*!\1'$nvrs'!'  ${oeasycfg}
			sed -r -i ''$hh2','$hh1's!('$j'\\ip=)[^*]*!\1'$nvr'!'  ${oeasycfg}
			sed -r -i ''$hh2','$hh1's!('$j'\\password=)[^*]*!\1'$nvrp'!'  ${oeasycfg}
			j=$(expr $j + 1)
			done
fi
killall OeasyProxy UploadOpenDoorInfor
cp ${OeasyP}3b/oeasycfg.ini  ../oeasycfg.ini3b
rm -rf ${OeasyP}3b
chown oeasy.oeasy ${OeasyP}/ -R
rm -rf  /etc/init.d/multiobj  /etc/init.d/oproxy  /etc/init.d/veriface
echo "======== upgrade OeasyProxy server success =========="
}


cudnn(){
cdnn=`cat /usr/local/cuda/include/cudnn.h | grep "define CUDNN_MAJOR" | awk '{print $3}'`
	if [[ $cdnn != 6 ]] && [[ ! -f "/home/oeasy/libcudnn6_6.0.21-1+cuda8.0_amd64.deb" ]] ;then
	cd ${oeasy}/
	wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn6_6.0.21-1%2Bcuda8.0_amd64.deb
	wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn6-dev_6.0.21-1%2Bcuda8.0_amd64.deb
	dpkg -i libcudnn6_6.0.21-1+cuda8.0_amd64.deb
	dpkg -i libcudnn6-dev_6.0.21-1+cuda8.0_amd64.deb
cat > /etc/ld.so.conf.d/cuda.conf <<EOF
/usr/local/cuda/lib64
EOF
ldconfig
source /etc/profile
ldconfig
	fi
}
pipyuan(){
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host=mirrors.aliyun.com
EOF
apt remove rcconf -y
apt install nmap -y
pip uninstall tensorflow tensorflow-gpu -y
sleep 3
pip install sysv_ipc timeout_decorator sqlalchemy requests paho-mqtt grpc grpcio==1.12.1 grpcio-tools==1.12.1 IPy easydict tensorflow{,-gpu}==1.4.1 numpy==1.14.5  -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com -q



if [  $? -ne 0 ];then
    echo "First installation failed ,try it again"
	pip install requests paho-mqtt grpc grpcio==1.12.1 grpcio-tools==1.12.1 IPy easydict  tensorflow{,-gpu}==1.4.1 numpy==1.14.5 -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com -q
fi
}

function ped(){

multi=pedestriandetector
newmulti=nvr_pedestrian_bin

if [ -d "/home/oeasy/pedestriandetector" ];then
	cd  ${oeasy}/${multi}
	svn info | grep ${newmulti}
	if [[ $? = 0 ]];then
	svn up
	else	
	cd ${oeasy}/
	svn co svn://zimg.0easy.com/nvr_pedestrian_bin
	rm -rf ${oeasy}/${multi}
	mv  ${oeasy}/${newmulti} ${oeasy}/${multi}
	fi
else
	cd ${oeasy}/
	svn co svn://zimg.0easy.com/nvr_pedestrian_bin
	mv  ${oeasy}/${newmulti} ${oeasy}/${multi}
fi
rm -rf  /etc/init.d/multiobj
cat > /etc/systemd/system/multiobj.service <<EOF
[Unit]
Description=multiobj
After=network.target

[Service]
User=oeasy
Environment=export LD_LIBRARY_PATH=/home/oeasy/pedestriandetector/lib:/home/oeasy/pedestriandetector/lib/HCNetSDK_linux/:/home/oeasy/pedestriandetector/lib/ffmpeg/:/home/oeasy/pedestriandetector/lib/HCNetSDK_linux/HCNetSDKCom/:/home/oeasy/pedestriandetector/lib/boost1.58/:/home/oeasy/pedestriandetector/lib/opencv3.2/
WorkingDirectory=/home/oeasy/pedestriandetector
ExecStart=/home/oeasy/pedestriandetector//bin/pedestrian_detector
ExecReload=/bin/kill -HUP 
KillMode=process
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
chown oeasy.oeasy  ${oeasy}/${multi}
killall pedestrian_detector
for it in multiobj.service; do systemctl enable $it;systemctl start $it;done
}

function face6(){
facev5=face_node_v5
facev52=face_node_v5.2
newface=face_node_v6.1


cd ${oeasy}/
if [  -d ${oeasy}/$facev5 ] || [  -d ${oeasy}/$facev52 ] ;then
	rm -rf  ${oeasy}/$facev5
    rm -rf  ${oeasy}/$facev52
	rm -rf face_node_v4 face_node
else
	cudnn
fi
if [ -d ${oeasy}/$newface ];then
	cd  ${oeasy}/${newface}
	svn up
else	
	cd ${oeasy}/
	svn  co svn://zimg.0easy.com/face_node/face_node_v6/face_node_v6.1
     wget  http://115.231.181.22:81/oeasy_soft/models.tar.gz
	 tar -xvf models.tar.gz
	cp -r ${oeasy}/models/* ${oeasy}/${newface}/oeasy_face_lib/
	rm -rf ${oeasy}/${newface}/conf/face_compare_server.conf
	cd ${oeasy}/${newface}/conf
	svn up
	sudo chown oeasy.oeasy ${oeasy}/${newface}/ -R

fi

pipyuan

echo "========== pip install package successed ============"

chown oeasy.oeasy ${oeasy}/face_node -R

# set area id

sed -r -i '1,20s!(area =)[^*]*!\10000000000,000000'$area_id'!'  ${oeasy}/${newface}/conf/face_compare_server.conf
# service daemon


   cd ${oeasy}/${newface}/face_compare_server
   python -m grpc_tools.protoc -I./protos --python_out=./rpc --grpc_python_out=./rpc compare.proto
   
   rm -rf /etc/systemd/system/lbs9317.service
   rm -rf /etc/systemd/system/face_detect.service
   rm -rf  /etc/systemd/system/face_compare.service
   
   sed -r -i '$s!(ExecStart=)[^*]*!\1/usr/bin/python algo_server.py detect 7000 0!'  ${oeasy}/${newface}/face_compare_server/services/face_detect.service
   cd ${oeasy}/${newface}/face_compare_server/services
   cp *service /etc/systemd/system
	sed -i 's#/usr/bin/taskset -c 4,5 ##'  /etc/systemd/system/face_detect.service 
	systemctl daemon-reload
#lushu
GTX=`nvidia-smi |grep GTX | gawk '{print $5}'  | cut -c1-3`
 if [  -d /etc/version ];then
 lu=`cat /etc/version`
sed -r -i '1,10s!(user_max_num  = )[^*]*!\1$lu!'  /home/oeasy/face_node_v6.1/conf/face_compare_server.conf
elif [ $GTX -eq 106 ];then
        sed -r -i '1,10s!(user_max_num  = )[^*]*!\110!'  /home/oeasy/face_node_v6.1/conf/face_compare_server.conf
elif  [ $GTX -eq 105 ];then
        sed -r -i '1,10s!(user_max_num  = )[^*]*!\16!'  /home/oeasy/face_node_v6.1/conf/face_compare_server.conf
        else
        echo "显卡异常"
fi

killall python
# start service
for item in face_compare.service face_detect.service face_lbs.service; do systemctl enable $item;systemctl start $item;done



echo "======== upgrade face for 6 server success =========="
}

function 2lu(){
facev5=face_node_v5
facev52=face_node_v5.2
newface=face_node_v6.1



if [ -d ${oeasy}/$newface ];then
	cd  ${oeasy}/${newface}
	svn up
else	
	cd ${oeasy}/
	svn co svn://zimg.0easy.com/face_node/face_node_v6/face_node_v6.1
     wget  http://115.231.181.22:81/oeasy_soft/models.tar.gz
	 tar -xvf models.tar.gz
	cp -r ${oeasy}/models/* ${oeasy}/${newface}/oeasy_face_lib/
	cd ${oeasy}/${newface}/oeasy_face_lib/
	mv facenet models_0330
	sudo chown oeasy.oeasy ${oeasy}/${newface}/ -R

fi
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host=mirrors.aliyun.com
EOF
apt remove rcconf -y
apt install nmap -y

sleep 3
pip install timeout_decorator sqlalchemy requests paho-mqtt grpc grpcio==1.12.1 grpcio-tools==1.12.1 IPy easydict tensorflow==1.4.1 numpy==1.14.5 


if [  $? -ne 0 ];then
    echo "First installation failed ,try it again"
	pip install timeout_decorator requests paho-mqtt grpc grpcio==1.12.1 grpcio-tools==1.12.1 IPy easydict tensorflow==1.4.1 numpy==1.14.5  
fi

echo "========== pip install package successed ============"

chown oeasy.oeasy ${oeasy}/${newface} -R

# set area id

sed -r -i '1,10s!(area =)[^*]*!\1000000'$area_id'!'  ${oeasy}/${newface}/conf/face_compare_server.conf
# service daemon


   cd ${oeasy}/${newface}/face_compare_server
   python -m grpc_tools.protoc -I./protos --python_out=./rpc --grpc_python_out=./rpc compare.proto
   
   rm -rf /etc/systemd/system/lbs9317.service
   rm -rf /etc/systemd/system/face_detect.service
   rm -rf  /etc/systemd/system/face_compare.service
   cd ${oeasy}/${newface}/face_compare_server/services
   cp *service /etc/systemd/system

killall python
# start service
for item in face_compare.service face_detect.service face_lbs.service; do systemctl enable $item;systemctl start $item;done

echo "======== upgrade face for 6 server success =========="
}

function usage() {
    echo "Usage: sudo bash $(basename $0) [2|o5|5|o6|ped] only ftp is [f5|fo]" "eg:  sudo  bash  $(basename $0)  o5  "
}

case $1 in
2)
    2lu
    ;;
o6)
    OeasyProxy
	face6
    ;;
o)
    OeasyProxy
    ;;
6)
    oeasyid
	face6
    ;;
ped)
    ped
    ;;
net)
	net
	;;
*)
    usage
    ;;
esac
