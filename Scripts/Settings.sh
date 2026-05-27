#!/bin/bash

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")


WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#修改WIFI地区
	sed -i "s/country='.*'/country='US'/g" $WIFI_UC
	#修改WIFI加密
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#无WIFI配置标志
if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
	echo "WRT_WIFI=wifi-no" >> $GITHUB_ENV
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	#设置NSS版本
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
	#其他调整
	echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> ./.config

	#无WIFI配置调整Q6大小
	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi
#add
#更新golang版本
rm -rf ./feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x ./feeds/packages/lang/golang

#修复speedtes-web无法编译缺少依赖问题
cp /usr/bin/upx ./staging_dir/host/bin/

#删除网络诊断（我真不觉得有人会用这个）
jq 'del(."admin/network/diagnostics")' ./feeds/luci/modules/luci-mod-network/root/usr/share/luci/menu.d/luci-mod-network.json > tmp.json \
&& mv ./tmp.json ./feeds/luci/modules/luci-mod-network/root/usr/share/luci/menu.d/luci-mod-network.json \
&& rm tmp.json
#删除插件（不知道主线搞了啥玩意儿反正没看出来用处）
jq 'del(."admin/system/plugins")' ./feeds/luci/modules/luci-mod-system/root/usr/share/luci/menu.d/luci-mod-system.json > tmp.json \
&& mv ./tmp.json ./feeds/luci/modules/luci-mod-system/root/usr/share/luci/menu.d/luci-mod-system.json \
&& rm tmp.json

# TTYD 免输入用户名
sed -i '/config ttyd/,/^config/ s|option command .*/bin/login.*|option command '\''/bin/login root'\''|' ./feeds/packages/utils/ttyd/files/ttyd.config


TARGET_CSS="./package/luci-theme-argon/htdocs/luci-static/argon/css/cascade.css"
TARGET="./feeds/luci/modules/luci-base/htdocs/luci-static/resources/luci.js"
TARGET_menu_argon="./package/luci-theme-argon/htdocs/luci-static/resources/menu-argon.js"


# 检查文件是否存在
[ ! -f "$TARGET_menu_argon" ] && { echo "[error] 找不到目标文件: $TARGET_menu_argon"; exit 1; }
# 检查是否已经修复过，防止重复编译时重复注入
grep -q "核心修复" "$TARGET_menu_argon" && { echo "[warn] menu-argon.js 已修复，跳过注入"; exit 0; }

# 使用 awk 精准注入修复代码 (兼容 GNU/BSD awk，无转义问题)
awk '!patched && /const currentHeight = element.scrollHeight;/ {
    print "            // 【核心修复】强制设置为 block，防止 CSS 隐藏导致 scrollHeight 为 0"
    print "            element.style.display = \"block\";"
    patched=1
}
{print}' "$TARGET_menu_argon" > "$TARGET_menu_argon.tmp" && mv "$TARGET_menu_argon.tmp" "$TARGET_menu_argon"
echo "[DONE] menu-argon.js 折叠动画 BUG 修复完成"


set -euo pipefail


# 定义唯一标识注释，用于检测是否已经添加过补丁
PATCH_MARKER="/* LUCI_SMOOTH_TRANSITION_PATCH_V1 */"

