# Git 版本控制指南

> Android 测试分发平台 - Git 工作流程

---

## 📋 概述

项目支持 Git 版本控制，用于：
- 📝 追踪代码和配置变更
- 🔄 版本管理和回退
- 👥 团队协作
- 📊 变更历史记录

---

## 🚀 快速开始

### 初始化 Git 仓库

项目已提供自动初始化脚本：

```bash
# 执行初始化脚本
./init-git.sh
```

**脚本会自动**：
1. ✅ 初始化 Git 仓库
2. ✅ 创建 .gitignore
3. ✅ 添加所有文件
4. ✅ 创建初始提交
5. ✅ 显示仓库信息

---

## 📁 .gitignore 配置

### 已忽略的文件

#### 1. APK 文件（⭐ 重要）
```
*.apk
```
**原因**：APK 文件太大（34MB+），不适合放入 Git

**解决方案**：
- 方案 1：使用版本回滚功能管理（已实现）
- 方案 2：使用 Git LFS（需单独配置）
- 方案 3：外部存储（对象存储、NAS）

#### 2. 敏感信息
```
*.pem      # SSH 密钥
*.key      # 其他密钥
.env       # 环境变量
```

#### 3. 系统文件
```
.DS_Store  # macOS
Thumbs.db  # Windows
```

#### 4. 编辑器配置
```
.vscode/
.idea/
*.swp      # Vim 临时文件
```

#### 5. 发布临时文件
```
to-publish/*.apk  # 待发布的 APK
```

---

## 🔄 常用 Git 操作

### 日常开发流程

```bash
# 1. 查看当前状态
git status

# 2. 添加修改的文件
git add <file>              # 添加单个文件
git add .                   # 添加所有文件
git add *.md                # 添加所有 Markdown 文件

# 3. 提交变更
git commit -m "描述你的更改"

# 4. 查看提交历史
git log --oneline          # 简洁显示
git log --graph            # 图形化显示

# 5. 查看文件变更
git diff                   # 工作区变更
git diff --staged          # 暂存区变更
```

### 提交消息规范

使用 **Conventional Commits** 格式：

```bash
# 新功能
git commit -m "feat: 添加版本回滚功能"

# Bug 修复
git commit -m "fix: 修复应用页面加载失败问题"

# 文档更新
git commit -m "docs: 更新回滚使用指南"

# 样式修改
git commit -m "style: 统一 HTML 代码格式"

# 重构
git commit -m "refactor: 优化发布脚本结构"

# 性能优化
git commit -m "perf: 优化页面加载速度"

# 测试
git commit -m "test: 添加回滚功能测试"

# 构建/工具
git commit -m "chore: 更新 .gitignore 配置"
```

---

## 🌐 关联 GitHub 远程仓库

### 创建 GitHub 仓库

1. 访问 https://github.com/new
2. 创建新仓库（不要初始化 README）
3. 复制仓库 URL

### 关联并推送

```bash
# 添加远程仓库
git remote add origin https://github.com/你的用户名/android-test-distribution.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

### 后续推送

```bash
# 提交本地修改
git add .
git commit -m "描述更改"

