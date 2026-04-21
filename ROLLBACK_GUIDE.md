# 版本回滚指南

> 最后更新：2026-04-20

---

## 📋 概述

Android 测试分发平台支持完整的版本历史管理和回滚功能。所有历史版本的 APK 都会被保留，可以随时回滚。

### ✅ 已有功能

- ✅ **版本历史记录**：所有发布的版本都保存在 `versions.json`
- ✅ **APK 文件保留**：历史 APK 文件永久保存在 `apk/` 目录
- ✅ **版本回滚脚本**：`rollback_version.sh` 支持快速回滚
- ✅ **完整信息保留**：版本号、构建号、更新说明、发布时间都保留

---

## 🔄 回滚操作

### 查看版本历史

```bash
# 查看 Telecom 应用的版本历史
./rollback_version.sh telecom

# 查看 Partner 应用的版本历史
./rollback_version.sh partner
```

**输出示例**：
```
========================================
📜 telecom 应用版本历史
========================================

序号 版本号       构建号    文名                                发布时间
---- -------         ------       -------                                  ----------
1     5.10.39         50100039     telecom-5.10.39-50100039.apk             2026-04-20 09:18
2     5.10.38         50100038     app-5.10.38-50100038.apk                 2026-04-20 08:11
3     5.10.37         50100037     app-5.10.37-50100037.apk                 2026-04-20 02:31
...
```

### 回滚到指定版本

```bash
# 语法
./rollback_version.sh <app_id> <version_code>

# 示例：回滚 Telecom 到构建号 50100038
./rollback_version.sh telecom 50100038
```

**回滚过程**：
1. ✅ 检查本地 APK 文件是否存在
2. ✅ 从服务器获取该版本的完整信息
3. ✅ 生成新的 `latest.json`
4. ✅ 生成新的二维码
5. ✅ 同步到服务器

---

## 🛡️ 安全特性

### 1. 不会删除任何文件
- 回滚操作**只更新** `latest.json` 和二维码
- 所有历史 APK 文件**永久保留**
- 版本历史 `versions.json` **不变**

### 2. 可重复回滚
- 可以在不同版本之间来回切换
- 不会丢失任何版本信息
- 每次回滚都是独立的操作

### 3. 确认机制
- 回滚前会显示详细的版本信息
- 确认 APK 文件存在才执行
- 失败会提示错误原因

---

## 📂 文件结构

```
data/apps/telecom/
├── latest.json           # 当前最新版本（回滚会更新此文件）
├── versions.json         # 完整版本历史（不变）
├── apk/                  # 所有历史 APK
│   ├── app-1.0.0-100.apk
│   ├── app-1.0.1-101.apk
│   ├── app-5.10.35-50100035.apk
│   ├── app-5.10.36-50100036.apk
│   ├── app-5.10.37-50100037.apk
│   ├── app-5.10.38-50100038.apk
│   └── telecom-5.10.39-50100039.apk
└── qr/
    ├── latest.png        # 当前二维码（回滚会更新此文件）
    └── ...
```

---

## 🔧 回滚脚本功能

### rollback_version.sh

**功能**：
1. 显示版本历史列表
2. 回滚到指定历史版本
3. 自动生成二维码
4. 自动同步到服务器

**用法**：
```bash
# 查看帮助
./rollback_version.sh

# 查看版本历史
./rollback_version.sh <app_id>

# 执行回滚
./rollback_version.sh <app_id> <version_code>
```

**参数**：
- `app_id`：应用 ID（telecom、partner）
- `version_code`：构建号（versionCode）

**示例**：
```bash
# 查看 Telecom 版本历史
./rollback_version.sh telecom

# 回滚 Telecom 到 5.10.38（构建号 50100038）
./rollback_version.sh telecom 50100038

# 回滚 Partner 到 2.0.0（构建号 200）
./rollback_version.sh partner 200
```

---

## 🚨 常见场景

### 场景 1：发现严重 Bug，需要紧急回滚

```bash
# 1. 查看版本历史，找到上一个稳定版本
./rollback_version.sh telecom

# 2. 回滚到稳定版本（例如 50100038）
./rollback_version.sh telecom 50100038

# 3. 通知测试团队访问下载页
# http://43.136.56.11:8080/android/telecom/
```

### 场景 2：需要对比不同版本

```bash
# 查看所有版本，找到需要对比的版本
./rollback_version.sh telecom

# 回滚到版本 A 进行测试
./rollback_version.sh telecom 50100037

# 测试完成后，回滚到版本 B
./rollback_version.sh telecom 50100038
```

### 场景 3：误发布了错误版本

```bash
# 立即回滚到之前的正确版本
./rollback_version.sh telecom 50100038

# 修复问题后重新发布新版本
./publish_telecom.sh
```

---

## ⚠️ 注意事项

### 1. 版本号和构建号
- **versionName**：版本号（如 5.10.39）
- **versionCode**：构建号（如 50100039）
- 回滚脚本使用**构建号**来标识版本

### 2. 回滚的影响
- ✅ 下载页会显示回滚后的版本
- ✅ 二维码会指向回滚后的 APK
- ✅ 不会影响已安装的用户
- ❌ 版本历史不会改变

### 3. 测试团队通知
回滚后建议通知测试团队：
- 发布说明已回滚
- 当前可用版本
- 下载地址（未变化）

---

## 📊 版本管理最佳实践

### 1. 定期清理旧版本（可选）
```bash
# 保留最近 20 个版本
cd data/apps/telecom/apk/
ls -t | tail -n +21 | xargs rm -f
```

### 2. 备份重要版本
```bash
# 备份特定版本到其他位置
cp data/apps/telecom/apk/telecom-5.10.39-50100039.apk ~/backup/
```

### 3. 版本标签建议
- 使用语义化版本号（Semantic Versioning）
- 每次发布递增构建号
- 清晰的更新说明

---

## 🔍 故障排查

### 问题：回滚脚本找不到 APK 文件

**原因**：APK 文件已被删除或路径错误

**解决**：
```bash
# 检查 APK 文件是否存在
ls -lh data/apps/telecom/apk/

# 如果文件不存在，从服务器恢复
ssh ubuntu@43.136.56.11 "cd /home/ubuntu/app/android-test-distribution && \
docker cp android-test-web:/usr/share/nginx/html/android/apps/telecom/apk/XXX.apk ."
```

### 问题：回滚后下载页未更新

**原因**：浏览器缓存

**解决**：
```bash
# 强制刷新浏览器
Ctrl + Shift + R (Windows/Linux)
Cmd + Shift + R (Mac)
```

### 问题：二维码生成失败

**原因**：未安装 qrencode 工具

**解决**：
```bash
# macOS
brew install qrencode

# Ubuntu/Debian
sudo apt-get install qrencode
```

---

## 📞 相关文档

- [发布脚本指南](./PUBLISH_SCRIPTS_GUIDE.md)
- [快速参考](./PUBLISH_QUICK_REF.md)
- [主文档](./Android测试分发平台.md)
- [更新日志](./Android测试分发平台-更新日志.md)

---

**文档版本**：v1.0
**最后更新**：2026-04-20
**维护者**：Claude + shixing