# 要追加的 CSS 补丁内容（已做适度换行以提高可读性，不影响CSS解析）
PATCH_CONTENT=$(cat <<'EOF'
/* LUCI_SMOOTH_TRANSITION_PATCH_V1 */
#view > .spinning,#maincontent > .spinning {display: none !important;height: 0 !important;opacity: 0 !important;pointer-events: none !important}
@keyframes viewSmoothEnter {from {opacity: 0;transform: translateY(6px)}to {opacity: 1;transform: translateY(0)}}
.view-wrapper.view-enter {animation: viewSmoothEnter 0.35s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards}
.cbi-section, .table, .cbi-map {transition: height 0.2s ease-out, opacity 0.2s ease-out}
.table .tr.placeholder .td,.cbi-section-table .tr.placeholder .td {color: transparent !important;background: linear-gradient(90deg, var(--background-color-medium) 25%, var(--background-color-low) 50%, var(--background-color-medium) 75%) !important;background-size: 200% 100% !important;animation: skeleton-pulse 1.5s infinite ease-in-out !important;border-radius: 4px;min-height: 24px}
@keyframes skeleton-pulse {0% { background-position: 200% 0}100% { background-position: -200% 0}}
:root[data-darkmode="true"] .table .tr.placeholder .td,:root[data-darkmode="true"] .cbi-section-table .tr.placeholder .td {background: linear-gradient(90deg, #2a2a2a 25%, #3a3a3a 50%, #2a2a2a 75%) !important;background-size: 200% 100% !important}
@media screen and (min-width: 769px) {#mainmenu {display: block !important;visibility: visible !important}}
#mainmenu .nav,#mainmenu .slide-menu {animation: menuFadeIn 0.15s ease-out forwards}
@keyframes menuFadeIn {from { opacity: 0; transform: translateX(-4px)}to { opacity: 1; transform: translateX(0)}}
.main-left {transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1), width 0.3s ease !important;visibility: visible !important;opacity: 1 !important}
.main-left .sidenav-header .brand,.main-left .sidenav-header .brand .logo {transition: color 0.4s ease, opacity 0.4s ease, filter 0.4s ease, transform 0.4s ease !important;text-rendering: optimizeLegibility;-webkit-font-smoothing: antialiased;-moz-osx-font-smoothing: grayscale}
.main-right {scrollbar-gutter: stable;overflow-y: auto}
.main-right::-webkit-scrollbar {width: 10px;background: transparent !important}
.main-right::-webkit-scrollbar-track {background: transparent !important}
.main-right::-webkit-scrollbar-thumb {background: var(--primary);border-radius: 10px;transition: background-color 0.3s ease}
.darkMask {transition: opacity 0.3s ease !important}
EOF
)

# 1. 检查目标文件是否存在，如果不存在则尝试创建
if [[ ! -f "$TARGET_CSS" ]]; then
    echo "[INFO] 目标文件不存在，正在尝试创建: $TARGET_CSS"
    mkdir -p "$(dirname "$TARGET_CSS")"
    touch "$TARGET_CSS"
fi

# 2. 幂等性检查：通过特征标记判断是否已添加
if grep -qF "$PATCH_MARKER" "$TARGET_CSS"; then
    echo "[SKIP] 补丁已存在于 $TARGET_CSS，无需重复添加。"
    exit 0
fi

# 3. 追加内容到文件末尾
# 先追加一个空行分隔，再追加补丁内容
echo "" >> "$TARGET_CSS"
echo "$PATCH_CONTENT" >> "$TARGET_CSS"

echo "[OK] 补丁已成功追加到: $TARGET_CSS"


if [[ ! -f "$TARGET" ]]; then
    echo "[ERROR] 文件不存在: $TARGET" >&2
    echo "[info] 请检查 LUCI_JS_PATH 是否正确。" >&2
    exit 1
fi

# 使用 Python3 进行精确的多行嵌套替换
python3 - "$TARGET" <<'PYEOF'
import sys, re
filepath = sys.argv[1]
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()
# 1) 定位 __name__: 'LuCI.view',
marker = "__name__: 'LuCI.view',"
marker_pos = content.find(marker)
if marker_pos == -1:
    print("[ERROR] 未找到 __name__: 'LuCI.view',", file=sys.stderr)
    sys.exit(1)
# 2) 在它之后定位 __init__() {
init_match = re.compile(r'__init__\(\)\s*\{').search(content, marker_pos)
if not init_match:
    print("[ERROR] 在 LuCI.view 中未找到 __init__()", file=sys.stderr)
    sys.exit(1)
start = init_match.start()
brace_pos = init_match.end() - 1  # '{' 的位置
# 3) 用括号深度计数找到匹配的 '}'（正确处理字符串/转义，防止误判）
depth = 0
pos = brace_pos
in_str = False
str_ch = None
esc = False
while pos < len(content):
    ch = content[pos]
    if esc:
        esc = False
    elif in_str:
        if ch == '\\':
            esc = True
        elif ch == str_ch:
            in_str = False
    else:
        if ch in ('"', "'", '`'):
            in_str = True
            str_ch = ch
        elif ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                end = pos + 1
                break
    pos += 1
if depth != 0:
    print("[ERROR] 未能找到 __init__() 的匹配右花括号", file=sys.stderr)
    sys.exit(1)
# 4) 新的 __init__() 实现（严格按照你提供的代码和缩进）
new_init = """__init__() {
\t\tconst vp = document.getElementById('view');
\t\tif (vp) {vp.style.pointerEvents = 'none';}
\t\tconst ready = L.loaded? Promise.resolve() : new Promise((resolve) => {document.addEventListener('luci-loaded', resolve, { once: true });});
\t\treturn ready
\t\t\t.then(LuCI.prototype.bind(this.load, this))
\t\t\t.then(LuCI.prototype.bind(this.render, this))
\t\t\t.then(LuCI.prototype.bind(function(nodes) {
\t\t\t\tconst vp = document.getElementById('view');
\t\t\t\tconst wrapper = E('div', { 'class': 'view-wrapper' }, [nodes, this.addFooter()]);
\t\t\t\twrapper.style.opacity = '0';
\t\t\t\twrapper.style.display = 'block';
\t\t\t\tDOM.content(vp, wrapper);
\t\t\t\tvoid wrapper.offsetHeight;
\t\t\t\tif (vp) vp.style.pointerEvents = '';
\t\t\t\trequestAnimationFrame(() => {requestAnimationFrame(() => {wrapper.classList.add('view-enter');});});}, this)).catch(LuCI.prototype.bind(function(err) {
\t\t\t\tconst vp = document.getElementById('view');
\t\t\t\tif (vp) vp.style.pointerEvents = '';
\t\t\t\tLuCI.prototype.error(err);
\t\t\t}, this));
\t}"""
# 5) 替换并写回
new_content = content[:start] + new_init + content[end:]

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"[DONE] 已替换 __init__()")
PYEOF

# 幂等检查：如果已存在补丁特征字符串，直接跳过
if grep -qF "env.apply_rollback = 60" "$TARGET"; then
    echo "[SKIP] 补丁已存在于 $TARGET，无需重复添加。"
    exit 0
fi

# 使用 Python3 进行精确插入
python3 - "$TARGET" <<'PYEOF'
import sys

filepath = sys.argv[1]

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1) 定位锚点
anchor = "Object.assign(env, setenv);"
anchor_pos = content.find(anchor)
if anchor_pos == -1:
    print("[ERROR] 未找到锚点: Object.assign(env, setenv);", file=sys.stderr)
    sys.exit(1)

# 2) 检测锚点所在行的缩进（兼容 Tab 或空格）
line_start = content.rfind('\n', 0, anchor_pos) + 1
indent = ''
for ch in content[line_start:anchor_pos]:
    if ch in (' ', '\t'):
        indent += ch
    else:
        break

# 3) 构造要插入的代码块（前后保留空行，与原代码风格一致）
patch_lines = [
    "if (typeof env.apply_rollback === 'number') env.apply_rollback = 60;",
    "if (typeof env.apply_holdoff === 'number')  env.apply_holdoff  = 2;",
    "if (typeof env.apply_timeout === 'number')  env.apply_timeout  = 10;",
    "if (typeof env.apply_display === 'number')  env.apply_display  = 1;",
]
patch = "\n\n" + "\n".join(indent + line for line in patch_lines) + "\n"

# 4) 在锚点结束位置插入
insert_pos = anchor_pos + len(anchor)
new_content = content[:insert_pos] + patch + content[insert_pos:]

# 5) 写回文件
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"[OK] 已成功插入 4 行环境参数覆盖代码")
print(f"     检测到缩进: {repr(indent)}")
PYEOF

echo "[DONE] 修改完成: $TARGET"

