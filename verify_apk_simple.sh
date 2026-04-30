#!/bin/bash
# APK 一键校验脚本（简化版）
# 用法：直接运行，输入 APK 路径和校验和

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}   APK SHA256 校验工具${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# 输入 APK 文件路径
read -p "请输入 APK 文件路径（可直接拖拽文件）: " APK_FILE

# 去除引号
APK_FILE=$(echo "$APK_FILE" | sed 's/^["\x27]*//;s/["\x27]*$//')

if [ ! -f "$APK_FILE" ]; then
    echo -e "${RED}✗ 文件不存在: $APK_FILE${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}正在计算 SHA256 校验和...${NC}"

# 计算校验和
ACTUAL_CHECKSUM=$(shasum -a 256 "$APK_FILE" | cut -d' ' -f1)

# 显示计算结果
echo ""
echo -e "${CYAN}计算结果:${NC}"
echo "  文件: $(basename "$APK_FILE")"
echo "  SHA256: $ACTUAL_CHECKSUM"
echo ""

# 输入预期校验和
read -p "请输入网页上的校验和（或按 Enter 仅复制计算结果）: " EXPECTED_CHECKSUM

# 复制到剪贴板（macOS）
if command -v pbcopy &> /dev/null; then
    echo "$ACTUAL_CHECKSUM" | pbcopy
    echo -e "${GREEN}✓ 已复制到剪贴板${NC}"
fi

# 如果输入了校验和，进行对比
if [ -n "$EXPECTED_CHECKSUM" ]; then
    echo ""
    echo -e "${CYAN}======================================${NC}"

    # 去除可能的空格和特殊字符
    EXPECTED_CLEAN=$(echo "$EXPECTED_CHECKSUM" | tr -d ' \t\n\r')
    ACTUAL_CLEAN=$(echo "$ACTUAL_CHECKSUM" | tr -d ' \t\n\r')

    if [ "$ACTUAL_CLEAN" = "$EXPECTED_CLEAN"" ]; then
        echo -e "${GREEN}✓ 校验成功！文件完整且未被篡改${NC}"
    else
        echo -e "${RED}✗ 校验失败！文件可能已损坏或不完整${NC}"
        echo ""
        echo "预期: $EXPECTED_CLEAN"
        echo "实际: $ACTUAL_CLEAN"
        exit 1
    fi
fi

echo ""
