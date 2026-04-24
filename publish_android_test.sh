#!/bin/bash

###############################################################################
# Android 测试包发布脚本
# 功能：自动更新版本信息、生成二维码、同步到服务器
###############################################################################

# ==================== 配置区域 ====================

# 下载页基础 URL（用于生成二维码）
# 如果有域名，请修改为: http://your-domain.com/android/
# 如果没有域名，可以使用 IP: http://43.136.56.11:8080/android/
BASE_URL="http://43.136.56.11:8080/android/"

# 服务器连接信息
SERVER_USER="ubuntu"
SERVER_HOST="43.136.56.11"
REMOTE_DIR="/home/ubuntu/app/android-test-distribution"

# 构建类型（debug/release）
BUILD_TYPE="debug"

# ==================== 脚本开始 ====================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# ==================== 参数检查 ====================

# 检查第一个参数是应用ID还是APK路径
APP_ID="telecom"  # 默认应用
if [ $# -gt 0 ]; then
    if [[ ! "$1" =~ \.apk$ ]] && [ ! -f "$1" ]; then
        # 第一个参数不是APK文件路径，当作应用ID处理
        APP_ID="$1"
        shift
    fi
fi

if [ $# -lt 4 ]; then
    error "用法: $0 [app_id] <apk路径> <versionName> <versionCode> <changelog>\n示例: $0 telecom app-release.apk 1.0.0 100 \"修复已知问题\"\n      $0 app-release.apk 1.0.0 100 \"修复已知问题\" (默认发布到 telecom)\""
fi

APK_PATH="$1"
VERSION_NAME="$2"
VERSION_CODE="$3"
CHANGELOG="$4"

# 验证 APK 文件存在
if [ ! -f "$APK_PATH" ]; then
    error "APK 文件不存在: $APK_PATH"
fi

# 获取 APK 文件名
APK_FILENAME=$(basename "$APK_PATH")
if [[ ! "$APK_FILENAME" =~ \.apk$ ]]; then
    error "文件不是 APK 格式: $APK_FILENAME"
fi

# ==================== 路径设置 ====================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
APP_DIR="$DATA_DIR/apps/${APP_ID}"
APK_DIR="$APP_DIR/apk"
QR_DIR="$APP_DIR/qr"
LATEST_JSON="$APP_DIR/latest.json"
VERSIONS_JSON="$APP_DIR/versions.json"

# 标准化 APK 文件名：{appId}-{versionName}-{versionCode}.apk
STANDARD_APK_NAME="${APP_ID}-${VERSION_NAME}-${VERSION_CODE}.apk"
APK_DEST="$APK_DIR/$STANDARD_APK_NAME"
QR_DEST="$QR_DIR/latest.png"

# ==================== 创建目录 ====================

info "创建必要的目录..."
mkdir -p "$APP_DIR"
mkdir -p "$APK_DIR"
mkdir -p "$QR_DIR"

# ==================== 复制 APK ====================

info "复制 APK 文件..."
cp "$APK_PATH" "$APK_DEST"
success "APK 已复制到: $APK_DEST"

# ==================== 生成 latest.json ====================

info "生成 latest.json..."
PUBLISH_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

cat > "$LATEST_JSON" << EOF
{
  "versionName": "${VERSION_NAME}",
  "versionCode": "${VERSION_CODE}",
  "fileName": "${STANDARD_APK_NAME}",
  "apkUrl": "./apk/${STANDARD_APK_NAME}",
  "qrUrl": "./qr/latest.png",
  "publishTime": "${PUBLISH_TIME}",
  "buildType": "${BUILD_TYPE}",
  "changelog": $(echo "$CHANGELOG" | jq -Rs .)
}
EOF

success "latest.json 已生成"

# ==================== 更新 versions.json ====================

info "更新 versions.json..."

# 创建新版本记录
NEW_VERSION=$(cat << EOF
{
  "versionName": "${VERSION_NAME}",
  "versionCode": "${VERSION_CODE}",
  "fileName": "${STANDARD_APK_NAME}",
  "apkUrl": "./apk/${STANDARD_APK_NAME}",
  "publishTime": "${PUBLISH_TIME}",
  "buildType": "${BUILD_TYPE}",
  "changelog": $(echo "$CHANGELOG" | jq -Rs .)
}
EOF
)

# 检查 versions.json 是否存在
if [ ! -f "$VERSIONS_JSON" ]; then
    info "创建新的 versions.json"
    echo "[$NEW_VERSION]" > "$VERSIONS_JSON"
else
    # 检查是否已存在相同版本
    if grep -q "\"versionCode\": \"${VERSION_CODE}\"" "$VERSIONS_JSON"; then
        info "版本 ${VERSION_CODE} 已存在，将被覆盖"
        # 移除旧版本
        jq --arg vc "$VERSION_CODE" 'del(.[] | select(.versionCode == $vc))' "$VERSIONS_JSON" > "${VERSIONS_JSON}.tmp"
        mv "${VERSIONS_JSON}.tmp" "$VERSIONS_JSON"
    fi

    # 将新版本插入到数组开头
    jq --argjson new "$NEW_VERSION" '.[:0] += [$new]' "$VERSIONS_JSON" > "${VERSIONS_JSON}.tmp"
    mv "${VERSIONS_JSON}.tmp" "$VERSIONS_JSON"
fi

success "versions.json 已更新"

# ==================== 生成二维码 ====================

info "生成二维码..."

# 使用 Docker 临时容器生成二维码（推荐方式）
if command -v docker &> /dev/null; then
    info "使用 Docker 生成二维码..."
    docker run --rm -v "$QR_DIR:/output" \
        debian:stable-slim \
        bash -c "apt-get update -qq && apt-get install -y -qq qrencode && echo '${BASE_URL}' | qrencode -o /output/latest.png -s 6 -m 2"
    success "二维码已生成（Docker 方式）"
else
    # 备用方式：使用系统 qrencode
    if command -v qrencode &> /dev/null; then
        info "使用系统 qrencode 生成二维码..."
        echo "$BASE_URL" | qrencode -o "$QR_DEST" -s 6 -m 2
        success "二维码已生成（系统方式）"
    else
        error "未找到 Docker 或 qrencode 命令，无法生成二维码"
    fi
fi

# ==================== 同步到服务器 ====================

info "同步到服务器 ${SERVER_USER}@${SERVER_HOST}..."
rsync -avz --delete \
    -e "ssh -i /Volumes/macOS/documents/密钥/mac.pem -o StrictHostKeyChecking=no" \
    "$DATA_DIR/" \
    "${SERVER_USER}@${SERVER_HOST}:${REMOTE_DIR}/data/"

success "数据已同步到服务器"

# ==================== 完成 ====================

echo ""
success "================================"
success "发布完成！"
success "================================"
echo ""
info "应用信息："
echo "  - 应用ID: ${APP_ID}"
echo "  - 版本号: ${VERSION_NAME}"
echo "  - 构建号: ${VERSION_CODE}"
echo "  - 构建类型: ${BUILD_TYPE}"
echo "  - 发布时间: ${PUBLISH_TIME}"
echo "  - 文件名: ${STANDARD_APK_NAME}"
echo ""
info "访问地址："
echo "  - 应用选择页: ${BASE_URL%android/}"
echo "  - 应用下载页: ${BASE_URL}${APP_ID}/"
echo "  - APK直链: ${BASE_URL}${APP_ID}/apk/${STANDARD_APK_NAME}"
echo ""
info "下一步："
echo "  1. 访问 ${BASE_URL}${APP_ID}/ 验证页面"
echo "  2. 扫码或点击下载按钮测试安装"
echo ""
