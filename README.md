<h1 align="center">:package:自用IPQ系列固件云编译版本</h1>
本项目基于V佬的
https://github.com/VIKINGYFY/OpenWRT-CI.git
修改而来感谢原作者以及其他开发者对IPQ系列设备的无私贡献！

# 自定义修改部分
- 待修改的部分
1. 修复某些界面可能无法应用平滑
2. argon-config无网访问速度优化
- 26.5.27
1. 修复Argon主题折叠菜单BUG（当前使用的版本）
2. 刷新页面后首次选择不同的折叠菜单动画会失效，已通过补丁解决
3. luci界面如果不联网会无法启用缓存机制，导致加载缓慢，请联网或者同步时间
- 26.5.26
1. 继续修复部分本地迁移云端的小BUG
2. 修改ssh连接文字LOGO为A U OK（等哪天想搞了再改成R U OK）
3. 修改插件应用最小等待时间和默认等待时间以及超时时间
- 26.5.25
1. 更新Argon主题源码，原先的不是很成功，界面比较无法理解
2. 解决部分修改从本地编译迁移云编译时出现的异常
- 26.5.24
1. 对Luci主题Argon进行大补丁修改，解决了视觉上闪烁和不连续等很多问题
2. 由于修改了luci.js内的部分逻辑，更换未修改css的主题将导致异常
3. 其他主题可以自行尝试使用同样的补丁脚本进行修改，本着实用原则暂时只改了Argon主题
- 26.5及之前累计修改
1. 添加speedtest-web方便内网测速使用同时解决其编译报错问题
2. 移除luci-app-attendedsysupgrade个人觉得对于会编译固件的玩家不需要这个
3. TTYD免输入用户名登陆，提升使用体验
4. 删除网络诊断，插件 属于完全没用的功能了
5. 修复可到云和adg的奇怪问题（可能是源码导致的）
6. 将qb，alist，openlist移动至NAS分组，符合实际情况
7. 将passwall移动至VPN分组，符合实际情况





<h1 align="center">以下来自https://github.com/VIKINGYFY/OpenWRT-CI.git</h1>

# OpenWRT-CI

官方版：

https://github.com/immortalwrt/immortalwrt.git

自用版：

https://github.com/VIKINGYFY/immortalwrt.git

# U-BOOT

高通版-沉心：

https://github.com/chenxin527/uboot-ipq60xx-emmc-build.git

https://github.com/chenxin527/uboot-ipq60xx-nand-build.git

https://github.com/chenxin527/uboot-ipq60xx-nor-build.git

高通版-小猪：

https://github.com/1980490718/u-boot-2016.git

联发科-全新版：

https://github.com/VIKINGYFY/UBOOT-CI/releases

联发科-官方版：

https://drive.wrt.moe/uboot/mediatek

# 目录简要说明

workflows——自定义CI配置

Scripts——自定义脚本

Config——自定义配置
