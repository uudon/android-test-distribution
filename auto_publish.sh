#!/bin/bash

###############################################################################
# Android APK 自动发布脚本
# 功能：从 APK 自动提取版本信息并发布
# 用法：./auto_publish.sh <app_id> <apk_path> [changelog]
###############################################################################

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# ==================== 参数检查 ====================

if [ $# -lt 2 ]; then
    error "用法: $0 <app_id> <apk_path> [changelog]\n\n示例: $0 telecom app-release.apk\n      $0 telecom app-release.apk \"修复已知问题\""
fi

APP_ID="$1"
APK_PATH="$2"
CHANGELOG="${3:-版本更新}"

# 验证应用ID格式
if [[ ! "$APP_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "应用ID格式无效：$APP_ID\n只允许字母、数字、下划线和连字符"
fi

# 验证 APK 文件存在
if [ ! -f "$APK_PATH" ]; then
    error "APK 文件不存在: $APK_PATH"
fi

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==================== 提取 APK 信息 ====================

info "正在分析 APK 文件..."
APK_INFO=$(python3 "$SCRIPT_DIR/extract_apk_info.py" "$APK_PATH" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$APK_INFO" ]; then
    error "无法从 APK 中提取版本信息\n请确保 APK 文件有效，或手动使用 publish_multi.sh"
fi

# 解析版本信息
VERSION_NAME=$(echo "$APK_INFO" | cut -d'|' -f1)
VERSION_CODE=$(echo "$APK_INFO" | cut -d'|' -f2)
PACKAGE_NAME=$(echo "$APK_INFO" | cut -d'|' -f3)

success "APK 信息提取成功："
echo "  - 包名: ${PACKAGE_NAME}"
echo "  - 版本名: ${VERSION_NAME}"
echo "  - 构建号: ${VERSION_CODE}"
echo ""

# ==================== 确认发布 ====================

echo -e "${YELLOW}即将发布到应用: ${APP_ID}${NC}"
echo "版本: ${VERSION_NAME} (${VERSION_CODE})"
echo "更新说明: ${CHANGELOG}"
echo ""

read -p "确认发布？(y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "发布已取消"
    exit 0
fi

# ==================== 调用发布脚本 ====================

info "开始发布..."
exec "$SCRIPT_DIR/publish_multi.sh" "$APP_ID" "$APK_PATH" "$VERSION_NAME" "$VERSION_CODE" "$CHANGELOG"