# 推送到 GitHub
git push
```

---

## 📊 分支管理

### 推荐分支策略

```
main          # 主分支（生产环境）
  ├── feature/*  # 功能分支
  ├── fix/*      # 修复分支
  └── docs/*     # 文档分支
```

### 创建和使用分支

```bash
# 创建新分支
git checkout -b feature/add-new-app

# 在新分支上工作...
git add .
git commit -m "feat: 添加新的应用支持"

# 切换回主分支
git checkout main

# 合并功能分支
git merge feature/add-new-app

# 删除已合并的分支
git branch -d feature/add-new-app
```

---

## 🔄 版本回退

### 查看 Git 历史

```bash
# 查看提交历史
git log --oneline --all

# 查看某个文件的修改历史
git log --oneline -- data/apps/telecom/index.html
```

### 回退到指定提交

```bash
# 方式 1: soft（保留修改在暂存区）
git reset --soft <commit-hash>

# 方式 2: mixed（保留修改在工作区，默认）
git reset --mixed <commit-hash>

# 方式 3: hard（⚠️ 丢弃所有修改）
git reset --hard <commit-hash>
```

### 撤销最近的提交

```bash
# 撤销提交，保留修改
git reset --soft HEAD~1

# 撤销提交和修改
git reset --hard HEAD~1

# 修改最近的提交消息
git commit --amend -m "新的提交消息"
```

---

## 📦 发布版本

### 创建版本标签

```bash
# 创建轻量标签
git tag v2.1.0

# 创建附注标签（推荐）
git tag -a v2.1.0 -m "版本 2.1.0 - 新增版本回滚功能"

# 查看所有标签
git tag -l

# 推送标签到 GitHub
git push origin v2.1.0
git push origin --tags
```

### 查看版本信息

```bash
# 显示标签信息
git show v2.1.0

# 查看指定标签的文件
git show v2.1.0:data/apps/telecom/index.html
```

---

## 🛡️ 备份与恢复

### 备份当前状态

```bash
# 创建备份提交
git add .
git commit -m "backup: $(date +%Y-%m-%d) 备份"

# 创建备份标签
git tag backup-$(date +%Y%m%d)
```

### 恢复到备份

```bash
# 查看所有备份
git tag -l "backup-*"

# 恢复到指定备份
git reset --hard backup-20260420
```

---

## 🔍 故障排查

### 问题：文件被忽略但想添加

**原因**：文件在 .gitignore 中

**解决**：
```bash
# 强制添加（-f 参数）
git add -f data/apps/telecom/apk/test.apk

# 或临时修改 .gitignore
```

### 问题：提交了敏感信息

**解决**：
```bash
# 1. 从 Git 历史中删除（保留文件）
git rm --cached <敏感文件>

# 2. 提交删除
git commit -m "chore: 移除敏感信息"

# 3. 推送到远程
git push

# 4. 修改 .gitignore，添加该文件
```

### 问题：需要修改历史提交

**警告**：修改历史会导致冲突，需要谨慎操作

```bash
# 交互式变基（最近 3 个提交）
git rebase -i HEAD~3

# 会打开编辑器，将 pick 改为 edit
# 修改后：
git add .
git rebase --continue
```

---

## 📚 最佳实践

### 1. 频繁提交
```bash
# ✅ 好习惯：小步快跑，频繁提交
git commit -m "feat: 添加应用图标"
git commit -m "fix: 修复图标显示问题"

# ❌ 坏习惯：大量修改一次性提交
git commit -m "update everything"
```

### 2. 清晰的提交消息
```bash
# ✅ 好消息
git commit -m "fix(telecom): 修复图标在移动端的显示问题

- 添加响应式样式
- 优化图标加载逻辑
- 添加备用 emoji"

# ❌ 坏消息
git commit -m "fix bug"
```

### 3. 使用 .gitignore
```bash
# ✅ 忽略编译产物、临时文件、敏感信息
# ❌ 不要忽略源代码、配置文件、文档
```

### 4. 推送前检查
```bash
# 1. 查看要推送的提交
git log origin/main..HEAD

# 2. 确认没有敏感信息
git diff --cached | grep -i "password\|secret\|key"

# 3. 确认没有大文件
git diff --cached --stat | grep -E "\s+[0-9]{3,}M"
```

---

## 🔗 相关资源

- [Git 官方文档](https://git-scm.com/doc)
- [GitHub Git 指南](https://guides.github.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git LFS 文档](https://git-lfs.github.com/)

---

## 📝 总结

### ✅ Git 已就绪
- `.gitignore` 配置完成
- 初始化脚本已准备
- 完整的工作流程文档

### 🚀 下一步
1. 执行 `./init-git.sh` 初始化仓库
2. (可选) 创建 GitHub 仓库
3. (可选) 推送到远程
4. 开始使用 Git 管理代码变更

### ⚠️ 重要提醒
- **APK 文件不放入 Git**（太大）
- **敏感信息不放入 Git**（密钥、密码）
- **使用版本回滚功能管理 APK 版本**

---

**文档版本**：v1.0
**最后更新**：2026-04-21
**维护者**：Claude + shixing
