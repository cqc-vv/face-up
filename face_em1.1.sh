#!/bin/bash

#=================================================
#	System Required: Ubuntu
#	Description: OeasyProxy，face_node_v6.1
#	Version: 1.0.0
#=================================================

#环境变量
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Home=/home/oeasy
File="/home/oeasy/OeasyProxy"
File1=`ls /home/oeasy/face_node*/conf`
oeasycfg="/home/oeasy/OeasyProxy/oeasycfg.ini"
Free=`free -g |gawk '/Mem/{print $2}'`
sh_ver="1.0.0"

#检查权限
[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1



#检查网络状态
check_network(){
ping -c 2 www.baidu.com > /dev/null 2>&1
if [ $? != 0 ];then
echo -e ${Error} 不通外网（请执行选项6修改服务器IP）
exit 1
fi
}

#算法版本检查
check_fversion(){
if [[ -d /home/oeasy/face_node_v6.1 ]]; then
        Fversion1=${Green_font_prefix}已是最新版本${Font_color_suffix}
else
        Fversion1=${Red_font_prefix}版本可更新${Font_color_suffix}
fi
}

#更改服务器ID
Change_ID(){
echo && stty erase '^H' && read -p "请输入小区号:" Area
sed -r -i '1,20s!(area =)[^*]*!\10000000000,000000'$Area'!'  ${Home}/${newface}/conf/face_compare_server.conf

if [[ -d $File ]];then
	sed -r -i '1,$s!(proxyId=)[^*]*!\1000000'$Area'!' $oeasycfg

fi
}

#重置算法特征
Refeature(){
killall python
rm -f $HOME/face_node_*/face_compare_server/facefeature.db
}

#检查代理程序进程
check_proxy_pid(){
	PID=$(ps -ef| grep "OeasyProxy"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}')
}

#检查算法程序进程
check_face_pid(){
	FID=$(ps -ef| grep "python"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}')
}


#配置代理文件
Proxy_conf(){
SXT=`cat /home/oeasy/OeasyProxy/oeasycfg.ini|grep -B2 log |grep size=*`
echo && stty erase '^H' && read -p "请输入小区ID" OID
sed -r -i '1,$s!(proxyId=)[^*]*!\1000000'$OID'!' /home/oeasy/OeasyProxy/oeasycfg.ini
echo "初始化摄像头参数"
echo && stty erase '^H' && read -p "请输入外置摄像头数量:" A
sed -i '/username/{n;s/'$SXT'/size='$A'/;}' /home/oeasy/OeasyProxy/oeasycfg.ini
#sed -i s/$SXT/size=$A/g /home/oeasy/OeasyProxy/oeasycfg.ini
killall OeasyProxy UploadOpenDoorInfor
echo ”重置配置文件中，请稍等...“
sleep 10s
echo "重启完成"
}

#安装cudnn补丁
cudnn(){
cdnn=`cat /usr/local/cuda/include/cudnn.h | grep "define CUDNN_MAJOR" | awk '{print $3}'`
if [[ $cdnn != 6 ]] && [[ ! -f "/home/oeasy/libcudnn6_6.0.21-1+cuda8.0_amd64.deb" ]] ;then
	cd ${Home}/
	#wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn6_6.0.21-1%2Bcuda8.0_amd64.deb
	#wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn6-dev_6.0.21-1%2Bcuda8.0_amd64.deb
	wget 115.231.181.22:81/oeasy_soft/libcudnn6_6.0.21-1+cuda8.0_amd64.deb --user oeasy --password oeasy123
    wget 115.231.181.22:81/oeasy_soft/libcudnn6-dev_6.0.21-1+cuda8.0_amd64.deb  --user oeasy --password oeasy123

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

#安装pip依赖
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

#2路pip依赖
2lpip(){
	echo -e "${Red_font_prefix} 软件安装中(第一次安装大约半小时左右),请耐心等待 ${Font_color_suffix}"
	pip install grpcio==1.12.1 grpcio-tools==1.12.1 easydict paho-mqtt numpy==1.14.5  timeout-decorator requests==2.18.1 sysv_ipc -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com -q 
	killall python python3 python2.7 > /dev/null 2>&1
	echo -e "${Green_font_prefix} 软件安装完成 ${Font_color_suffix}"
	apt install dos2unix -y > /dev/null 2>&1
}

#配置IP地址
Network() {
#get iface
iface=$(ip route | grep default | awk '{print $5}' | head -1)

ping -c 2 www.baidu.com > /dev/null 2>&1
if [ $? = 0 ];then
		NETMASK=`ifconfig | grep "Mask" | gawk '{print $4}' | sed 's/Mask://g' | sed -n "1p"`
		GATEWAY=$(route -n | grep $iface | awk '{print $2}' | head -1)
		echo && stty erase '^H' && read -p "请输入需要固定的ip:"  IP
else
		echo && stty erase '^H' && read -p "请输入需要固定的ip:"  IP
		echo && stty erase '^H' && read -p "请输入子网掩码:" NETMASK 
		echo && stty erase '^H' && read -p "请输入网关:" GATEWAY
		#echo && stty erase '^H' && read -p "请输入DNS:" DNS
fi

sed -i '/^address/,$d'  /etc/network/interface

	for i in $IP $NETMASK $GATEWAY; do
echo $i | grep -P  "(\d+\.){3}\d+" > /dev/null
if [ $? -ne 0 ]; then
        echo -e "\033[31m IP、掩码、网关错误,请重新运行脚本 \033[0m"
        exit
fi
done
	
if [[ -d /usr/local/cuda ]] || [[ ${Free} -gt 6 ]];then
		cat >>/etc/network/interfaces  <<EOF
address $IP
netmask $NETMASK
gateway $GATEWAY
dns-nameserver 114.114.114.114
EOF
	/etc/init.d/networking restart

else
	#write to file
	cat > interfaces <<__EOF__
auto lo
iface lo inet loopback

auto $iface
iface $iface inet static
	address $IP
	netmask $NETMASK
	gateway $GATEWAY
	dns-nameservers 114.114.114.114
__EOF__

	sudo mv interfaces /etc/network
	rm -rf /etc/resolv.conf
	sed -i "/^exit/i\echo \"nameserver 114.114.114.114 \" > /etc/resolv.conf" /etc/rc.local
	echo "nameserver 114.114.114.114" > /etc/resolv.conf
	
	ping -c 2 www.baidu.com > /dev/null 2>&1
	if [ $? != 0 ];then
		echo "外网不通"
		exit 7
	fi

	#stop NetworkManager server
	systemctl stop NetworkManager
	systemctl disable NetworkManager
	
fi
}



#安装算法
Install_face(){
newface=face_node_v6.1
if [ -d ${Home}/${newface} ];then
	cd  ${Home}/${newface}
	svn up
	echo ${Green_font_prefix} "当前算法已是最新版本"${Font_color_suffix}
else
	echo && stty erase '^H' && read -p "请输入小区号:" Area
	cd ${Home}/
	rm -rf face_node*
	svn  co svn://zimg.0easy.com/face_node/face_node_v6/face_node_v6.1
	#wget http://115.231.181.22:81/oeasy_soft/face_node_v6.1.tar.gz --user oeasy --password oeasy123
	#tar -xvf face_node_v6.1.tar.gz
     wget  http://115.231.181.22:81/oeasy_soft/models.tar.gz --user oeasy --password oeasy123
	 tar -xvf models.tar.gz
	cp -r ${Home}/models/* ${Home}/${newface}/oeasy_face_lib/
	chown oeasy.oeasy ${Home}/${newface} -R

if [[ -d /usr/local/cuda ]] || [[ ${Free} -gt 6 ]];then
	cudnn
	pipyuan
	GTX=`nvidia-smi |grep GTX | gawk '{print $5}'  | cut -c1-3`
	if [  -d /etc/version ];then
	lu=`cat /etc/version`
	sed -r -i '1,10s!(user_max_num  = )[^*]*!\1$lu!'  ${Home}/${newface}/conf/face_compare_server.conf
	elif	[ ${GTX} -eq 106 ];then
        sed -r -i '1,10s!(user_max_num  = )[^*]*!\110!'  ${Home}/${newface}/conf/face_compare_server.conf
		elif	[ ${GTX} -eq 105 ];then
        sed -r -i '1,10s!(user_max_num  = )[^*]*!\16!'  ${Home}/${newface}/conf/face_compare_server.conf
			elif	[ ${GTX} -eq 165 ];then
		sed -r -i '1,10s!(user_max_num  = )[^*]*!\16!'  ${Home}/${newface}/conf/face_compare_server.conf
				fi
	echo "======== upgrade face for 6 server success =========="
	else
	2lpip
	fi
fi
# set area id

sed -r -i '1,20s!(area =)[^*]*!\10000000000,000000'$Area'!'  ${Home}/${newface}/conf/face_compare_server.conf
# service daemon
   cd ${Home}/${newface}/face_compare_server/services
   cp *service /etc/systemd/system
	systemctl daemon-reload
	killall python
# start service
	for item in face_compare.service face_detect.service face_lbs.service; do systemctl enable $item;systemctl start ${item};done
}

#安装代理
Install_Proxy(){
if [[ ! -d /usr/local/cuda ]] || [[ ${Free} -le 6 ]];then
	echo -e "2路服务器不可以安装代理服务"
exit 1
fi

cd ${File}
svn info | grep OeasyProxy_4.X
if [[ $? = 0 ]];then
	svn up
else
	cd ${Home}/
	svn co svn://zimg.0easy.com/OeasyProxy_4.X
	#wget http://115.231.181.22:81/oeasy_soft/OeasyProxy_4.X.zip --user oeasy --password oeasy123
	unzip OeasyProxy_4.X.zip
	echo 'oeasy' | sudo -S /etc/init.d/oproxy stop
	mv ${File}  ${File}3b
	mv ${File}_4.X  ${File}
	hh=`cat /home/oeasy/OeasyProxy/oeasycfg.ini | grep -n "\[log\]" |awk -F: '{print $1}'`
    size=`cat /home/oeasy/OeasyProxy/oeasycfg.ini |grep size| grep -v channel |awk -F= 'NR==2{print $2}'`
	size1=`cat /home/oeasy/OeasyProxy3b/oeasycfg.ini|grep size| grep -v channel |awk -F= 'NR==2{print $2}'`
	let hhh=hh-3
	sed -i ''$hhh','$hh's!size='$size'!size='$size1'!g'  ${oeasycfg}
fi

echo 'oeasy' | sudo -S sed -r -i '1,80s!(//)[^:]*(:9317)!\1127.0.0.1\2!' ${oeasycfg}
rm -rf /etc/systemd/system/OeasyProxy.service
rm -rf /etc/systemd/system/UploadOpenDoorInfor.service
cp ${File}/OeasyProxy.service  /etc/systemd/system/OeasyProxy.service
cp ${File}/UploadOpenDoorInfor.service /etc/systemd/system/UploadOpenDoorInfor.service

for it in OeasyProxy.service UploadOpenDoorInfor.service ; do systemctl enable $it;systemctl start $it;done
systemctl daemon-reload
killall OeasyProxy UploadOpenDoorInfor
sleep 10

chmod 775 ${File}/OeasyProxy
chmod 775 ${File}/UploadOpenDoorInfor

# set OeasyProxy id

if [[ -d "/home/oeasy/OeasyProxy3b" ]];then
		area_id=`cat  /home/oeasy/OeasyProxy3b/oeasycfg.ini  | grep proxyId= | awk -F"000000" '{print $2}'`
		sed -r -i '1,$s!(proxyId=)[^*]*!\1000000'$area_id'!'  ${oeasycfg}
		echo 'oeasy' | sudo -S sed -r -i '1,'$hh's!(//)[^:]*(:9317)!\1127.0.0.1\2!' ${oeasycfg}		
		k=1
		hhj=`cat ${oeasycfg} | grep -n size= | grep -v channel |awk -F: 'NR==2{print $1}'`
		#1eed1901143d 192.168.5.99 oeasy123
cat ${File}3b/oeasycfg.ini | grep -e ip= -e Mac -e pass -e cameraId= -e NVRChannel=| awk -F= '{print $2}' | awk '{if(NR%5!=0)ORS=" ";else ORS="\n"}1'| while read line
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



sed -r -i '1,$s!(proxyId=)[^*]*!\1000000'$area_id'!'  ${oeasycfg}
nv=`cat /home/oeasy/OeasyProxy3b/oeasycfg.ini  | grep IsUseNvr= | awk -F= '{print $2}'`
if [[ $nv = true ]];then
			sed -r -i '1,$s!(IsUseNvr=)[^*]*!\11!'  ${oeasycfg}
			killall OeasyProxy
			sleep 6
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
cp ${File}3b/oeasycfg.ini  ../oeasycfg.ini3b
rm -rf ${File}3b
chown oeasy.oeasy ${File}/ -R
rm -rf  /etc/init.d/multiobj  /etc/init.d/oproxy  /etc/init.d/veriface
echo "======== upgrade OeasyProxy server success =========="
}


#卸载重装算法
Rinstall_face(){
for item in face_compare.service face_detect.service face_lbs.service; do systemctl stop $item;done
cd $HOME
rm -rf face_node_*
Install_face
}


op(){
infor=/home/oeasy/pz
area_id=`cat ${infor}  | grep id | awk -F":" '{print $2}'`
hh=`cat /home/oeasy/OeasyProxy/oeasycfg.ini | grep -n "\[log\]" |awk -F: '{print $1}'`
let size=`cat ${infor} | grep -v "#" |grep -v // |grep -v nvr| grep [a-zA-Z] |wc -l`-1
	let hhh=hh-3
	sed -r -i ''$hhh','$hh's!(size=)[^*]*!\1'$size'!g'  ${oeasycfg}	
	killall OeasyProxy
	sleep 20
		
		sed -r -i '1,$s!(proxyId=)[^*]*!\100000'$area_id'!'  ${oeasycfg}
		echo 'oeasy' | sudo -S sed -r -i '1,'$hh's!(//)[^:]*(:9317)!\1127.0.0.1\2!' ${oeasycfg}		
		k=1
		#id=0
		hhj=`cat ${oeasycfg} | grep -n size= | grep -v channel |awk -F: 'NR==2{print $1}'`

cat ${infor} | grep -v "#" | grep -v ":" |grep -v // |grep -v nvr | grep [a-zA-Z]| while read line
do
			
			
			mac=$(echo $line |awk '{print $3}')
			ip=$(echo $line |awk '{print $1}')
			passwaed=$(echo $line |awk '{print $2}')
			#user=$(echo $line |awk '{print $2}')
			nc=$(echo $line |awk '{print $4}')
			let nt=$nc-1
			tp=$(echo $line |awk '{print $6}')
			id=$(echo $line |awk '{print $5}')
			sed -r -i '1,'$hhj's!('$k'\\ip=)[^*]*!\1'$ip'!'  ${oeasycfg}
			sed -r -i '1,$s!('$k'\\channels\\1\\NVRChannel=)[^*]*!\1'$nt'!'  ${oeasycfg}
			sed -r -i '1,$s!('$k'\\channels\\1\\cameraId=)[^*]*!\1'$id'!'  ${oeasycfg}
			sed -r -i '1,$s!('$k'\\channels\\1\\intercomMac=)[^*]*!\1'$mac'!'  ${oeasycfg}
			sed -r -i '1,$s!('$k'\\password=)[^*]*!\1'$passwaed'!'  ${oeasycfg}
			#sed -r -i '1,$s!('$k'\\username=)[^*]*!\1'$user'!'  ${oeasycfg}
			sed -r -i '1,$s!('$k'\\channels\\1\\vendorType=)[^*]*!\1'$tp'!'  ${oeasycfg}
			k=$(expr $k + 1)
			#let id=id+1
 done

#写入nvr配置
nv=`cat ${infor}  | grep -w "nvr"| awk -F: '{print $2}'`
if [[  -n "$nv" ]];then
			sed -r -i '1,$s!(IsUseNvr=)[^*]*!\11!'  ${oeasycfg}
			killall OeasyProxy
			sleep 3

			hh1=`cat ${oeasycfg} | grep -n size= | grep -v channel |awk -F: 'NR==3{print $1}'`
			hh2=`grep -n 'nvr' ${oeasycfg} |awk -F":" '{print $1}'`
			let nvrh=hh1-hh2
			j=1
			cat ${infor}  | grep -w "nvr" |grep -v "#" | awk -F: '{print $2}'| while read line
			do
			#nvrs=$(echo $line |awk '{print $1}')
			nvr=$(echo $line |awk '{print $1}')
			nvrp=$(echo $line |awk '{print $2}')
			#sed -r -i ''$hh2','$hh1's!('$j'\\IPChanNum=)[^*]*!\1'$nvrs'!'  ${oeasycfg}
			sed -r -i ''$hh2','$hh1's!('$j'\\ip=)[^*]*!\1'$nvr'!'  ${oeasycfg}
			sed -r -i ''$hh2','$hh1's!('$j'\\password=)[^*]*!\1'$nvrp'!'  ${oeasycfg}
			j=$(expr $j + 1)
			done
fi 

#配置尾随
sed -r -i 's!(TailRoiX=)[^*]*!\10.2!g'  ${oeasycfg}
sed -r -i 's!(TailRoiY=)[^*]*!\10.2!g'  ${oeasycfg}
sed -r -i 's!(TailRoiHeight=)[^*]*!\10.8!g'  ${oeasycfg}
sed -r -i 's!(TailRoiWidth=)[^*]*!\10.8!g'  ${oeasycfg}	
sed -r -i 's!(alarm_distance=)[^*]*!\10.8!g'  ${oeasycfg}

killall OeasyProxy UploadOpenDoorInfor
for item in face_compare.service face_detect.service face_lbs.service; do systemctl restart $item;done
Refeature
}

example(){
echo "
自动配置文件格式示例
#小区号（五位数）
id:09999
#摄像头数据
ip地址 摄像头密码 对讲mac地址 nvr通道号 摄像头编号号 摄像头类型（1多目标，2人脸，3多目标+人脸）
192.168.1.2 test1 2eed1919191 2 0000 2
192.168.1.3 test2 2eed1919191 2	0001 2
192.168.1.4 test3 2eed1919192 2	0002 2
192.168.1.5 test3 2eed1919193 3 0002 3
192.168.1.6 test3 2eed1919194 3 0002 3
192.168.1.7 test3 2eed1919196 3 0002 3
#NVRIP地址 NVR密码
nvr:19.6.6.6 kkkkkkk
"
}

oeasy_conf(){
clear
ID=$(grep proxyId /home/oeasy/OeasyProxy/oeasycfg.ini | grep -Eo '[0-9]{4}$')
IP=$(ip a | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}" | head -2 | tail -1)
netMac=$(ip a | grep ether | awk '{print $2}')
phoneNum=$(grep NVRC /home/oeasy/OeasyProxy/oeasycfg.ini  | wc -l)
#phonePasswd=$(grep pass /home/oeasy/OeasyProxy/oeasycfg.ini | awk -F'=' '{print $2}' | tail -1)

rm -fr tower
if [ ! -f /home/oeasy/OeasyProxy/oeasycfg.ini ];then
	echo "代理不存在"
	exit 1
fi

#基本信息
cat >tower <<EOF
小区号：$ID
服务器信息：
人脸识别服务器IP:$IP   网卡mac：$netMac
OeasyProxy代理IP:$IP
用户名/密码:oeasy/oeasy

摄像头信息：
外置摄像头数量：$phoneNum
EOF

#摄像头信息
for i in $(seq 1 $phoneNum);do
	phoneIp=$(grep ip= /home/oeasy/OeasyProxy/oeasycfg.ini | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -$i | tail -1)
	MAC=$(grep Mac /home/oeasy/OeasyProxy/oeasycfg.ini | grep -Eo [0-9a-z]{11} | head -$i | tail -1)
	TYPE=$(grep vendorType /home/oeasy/OeasyProxy/oeasycfg.ini |grep channels | awk -F'=' '{print $2}' | head -$i | tail -1)
	sxtid=$(grep cameraId= /home/oeasy/OeasyProxy/oeasycfg.ini | awk -F'=' '{print $2}' | head -$i | tail -1)
	phonePasswd=$(grep pass /home/oeasy/OeasyProxy/oeasycfg.ini | awk -F'=' '{print $2}' | head -$i | tail -1)
	if [ $TYPE == 1 ];then
		echo "摄像头$i IP:$phoneIp  （多目标）摄像头ID:$sxtid  密码:$phonePasswd" >> tower
	elif [ $TYPE == 2 ];then
		echo "摄像头$i IP：$phoneIp (人脸识别) 摄像头ID:$sxtid 密码:$phonePasswd" >> tower
		echo "MAC:$MAC" >> tower
	elif [ $TYPE == 3 ];then
                echo "摄像头$i IP：$phoneIp (人脸识别+多目标) 摄像头ID:$sxtid 密码:$phonePasswd" >> tower
                echo "MAC:$MAC" >> tower
	else
		echo "摄像头$i IP：$phoneIp (只做监控) 摄像头ID:$sxtid 密码:$phonePasswd" >> tower
	fi
	
done

#echo "用户名：admin" >> tower
#echo "密码:$phonePasswd" >> tower



#nvr信息
IsUseNvr=$(grep IsUseNvr= /home/oeasy/OeasyProxy/oeasycfg.ini | awk -F'=' '{print $2}')
if [ $IsUseNvr == false ];then
	echo "NVR信息:无"
else
	nvrIp=$(grep ip= /home/oeasy/OeasyProxy/oeasycfg.ini | tail -1 | awk -F'=' '{print $2}')
	nvrPasswd=$(grep pass /home/oeasy/OeasyProxy/oeasycfg.ini | tail -1 | awk -F'=' '{print $2}')
	cat >> tower <<EOF

NVR信息：
NVR IP:$nvrIp
用户名：admin
密码：$nvrPasswd
EOF
fi

echo "其他:" >> tower
cat tower

}

#系统状态检查
system_check(){
clear
da=$(date "+%Y-%m-%d")
#网络
ping -c 2 www.baidu.com > /dev/null 2>&1
if [ $? != 0 ];then
	echo -e ${Error} 不通外网（请执行选项6修改服务器IP）
	else
	wl=$(cat /etc/network/interfaces |grep static |awk '{print $4}')
	if [[ "$wl" -eq static ]];then
	echo -e "通外网,ip地址已固定"
	else
	echo -e "通外网,ip地址未固定"
	fi
fi

#判断显卡是否连接正常
nvidia-smi > /dev/null 2>&1
#lspci | grep -i vga | grep NVIDIA
if [ $? = 0 ];then
    echo "显卡在线"
else
    echo -e "\033[31m显卡不在线，需要断电，拔插一下显卡并检查显卡电源线是否连好. \033[0m"
fi

#判断代理程序状态
if [[ -e ${File} ]]; then
	check_proxy_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e "当前代理状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e "当前代理状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e "当前代理状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi

#判断算法程序状态
if [[ -n ${File1} ]]; then
	check_fversion
	check_face_pid
	if [[ ! -z "${FID}" ]]; then
		echo -e "当前算法状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}  $Fversion1"
	else
		echo -e "当前算法状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}  $Fversion1"
	fi
else
	echo -e "当前算法状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi

#硬盘检查
yp=$(df | grep '/$'| awk '{print $(NF-1)}' | awk -F'%' '{print $1}')
if [[ "$yp" -ge 80 ]];then
	yp1="${Red_font_prefix}硬盘已满${Font_color_suffix}"
	fi
echo -e $da  "硬盘使用率$yp% $yp1"

}

#手动增加摄像头
misxt(){
phoneNum=$(grep NVRC /home/oeasy/OeasyProxy/oeasycfg.ini  | wc -l)
echo 目前已配置好$phoneNum个摄像头
echo && stty erase '^H' && read -p "请输入本次要增加的摄像头数量:" sxtsl
hh=`cat /home/oeasy/OeasyProxy/oeasycfg.ini | grep -n "\[log\]" |awk -F: '{print $1}'`
let hhh=hh-3
let pzsxt=$phoneNum+$sxtsl
sed -r -i ''$hhh','$hh's!(size=)[^*]*!\1'$pzsxt'!g'  ${oeasycfg}	
killall OeasyProxy
sleep 20
let sxtcs=$phoneNum+1
for i in  $(seq 1 $sxtsl);do
	hhj=`cat ${oeasycfg} | grep -n size= | grep -v channel |awk -F: 'NR==2{print $1}'`
	echo && stty erase '^H' && read -p "摄像头ip:" rxtip
	echo && stty erase '^H' && read -p "$rxtip摄像头密码:" rxtpa
	echo && stty erase '^H' && read -p "$rxtip对讲mac地址:" rxtmac
	echo && stty erase '^H' && read -p "$rxtip摄像头ID:" rxtid
	echo && stty erase '^H' && read -p "$rxtip摄像头功能（1只抓拍、2人脸识别、3多目标）:" rxtgn
	sed -r -i '1,'$hhj's!('$sxtcs'\\ip=)[^*]*!\1'$rxtip'!'  ${oeasycfg}
	sed -r -i '1,$s!('$sxtcs'\\password=)[^*]*!\1'$rxtpa'!'  ${oeasycfg}
	sed -r -i '1,$s!('$sxtcs'\\channels\\1\\intercomMac=)[^*]*!\1'$rxtmac'!'  ${oeasycfg}
	sed -r -i '1,$s!('$sxtcs'\\channels\\1\\cameraId=)[^*]*!\1'$rxtid'!'  ${oeasycfg}
	sed -r -i '1,$s!('$sxtcs'\\channels\\1\\vendorType=)[^*]*!\1'$rxtgn'!'  ${oeasycfg}
	let sxtcs=sxtcs+1
done
killall OeasyProxy
sleep 10
echo -e "${Green_font_prefix} 配置完成 ${Font_color_suffix}"
}


#手动配置nvr
nvr_conf(){
phoneNum=$(grep NVRC /home/oeasy/OeasyProxy/oeasycfg.ini  | wc -l)
k=1
for i in $(seq 1 $phoneNum);do
	phoneIp=$(grep ip= /home/oeasy/OeasyProxy/oeasycfg.ini | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -$i | tail -1)
	echo && stty erase '^H' && read -p "请输入$phoneIp摄像头nvr通道号:" tdh
	sed -r -i '1,$s!('$k'\\channels\\1\\NVRChannel=)[^*]*!\1'$tdh'!'  ${oeasycfg}
	k=$(expr $k + 1)
done
echo && stty erase '^H' && read -p "请输入NVRIP:"  nvrip
echo && stty erase '^H' && read -p "请输入NVR密码:"  nvrpas
sed -r -i '1,$s!(IsUseNvr=)[^*]*!\11!'  ${oeasycfg}
killall OeasyProxy
sleep 3
hh1=`cat ${oeasycfg} | grep -n size= | grep -v channel |awk -F: 'NR==3{print $1}'`
hh2=`grep -n 'nvr' ${oeasycfg} |awk -F":" '{print $1}'`
let nvrh=hh1-hh2
j=1
sed -r -i ''$hh2','$hh1's!('$j'\\ip=)[^*]*!\1'$nvrip'!'  ${oeasycfg}
sed -r -i ''$hh2','$hh1's!('$j'\\password=)[^*]*!\1'$nvrpas'!'  ${oeasycfg}
killall OeasyProxy
sleep 3
echo -e "${Green_font_prefix} 配置完成 ${Font_color_suffix}"
}

#管理外置摄像头
Oeasy_config(){
if [[ -e ${File} ]]||[[ -e ${File1} ]];then
	echo && echo -e "你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix}  新增摄像头
 ${Green_font_prefix}2.${Font_color_suffix}  按文件自动配置
 ${Green_font_prefix}3.${Font_color_suffix}  手动添加NVR（要求已配置好摄像头）
 ${Green_font_prefix}4.${Font_color_suffix}  查看目前外置摄像头配置
 ${Green_font_prefix}5.${Font_color_suffix}  查看自动配置文件格式"&& echo
	read -e -p "(请选择):" gf_modify
	[[ -z "${gf_modify}" ]] && echo "已取消..." && exit 1
	if [[ ${gf_modify} == "1" ]]; then
		oeasy_conf
		misxt
		oeasy_conf
	elif [[ ${gf_modify} == "2" ]]; then
		op
		oeasy_conf
	elif [[ ${gf_modify} == "3" ]]; then
		nvr_conf
	elif [[ ${gf_modify} == "4" ]]; then
		oeasy_conf
	elif [[ ${gf_modify} == "5" ]]; then
		example
	else
		echo -e "${Error} 请输入正确的数字(1-6)" && exit 1
	fi
fi
}

#操作说明
echo && echo -e "  oeasy人脸服务器一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- 如执行期间有问题请联系工作人员 --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装或升级人脸算法程序
 ${Green_font_prefix} 2.${Font_color_suffix} 安装或升级摄像头代理程序
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载重装人脸算法识别程序
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 检查系统状态
 ${Green_font_prefix} 5.${Font_color_suffix} 管理外置摄像头
 ${Green_font_prefix} 6.${Font_color_suffix} 修改服务器IP
————————————" && echo

#判断代理程序状态
if [[ -e ${File} ]]; then
	check_proxy_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前代理状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前代理状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前代理状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi

#判断算法程序状态
if [[ -n ${File1} ]]; then
	check_fversion
	check_face_pid
	if [[ ! -z "${FID}" ]]; then
		echo -e " 当前算法状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}  $Fversion1"
	else
		echo -e " 当前算法状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}  $Fversion1"
	fi
else
	echo -e " 当前算法状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi

echo
read -e -p " 请输入数字 [0-10]:" num
case "$num" in
	0)
	check_network
	Update_Shell
	;;
	1)
	check_network
	Install_face
	;;
	2)
	check_network
	Install_Proxy
	;;
	3)
	check_network
	Rinstall_face
	;;
	4)
	system_check
	;;
	5)
	Oeasy_config
	;;
	6)
	Network
	;;
	*)
	echo "请输入正确数字 [0-10]"
	;;
esac
