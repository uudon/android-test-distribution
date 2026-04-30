#!/bin/bash

###############################################################################
# Telecom 自动发布脚本
# 功能：从 to-publish/telecom/ 自动获取并发布 APK
# 用法：./publish_telecom_auto.sh
###############################################################################

set -e  # 遇到错误立即退出

# ==================== 配置 ====================

APP_ID="telecom"
PUBLISH_DIR="/Volumes/macOS/dev/android-test-distribution/to-publish/${APP_ID}"
ARCHIVE_DIR="${PUBLISH_DIR}/archive"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

info() {
    echo -e "${YELLOW}→ $1${NC}"
}

app_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

notify() {
    local title="$1"
    local message="$2"

    # macOS 桌面通知
    if command -v osascript &> /dev/null; then
        osascript -e "display notification \"${message}\" with title \"${title}\" sound name \"Glass\""
    fi

    # 终端提示
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}📢 通知: ${title}${NC}"
    echo -e "${CYAN}${BOLD}   ${message}${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ==================== 检查目录 ====================

if [ ! -d "$PUBLISH_DIR" ]; then
    error "发布目录不存在: ${PUBLISH_DIR}"
fi

# 创建归档目录
mkdir -p "$ARCHIVE_DIR"

# ==================== 查找 APK 文件 ====================

echo ""
echo -e "${CYAN}${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║   📱 Telecom 自动发布脚本            ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""

info "扫描发布目录: ${PUBLISH_DIR}"

# 查找所有 APK 文件
APK_FILES=($(find "$PUBLISH_DIR" -maxdepth 1 -name "*.apk" -type f 2>/dev/null | sort))

if [ ${#APK_FILES[@]} -eq 0 ]; then
    app_info "未找到 APK 文件"
    echo ""
    echo "请将 APK 文件放到以下目录："
    echo "  ${PUBLISH_DIR}"
    echo ""
    exit 0
fi

if [ ${#APK_FILES[@]} -gt 1 ]; then
    echo ""
    echo -e "${YELLOW}发现 ${#APK_FILES[@]} 个 APK 文件：${NC}"
    echo ""

    for i in "${!APK_FILES[@]}"; do
        APK_FILE="${APK_FILES[$i]}"
        APK_NAME=$(basename "$APK_FILE")
        APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
        APK_TIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$APK_FILE")

        echo -e "  [$((i+1))] ${BOLD}${APK_NAME}${NC}"
        echo "      大小: ${APK_SIZE} | 时间: ${APK_TIME}"
        echo ""
    done

    read -p "请选择要发布的 APK [1-${#APK_FILES[@]}] (默认: 1): " choice
    choice=${choice:-1}

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#APK_FILES[@]}" ]; then
        error "无效的选择"
    fi

    APK_PATH="${APK_FILES[$((choice-1))]}"
else
    APK_PATH="${APK_FILES[0]}"
fi

APK_NAME=$(basename "$APK_PATH")
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)

echo ""
success "找到 APK 文件"
echo "  文件名: ${APK_NAME}"
echo "  大小: ${APK_SIZE}"
echo "  路径: ${APK_PATH}"
echo ""

# ==================== 提取版本信息 ====================

info "正在分析 APK 文件..."

APK_INFO=$(python3 "$SCRIPT_DIR/extract_apk_info.py" "$APK_PATH" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$APK_INFO" ]; then
    error "无法从 APK 中提取版本信息\n请确保 APK 文件有效"
fi

VERSION_NAME=$(echo "$APK_INFO" | cut -d'|' -f1)
VERSION_CODE=$(echo "$APK_INFO" | cut -d'|' -f2)
PACKAGE_NAME=$(echo "$APK_INFO" | cut -d'|' -f3)

success "APK 信息提取成功："
echo "  - 包名: ${PACKAGE_NAME}"
echo "  - 版本名: ${VERSION_NAME}"
echo "  - 构建号: ${VERSION_CODE}"
echo ""

# ==================== 检查是否已发布 ====================

LATEST_JSON="$SCRIPT_DIR/data/apps/${APP_ID}/latest.json"

if [ -f "$LATEST_JSON" ]; then
    CURRENT_VERSION=$(cat "$LATEST_JSON" | grep -o '"versionCode":[[:space:]]*"[^"]*"' | cut -d'"' -f4)

    if [ "$CURRENT_VERSION" = "$VERSION_CODE" ]; then
        echo -e "${YELLOW}⚠️  警告: 版本 ${VERSION_CODE} 已经发布过！${NC}"
        echo ""
        read -p "是否继续发布？（将覆盖旧版本）(y/N): " -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "发布已取消"
            exit 0
        fi
    fi
fi

# ==================== 输入更新说明 ====================

echo ""
read -p "请输入更新说明 (默认: 版本更新): " CHANGELOG_INPUT
CHANGELOG="${CHANGELOG_INPUT:-版本更新}"

# ==================== 确认发布 ====================

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}📦 准备发布 ${APP_ID}${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo "  版本: ${VERSION_NAME} (${VERSION_CODE})"
echo "  文件: ${APK_NAME}"
echo "  说明: ${CHANGELOG}"
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""

read -p "确认发布？(Y/n): " -n 1 -r
echo ""

# 默认为 Y
if [[ -n "$REPLY" && ! "$REPLY" =~ ^[Yy]$ ]]; then
    info "发布已取消"
    exit 0
fi

# ==================== 执行发布 ====================

echo ""
info "开始发布..."
echo ""

# 调用发布脚本
if "$SCRIPT_DIR/publish_multi.sh" "$APP_ID" "$APK_PATH" "$VERSION_NAME" "$VERSION_CODE" "$CHANGELOG"; then
    # 发布成功

    # 移动 APK 到归档目录
    ARCHIVE_PATH="${ARCHIVE_DIR}/${APK_NAME}"
    mv "$APK_PATH" "$ARCHIVE_PATH"

    echo ""
    success "APK 已归档到: ${ARCHIVE_PATH}"
    echo ""

    # 发布成功通知
    notify "✅ Telecom 发布成功！" "版本 ${VERSION_NAME} (${VERSION_CODE}) 已发布到服务器"

    # 保存发布记录
    LOG_FILE="${ARCHIVE_DIR}/publish.log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 发布成功: ${VERSION_NAME} (${VERSION_CODE}) - ${APK_NAME}" >> "$LOG_FILE"

    echo ""
    success "================================"
    success "发布完成！"
    success "================================"
    echo ""
    info "归档记录："
    echo "  - 文件: ${ARCHIVE_PATH}"
    echo "  - 日志: ${LOG_FILE}"
    echo ""

else
    # 发布失败
    echo ""
    notify "❌ Telecom 发布失败" "请检查错误信息"

    error "发布失败，请查看上方错误信息"
fi
