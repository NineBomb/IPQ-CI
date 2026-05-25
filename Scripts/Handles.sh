#!/bin/bash

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

ls -l 

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	echo " "

	HP_RULE="surge"
	HP_PATH="homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

#修改mini-diskmanager菜单位置
if [ -d *"luci-app-mini-diskmanager"* ]; then
	echo " " && cd ./luci-app-mini-diskmanager/

	sed -i "s/services/system/g" ./luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json

	cd $PKG_PATH && echo "mini-diskmanager has been fixed!"
fi

#修改qca-nss-drv启动顺序
NSS_DRV="../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then
	echo " "

	sed -i 's/START=.*/START=85/g' $NSS_DRV

	cd $PKG_PATH && echo "qca-nss-drv has been fixed!"
fi

#修改qca-nss-pbuf启动顺序
NSS_PBUF="./kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then
	echo " "

	sed -i 's/START=.*/START=86/g' $NSS_PBUF

	cd $PKG_PATH && echo "qca-nss-pbuf has been fixed!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	echo " "

	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale has been fixed!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust has been fixed!"
fi
#add
#修复KOD奇怪的依赖问题
if [ -d *"luci-app-kodexplorer"* ]; then
	echo " " && cd ./luci-app-kodexplorer/

	sed -i 's/+php8 \+//' $(find ./luci-app-kodexplorer/ -type f -name "Makefile") 

	cd $PKG_PATH && echo "KOD has been fixed!"
fi

#修复Kiddin9的adg无法正常install的问题（实际上是adg核心的init冲突但是adg核心的init确实不全）


sed -i '/\/etc\/init\.d/d' ../feeds/packages/net/adguardhome/Makefile

cd $PKG_PATH && echo "adg has been fixed!"

#move Passwall form services to VPN
if [ -d *"luci-app-passwall"* ]; then
	echo " " && cd ./luci-app-passwall/

	sed -i 's/services/vpn/g' $(find ./luci-app-passwall/ -type f -name "*lua")

	cd $PKG_PATH && echo "passwall has been fixed!"
fi


#move Alist from Services to NAS
if [ -d *"luci-app-alist"* ]; then
	echo " " && cd ./luci-app-alist/

	sed -i 's/services/nas/g' $(find ./luci-app-alist/ -type f -name "*json")

	cd $PKG_PATH && echo "alist has been fixed!"
fi

#move Oplist2 from Service to NAS
if [ -d *"luci-app-openlist2"* ]; then
	echo " " && cd ./luci-app-openlist2/

	sed -i 's/services/nas/g' $(find ./luci-app-openlist2/ -type f -name "*json")

	cd $PKG_PATH && echo "openlist2 has been fixed!"
fi

#move qB from Services to NAS
if [ -d *"luci-app-qbittorrent"* ]; then
	echo " " && cd ./luci-app-qbittorrent/

	sed -i 's/services/nas/g' $(find ./luci-app-qbittorrent/ -type f -name "*json")

	cd $PKG_PATH && echo "qb has been fixed!"
fi

