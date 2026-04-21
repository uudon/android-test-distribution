#!/bin/bash

##############################################################################
# Git 初始化脚本
# 为 Android 测试分发平台初始化 Git 版本控制
##############################################################################

set -e

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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
    echo -e "${BLUE}========================================"
    echo "$1"
    echo -e "========================================${NC}"
}

# 检查是否已经在 git 仓库中
if [ -d ".git" ]; then
    print_error "此目录已经是 Git 仓库！"
    exit 1
fi

print_header "🎯 初始化 Git 版本控制"

# 1. 初始化 git 仓库
print_info "步骤 1/7: 初始化 Git 仓库..."
git init
print_success "Git 仓库初始化完成"

# 2. 添加 .gitignore
print_info "步骤 2/7: 创建 .gitignore..."
if [ ! -f ".gitignore" ]; then
    print_error ".gitignore 文件不存在！"
    exit 1
fi
print_success ".gitignore 已就绪"

# 3. 添加所有文件
print_info "步骤 3/7: 添加文件到暂存区..."
git add .
print_success "文件已添加到暂存区"

# 4. 检查状态
print_info "步骤 4/7: 查看 Git 状态..."
git status --short
echo ""

# 5. 显示将要提交的文件统计
print_info "步骤 5/7: 统计文件..."
echo "跟踪的文件:"
git status --short | grep "^A" | wc -l | xargs echo "  - 新增文件:"
echo ""
echo "忽略的文件:"
git status --short | grep "^??" | wc -l | xargs echo "  - 未跟踪文件:"
echo ""

# 6. 创建初始提交
print_info "步骤 6/7: 创建初始提交..."
git commit -m "feat: 初始化 Android 测试分发平台

- 多应用支持（Telecom、Partner）
- 现代化 UI 设计（Glass Morphism）
- 版本回滚功能
- 自动化发布脚本
- Docker 容器化部署
- 完整文档

Co-Authored-By: Claude Sonnet <noreply@anthropic.com>"
print_success "初始提交完成"

# 7. 显示仓库信息
print_info "步骤 7/7: 仓库信息..."
echo ""
echo "📊 仓库统计:"
git log --oneline | head -1
echo ""
echo "📁 主要目录:"
ls -1 | grep -v "^\." | head -10
echo ""

print_header "✨ Git 初始化完成！"
echo ""
print_success "Git 仓库已创建"
echo ""
print_info "后续步骤:"
echo "  1. (可选) 创建 GitHub 仓库"
echo "  2. (可选) 关联远程仓库:"
echo "     git remote add origin <your-repo-url>"
echo "  3. (可选) 推送到 GitHub:"
echo "     git push -u origin main"
echo ""
print_warning "注意:"
echo "  - APK 文件已被 .gitignore 忽略（文件太大）"
echo "  - 如需 Git LFS 管理 APK，请参考 ROLLBACK_GUIDE.md"
echo "  - 敏感文件（.pem 密钥）已被忽略"
echo ""
