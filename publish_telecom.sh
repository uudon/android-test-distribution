#!/bin/bash

###############################################################################
# Telecom 应用一键发布脚本
# 使用方法：
#   1. 将 APK 文件放到 to-publish/telecom/ 目录
#   2. 运行本脚本：./publish_telecom.sh
###############################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}→ $1${NC}"
}

important() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 应用配置
APP_ID="telecom"
APP_NAME="Telecom"
APP_ICON="📞"

# 项目目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APK_DIR="$PROJECT_DIR/to-publish/$APP_ID"

echo -e "${CYAN}"
echo "========================================"
echo "   $APP_ICON $APP_NAME 应用发布工具"
echo "========================================"
echo -e "${NC}"

# ==================== 检查 APK 文件 ====================

info "检查 to-publish/$APP_ID 目录..."

if [ ! -d "$APK_DIR" ]; then
    mkdir -p "$APK_DIR"
    important "已创建目录: $APK_DIR"
    echo ""
    error "目录为空，请先将 APK 文件放到以下目录：\n  $APK_DIR/"
fi

# 查找 APK 文件
APK_FILES=($(find "$APK_DIR" -maxdepth 1 -name "*.apk" -type f 2>/dev/null | sort))

if [ ${#APK_FILES[@]} -eq 0 ]; then
    error "
未找到 APK 文件！

请先将 $APP_NAME 的 APK 文件放到：
  $APK_DIR

例如：
  cp /path/to/telecom-app.apk $APK_DIR/
"
fi

if [ ${#APK_FILES[@]} -gt 1 ]; then
    important "发现多个 APK 文件："
    echo ""
    for i in "${!APK_FILES[@]}"; do
        apk_file="${APK_FILES[$i]}"
        apk_name=$(basename "$apk_file")
        size=$(ls -lh "$apk_file" | awk '{print $5}')
        echo "  $((i+1)). $apk_name ($size)"
    done
    echo ""

    while true; do
        read -p "请选择要发布的 APK (输入序号，默认 1): " choice
        choice=${choice:-1}

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#APK_FILES[@]} ]; then
            APK_PATH="${APK_FILES[$((choice-1))]}"
            break
        else
            error "无效的选择，请输入 1-${#APK_FILES[@]} 之间的数字"
        fi
    done
else
    APK_PATH="${APK_FILES[0]}"
fi

APK_FILENAME=$(basename "$APK_PATH")
success "找到 APK: $APK_FILENAME"

# 显示 APK 信息
APK_SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
APK_TIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$APK_PATH")
info "文件大小: $APK_SIZE"
info "修改时间: $APK_TIME"
echo ""

# ==================== 收集版本信息 ====================

info "请输入版本信息"
echo ""

# 尝试从文件名提取版本号
if [[ "$APK_FILENAME" =~ ${APP_ID}-([0-9]+\.[0-9]+\.[0-9]+)-([0-9]+) ]]; then
    SUGGESTED_VERSION="${BASH_REMATCH[1]}"
    SUGGESTED_CODE="${BASH_REMATCH[2]}"
    important "检测到文件名中的版本信息："
    echo "  版本号: $SUGGESTED_VERSION"
    echo "  构建号: $SUGGESTED_CODE"
    echo ""
elif [[ "$APK_FILENAME" =~ app-([0-9]+\.[0-9]+\.[0-9]+)-([0-9]+) ]]; then
    SUGGESTED_VERSION="${BASH_REMATCH[1]}"
    SUGGESTED_CODE="${BASH_REMATCH[2]}"
    important "检测到文件名中的版本信息（非标准命名）："
    echo "  版本号: $SUGGESTED_VERSION"
    echo "  构建号: $SUGGESTED_CODE"
    echo "  建议使用: ${APP_ID}-版本号-构建号.apk 格式"
    echo ""
fi

# 输入版本号
while true; do
    if [ -n "$SUGGESTED_VERSION" ]; then
        read -p "版本号 (versionName) [默认: $SUGGESTED_VERSION]: " VERSION_NAME
        VERSION_NAME=${VERSION_NAME:-$SUGGESTED_VERSION}
    else
        read -p "版本号 (versionName，如 1.0.0): " VERSION_NAME
    fi

    if [[ "$VERSION_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        break
    else
        error "版本号格式错误，应为 x.y.z 格式（如 1.0.0）"
    fi
done

# 输入构建号
while true; do
    if [ -n "$SUGGESTED_CODE" ]; then
        read -p "构建号 (versionCode) [默认: $SUGGESTED_CODE]: " VERSION_CODE
        VERSION_CODE=${VERSION_CODE:-$SUGGESTED_CODE}
    else
        info "检查 $APP_NAME 当前最新构建号..."
        LATEST_CODE=$(ssh -i "/Volumes/macOS/Donwloads/claude.pem" \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=5 \
            ubuntu@43.136.56.11 \
            "cat /home/ubuntu/app/android-test-distribution/data/apps/$APP_ID/latest.json 2>/dev/null | grep versionCode | grep -oE '[0-9]+' 2>/dev/null" || echo "0")

        if [ "$LATEST_CODE" != "0" ]; then
            NEXT_CODE=$((LATEST_CODE + 1))
            important "当前最新构建号: $LATEST_CODE，建议使用: $NEXT_CODE"
            read -p "构建号 (versionCode) [默认: $NEXT_CODE]: " VERSION_CODE
            VERSION_CODE=${VERSION_CODE:-$NEXT_CODE}
        else
            read -p "构建号 (versionCode，如 100): " VERSION_CODE
        fi
    fi

    if [[ "$VERSION_CODE" =~ ^[0-9]+$ ]]; then
        break
    else
        error "构建号必须是数字"
    fi
done

# 输入更新说明
echo ""
info "请输入更新说明（支持多行，输入完成后按 Ctrl+D）："
CHANGELOG_LINES=()
while IFS= read -r line; do
    CHANGELOG_LINES+=("$line")
done
CHANGELOG=$(
    IFS=$'\n'
    echo "${CHANGELOG_LINES[*]}"
)

if [ -z "$CHANGELOG" ]; then
    CHANGELOG="版本更新"
fi

# ==================== 确认发布 ====================

echo ""
echo -e "${YELLOW}========================================${NC}"
echo "发布信息确认："
echo ""
echo "  应用: $APP_ICON $APP_NAME"
echo "  APK 文件: $APK_FILENAME"
echo "  版本号: $VERSION_NAME"
echo "  构建号: $VERSION_CODE"
echo "  更新说明:"
echo "$CHANGELOG" | head -3
if [ $(echo "$CHANGELOG" | wc -l) -gt 3 ]; then
    echo "  ..."
fi
echo ""
echo -e "${YELLOW}========================================${NC}"
echo ""

read -p "确认发布？(y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    error "已取消发布"
fi

# ==================== 执行发布 ====================

echo ""
info "开始发布到 $APP_NAME..."
echo ""

cd "$PROJECT_DIR"

./publish_multi.sh \
    "$APP_ID" \
    "$APK_PATH" \
    "$VERSION_NAME" \
    "$VERSION_CODE" \
    "$CHANGELOG"

PUBLISH_RESULT=$?

if [ $PUBLISH_RESULT -eq 0 ]; then
    echo ""
    success "================================"
    success "发布成功！"
    success "================================"
    echo ""
    info "版本信息："
    echo "  - 应用: $APP_NAME"
    echo "  - 版本号: $VERSION_NAME"
    echo "  - 构建号: $VERSION_CODE"
    echo "  - 文件名: ${APP_ID}-${VERSION_NAME}-${VERSION_CODE}.apk"
    echo ""
    info "访问地址："
    echo "  - 应用下载: http://43.136.56.11:8080/android/${APP_ID}/"
    echo "  - APK 直链: http://43.136.56.11:8080/android/${APP_ID}/apk/${APP_ID}-${VERSION_NAME}-${VERSION_CODE}.apk"
    echo ""

    # 询问是否打开下载页
    read -p "是否在浏览器打开应用下载页？(y/n): " open_browser
    if [[ "$open_browser" =~ ^[Yy]$ ]]; then
        open "http://43.136.56.11:8080/android/${APP_ID}/"
    fi

    # 询问是否删除已发布的 APK
    echo ""
    read -p "是否删除已发布的 APK 文件？(y/n): " delete_apk
    if [[ "$delete_apk" =~ ^[Yy]$ ]]; then
        rm -f "$APK_PATH"
        success "已删除: $APK_FILENAME"
    else
        info "保留文件: $APK_FILENAME"
    fi

else
    error "发布失败，请检查错误信息"
fi

echo ""
