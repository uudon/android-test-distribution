#!/bin/bash
# APK 文件校验验证脚本
# 用法: ./verify_apk.sh <apk_file> <checksum>

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -ne 2 ]; then
    echo "用法: $0 <apk_file> <checksum>"
    echo "示例: $0 telecom-5.10.50-50100050.apk e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    exit 1
fi

APK_FILE="$1"
EXPECTED_CHECKSUM="$2"

if [ ! -f "$APK_FILE" ]; then
    echo -e "${RED}✗ 错误: APK 文件不存在: $APK_FILE${NC}"
    exit 1
fi

echo "正在验证 APK 文件..."
echo "文件: $APK_FILE"
echo "预期校验和: $EXPECTED_CHECKSUM"

ACTUAL_CHECKSUM=$(shasum -a 256 "$APK_FILE" | cut -d' ' -f1)
echo "实际校验和: $ACTUAL_CHECKSUM"

if [ "$ACTUAL_CHECKSUM" = "$EXPECTED_CHECKSUM" ]; then
    echo -e "${GREEN}✓ 文件校验成功！APK 文件完整且未被篡改。${NC}"
    exit 0
else
    echo -e "${RED}✗ 文件校验失败！文件可能已损坏或不完整。${NC}"
    echo -e "${YELLOW}建议重新下载 APK 文件。${NC}"
    exit 1
fi
