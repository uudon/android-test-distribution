#!/bin/bash

##############################################################################
# Android 测试分发平台 - 版本回滚脚本
# 功能：回滚到指定历史版本
##############################################################################

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_BASE_DIR="${SCRIPT_DIR}/data/apps"
SERVER_USER="ubuntu"
SERVER_HOST="43.136.56.11"
SERVER_KEY="/Volumes/macOS/Donwloads/claude.pem"
SERVER_BASE_DIR="/home/ubuntu/app/android-test-distribution/data/apps"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 显示使用说明
show_usage() {
    cat << EOF
用法: $0 <app_id> [version_code]

参数:
    app_id        应用 ID（如：telecom, partner）
    version_code  可选，要回滚到的版本号（构建号）

功能:
    1. 不带 version_code：显示版本历史列表
    2. 带 version_code：回滚到指定版本

示例:
    # 查看 Telecom 应用的版本历史
    $0 telecom

    # 回滚 Telecom 到版本 50100038
    $0 telecom 50100038

注意:
    - 回滚操作会更新 latest.json 和二维码
    - 不会删除任何现有 APK 文件
    - 建议在回滚前先查看版本历史

EOF
    exit 1
}

# 检查参数
if [ $# -lt 1 ]; then
    show_usage
fi

APP_ID="$1"
VERSION_CODE="$2"

# 验证应用 ID
APP_DIR="${SOURCE_BASE_DIR}/${APP_ID}"
if [ ! -d "${APP_DIR}" ]; then
    print_error "应用 ${APP_ID} 不存在！"
    echo ""
    echo "可用的应用:"
    for dir in "${SOURCE_BASE_DIR}"/*; do
        if [ -d "$dir" ]; then
            echo "  - $(basename "$dir")"
        fi
    done
    exit 1
fi

# 显示版本历史
show_version_history() {
    local app_id="$1"
    local versions_file="${SOURCE_BASE_DIR}/${app_id}/versions.json"

    if [ ! -f "$versions_file" ]; then
        print_error "未找到版本历史文件：$versions_file"
        exit 1
    fi

    print_header "📜 ${app_id} 应用版本历史"

    # 解析并显示版本列表
    local index=1
    declare -a version_codes
    declare -a version_names
    declare -a file_names
    declare -a publish_times

    while IFS= read -r line; do
        if [[ "$line" =~ \"versionCode\"[[:space:]]*:[[:space:]]*\"?([0-9]+) ]]; then
            version_codes[$index]="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ \"versionName\"[[:space:]]*:[[:space:]]*\"([^\"]+) ]]; then
            version_names[$index]="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ \"fileName\"[[:space:]]*:[[:space:]]*\"([^\"]+) ]]; then
            file_names[$index]="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ \"publishTime\"[[:space:]]*:[[:space:]]*\"([^\"]+) ]]; then
            publish_times[$index]="${BASH_REMATCH[1]}"
        fi

        if [[ "$line" =~ \} ]]; then
            index=$((index + 1))
        fi
    done < "$versions_file"

    # 显示版本列表（倒序，最新的在前）
    echo ""
    printf "%-5s %-15s %-12s %-40s %-20s\n" "序号" "版本号" "构建号" "文件名" "发布时间"
    printf "%-5s %-15s %-12s %-40s %-20s\n" "----" "-------" "------" "-------" "----------"

    for ((i=${#version_codes[@]}; i>=1; i--)); do
        local time="${publish_times[$i]}"
        local formatted_time=$(date -j -f "%Y-%m-%dT%H:%M:%S.000Z" "$time" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$time")
        printf "%-5s %-15s %-12s %-40s %-20s\n" \
            "$(( ${#version_codes[@]} - i + 1 ))" \
            "${version_names[$i]}" \
            "${version_codes[$i]}" \
            "${file_names[$i]}" \
            "$formatted_time"
    done

    echo ""
    print_info "当前最新版本: ${version_names[${#version_codes[@]}]} (构建号: ${version_codes[${#version_codes[@]}]})"
    print_info "总版本数: ${#version_codes[@]}"
    echo ""
    print_info "如需回滚，请执行:"
    echo "  $0 ${app_id} <构建号>"
    echo ""
}

# 检查 APK 文件是否存在
check_apk_exists() {
    local app_id="$1"
    local version_code="$2"
    local apk_dir="${SOURCE_BASE_DIR}/${app_id}/apk"

    # 查找匹配的 APK 文件
    local apk_file=$(find "$apk_dir" -name "*-${version_code}.apk" -type f 2>/dev/null | head -1)

    if [ -z "$apk_file" ]; then
        return 1
    fi

    echo "$apk_file"
    return 0
}

# 从服务器获取版本历史
get_remote_version_info() {
    local app_id="$1"
    local version_code="$2"

    local versions_json=$(ssh -i "$SERVER_KEY" ${SERVER_USER}@${SERVER_HOST} "cat ${SERVER_BASE_DIR}/${app_id}/versions.json")

    # 提取指定版本的信息
    local version_info=$(echo "$versions_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for version in data:
    if str(version.get('versionCode', '')) == '${version_code}':
        print(json.dumps(version))
        break
" 2>/dev/null)

    if [ -z "$version_info" ]; then
        return 1
    fi

    echo "$version_info"
    return 0
}

# 回滚到指定版本
rollback_to_version() {
    local app_id="$1"
    local version_code="$2"

    print_header "🔄 回滚 ${app_id} 到版本 ${version_code}"

    # 1. 检查本地 APK 文件
    print_info "步骤 1/5: 检查本地 APK 文件..."
    local apk_file=$(check_apk_exists "$app_id" "$version_code")

    if [ $? -ne 0 ]; then
        print_error "未找到构建号为 ${version_code} 的 APK 文件！"
        echo ""
        print_info "可用的 APK 文件:"
        ls -lh "${SOURCE_BASE_DIR}/${app_id}/apk/" | grep -E "\.apk$" | tail -5
        exit 1
    fi

    print_success "找到 APK 文件: $(basename "$apk_file")"

    # 2. 从服务器获取版本信息
    print_info "步骤 2/5: 从服务器获取版本信息..."
    local version_info=$(get_remote_version_info "$app_id" "$version_code")

    if [ $? -ne 0 ]; then
        print_error "服务器上未找到版本 ${version_code} 的记录！"
        exit 1
    fi

    print_success "获取版本信息成功"

    # 3. 生成新的 latest.json
    print_info "步骤 3/5: 生成新的 latest.json..."
    local latest_file="${SOURCE_BASE_DIR}/${app_id}/latest.json"

    # 将版本信息写入 latest.json
    echo "$version_info" | python3 -m json.tool > "$latest_file"

    print_success "已生成 latest.json"

    # 4. 生成二维码
    print_info "步骤 4/5: 生成二维码..."
    local qr_dir="${SOURCE_BASE_DIR}/${app_id}/qr"
    mkdir -p "$qr_dir"

    # 获取 APK URL
    local apk_url=$(echo "$version_info" | python3 -c "import sys, json; print(json.load(sys.stdin)['apkUrl'])")
    local download_url="http://${SERVER_HOST}:8080/android/${app_id}/${apk_url}"

    # 生成二维码
    qrencode -t PNG -o "${qr_dir}/latest.png" "$download_url" 2>/dev/null

    if [ $? -eq 0 ]; then
        print_success "已生成二维码"
    else
        print_warning "二维码生成失败（可能需要安装 qrencode）"
    fi

    # 5. 同步到服务器
    print_info "步骤 5/5: 同步到服务器..."

    # 同步 latest.json
    rsync -avz -e "ssh -i ${SERVER_KEY} -o StrictHostKeyChecking=no" \
        "$latest_file" \
        ${SERVER_USER}@${SERVER_HOST}:${SERVER_BASE_DIR}/${app_id}/

    # 同步二维码
    if [ -f "${qr_dir}/latest.png" ]; then
        rsync -avz -e "ssh -i ${SERVER_KEY} -o StrictHostKeyChecking=no" \
            "${qr_dir}/latest.png" \
            ${SERVER_USER}@${SERVER_HOST}:${SERVER_BASE_DIR}/${app_id}/qr/
    fi

    print_success "已同步到服务器"

    # 显示回滚结果
    echo ""
    print_success "========================================="
    print_success "回滚完成！"
    print_success "========================================="
    echo ""
    print_info "应用: ${app_id}"
    print_info "版本: $(echo "$version_info" | python3 -c "import sys, json; print(json.load(sys.stdin)['versionName'])")"
    print_info "构建号: ${version_code}"
    print_info "下载地址: http://${SERVER_HOST}:8080/android/${app_id}/"
    echo ""
    print_warning "注意: 回滚操作不影响版本历史，所有历史版本仍保留"
    echo ""
}

# 主逻辑
if [ -z "$VERSION_CODE" ]; then
    # 只显示版本历史
    show_version_history "$APP_ID"
else
    # 执行回滚
    rollback_to_version "$APP_ID" "$VERSION_CODE"
fi
