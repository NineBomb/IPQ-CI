#!/bin/bash
#安装和更新软件包
UPDATE_PACKAGE() {
    # ==================== 参数定义 ====================
    local PKG_NAME="${1}"           # [必填] 目标软件包名称
    local PKG_REPO="${2}"           # [必填] GitHub 仓库路径 (user/repo)
    local PKG_BRANCH="${3}"         # [必填] Git 分支名称
    local PKG_SPECIAL="${4:-}"      # [可选] 特殊模式: pkg / name / 空
    local PKG_EXTRA_KEYWORDS="${5:-}" # [可选] 额外搜索关键词（空格分隔）
    
    local REPO_NAME="${PKG_REPO#*/}"
    local PKG_LIST=("${PKG_NAME}")
    
    # ==================== 参数校验 ====================
    if [[ -z "${PKG_NAME}" || -z "${PKG_REPO}" || -z "${PKG_BRANCH}" ]]; then
        echo "[ERROR] Missing required parameters!"
        echo "[USAGE] UPDATE_PACKAGE <pkg_name> <user/repo> <branch> [special] [extra_keywords]"
        return 1
    fi
    
    # 构建搜索关键词列表（包名 + 额外关键词）
    if [[ -n "${PKG_EXTRA_KEYWORDS}" ]]; then
        read -ra EXTRA_ARR <<< "${PKG_EXTRA_KEYWORDS}"
        PKG_LIST+=("${EXTRA_ARR[@]}")
    fi
    
    echo ""
    echo "[INFO] Processing: ${PKG_NAME} from ${PKG_REPO}#${PKG_BRANCH}"
    
    # ==================== 阶段1: 清理本地旧版本 ====================
    for NAME in "${PKG_LIST[@]}"; do
        echo "[INFO] Search directory: *${NAME}*"
        local FOUND_DIRS
        FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*${NAME}*" 2>/dev/null)
        
        if [[ -n "${FOUND_DIRS}" ]]; then
            while IFS= read -r DIR; do
                [[ -z "${DIR}" ]] && continue
                rm -rf "${DIR}" 2>/dev/null && \
                    echo "[OK] Delete directory: ${DIR}" || \
                    echo "[WARN] Failed to delete: ${DIR}"
            done <<< "${FOUND_DIRS}"
        else
            echo "[INFO] Not found directory: *${NAME}*"
        fi
    done
    
    # ==================== 阶段2: 克隆远程仓库 ====================
    local CLONE_URL="https://github.com/${PKG_REPO}.git"
    echo "[INFO] Cloning: ${CLONE_URL} (branch: ${PKG_BRANCH})"
    
    # 执行克隆并检查结果
    if ! git clone --depth=1 --single-branch --branch "${PKG_BRANCH}" "${CLONE_URL}" 2>/dev/null; then
        echo "[ERROR] Failed to clone repository: ${CLONE_URL}"
        return 1
    fi
    
    # 校验克隆目录是否存在
    if [[ ! -d "./${REPO_NAME}" ]]; then
        echo "[ERROR] Clone succeeded but directory not found: ./${REPO_NAME}"
        return 1
    fi
    
    # ==================== 阶段3: 特殊处理克隆结果 ====================
    if [[ "${PKG_SPECIAL}" == "pkg" ]]; then
        echo "[INFO] Mode 'pkg': Extracting subdirectory containing '*${PKG_NAME}*'"
        
        local FOUND_PKG=false
        # 查找并复制匹配的子目录
        while IFS= read -r -d '' SRC_DIR; do
            cp -rf "${SRC_DIR}" ./ 2>/dev/null && \
                echo "[OK] Copied: ${SRC_DIR} -> ./" && \
                FOUND_PKG=true
        done < <(find "./${REPO_NAME}/" -maxdepth 3 -type d -iname "*${PKG_NAME}*" -prune -print0 2>/dev/null)
        
        # 清理临时仓库
        rm -rf "./${REPO_NAME}" 2>/dev/null
        
        if [[ "${FOUND_PKG}" != true ]]; then
            echo "[WARN] No subdirectory matched '*${PKG_NAME}*', repository cleaned but no package extracted"
        fi
        
    elif [[ "${PKG_SPECIAL}" == "name" ]]; then
        echo "[INFO] Mode 'name': Renaming '${REPO_NAME}' -> '${PKG_NAME}'"
        
        if ! mv -f "${REPO_NAME}" "${PKG_NAME}" 2>/dev/null; then
            echo "[ERROR] Failed to rename directory: ${REPO_NAME} -> ${PKG_NAME}"
            return 1
        fi
    else
        echo "[INFO] Mode 'default': Using cloned directory as-is: ${REPO_NAME}"
    fi
    
    echo "[OK] UPDATE_PACKAGE completed: ${PKG_NAME}"
    return 0
}

# ✅ 基础用法
#UPDATE_PACKAGE "luci-app-argon" "jerrykuku/luci-theme-argon" "master"

# ✅ 重命名模式
#UPDATE_PACKAGE "luci-app-alist" "xiaorouji/openwrt-passwall" "main" "name"

# ✅ 提取子包模式
#UPDATE_PACKAGE "luci-app-passwall" "xiaorouji/openwrt-passwall" "main" "pkg"

# ✅ 带额外搜索关键词（清理更彻底）
#UPDATE_PACKAGE "luci-app-ssr-plus" "fw876/helloworld" "main" "" "ssr-plus helloworld"

# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
UPDATE_PACKAGE "shadcn" "eamonxg/luci-theme-shadcn" "main"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"
UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "master"
UPDATE_PACKAGE "kucat-config" "sirpdboy/luci-app-kucat-config" "master"

UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
UPDATE_PACKAGE "momo" "nikkinikki-org/OpenWrt-momo" "main"
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"

UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"

#UPDATE_PACKAGE "athena-led" "unraveloop/JDC-AX6600-Athena-LED-Controller" "main"
UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "main"
UPDATE_PACKAGE "diskmanager" "4IceG/luci-app-mini-diskmanager" "main"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
UPDATE_PACKAGE "netspeedtest" "sirpdboy/netspeedtest" "main" "" "homebox ookla-speedtest"
UPDATE_PACKAGE "netwizard" "sirpdboy/luci-app-netwizard" "main"
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"
UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main"
UPDATE_PACKAGE "timecontrol" "sirpdboy/luci-app-timecontrol" "main"
UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "gecoosac luci-app-timewol luci-app-wolplus"
UPDATE_PACKAGE "vnt" "lmq8267/luci-app-vnt" "main"
#add
UPDATE_PACKAGE "luci-app-kodexplorer" "kiddin9/op-packages" "main" "pkg"
UPDATE_PACKAGE "luci-app-speedtest-web" "kiddin9/op-packages" "main" "pkg"
UPDATE_PACKAGE "speedtest-web" "kiddin9/op-packages" "main" "pkg"
UPDATE_PACKAGE "openlist2" "kiddin9/op-packages" "main" "pkg"
UPDATE_PACKAGE "luci-app-openlist2" "kiddin9/op-packages" "main" "pkg"
UPDATE_PACKAGE "luci-app-adguardhome" "kiddin9/op-packages" "main" "pkg"


