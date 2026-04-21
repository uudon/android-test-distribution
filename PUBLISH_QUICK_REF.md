# 发布脚本快速参考

## 📋 脚本概览

| 脚本 | 说明 | 使用场景 |
|------|------|---------|
| `publish_interactive.sh` | 🌟 通用多应用发布 | 发布任意应用（推荐日常使用） |
| `publish_telecom.sh` | 📞 Telecom 专用 | 只发布 Telecom 应用 |
| `publish_partner.sh` | 🤝 Partner 专用 | 只发布 Partner 应用 |
| `publish_multi.sh` | ⚙️ 命令行发布 | 自动化/CI/CD |
| `publish_android_test.sh` | 🔄 兼容旧版本 | 向后兼容 |

---

## 🚀 快速使用

### 方式 1：通用发布（推荐）

```bash
# 1. 放置 APK
cp your-app.apk to-publish/telecom/

# 2. 运行脚本
./publish_interactive.sh

# 3. 选择应用编号
> 1  ← 选择 Telecom
```

### 方式 2：应用专用

```bash
# Telecom 应用
./publish_telecom.sh

# Partner 应用
./publish_partner.sh
```

### 方式 3：命令行发布

```bash
./publish_multi.sh telecom app.apk 1.0.0 100 "更新说明"
```

---

## 📁 APK 存放位置

```
to-publish/
├── telecom/          ← Telecom 应用的 APK
├── partner/            ← Partner 应用的 APK
└── [any].apk         ← 通用位置
```

---

## 🏷️ APK 命名规范

**推荐**（自动检测版本）：
```
{app_id}-{versionName}-{versionCode}.apk
```

**示例**：
- `telecom-1.0.0-100.apk`
- `partner-2.0.0-200.apk`

---

## 📝 版本号格式

- **versionName**: `x.y.z` （如 1.0.0）
- **versionCode**: 数字 （如 100）

---

## ✨ 脚本功能

### ✅ 自动功能
- 自动检测文件名中的版本信息
- 从服务器获取最新构建号
- 生成版本 JSON 文件
- 生成二维码
- 同步到服务器
- 询问清理 APK 文件

### ✅ 交互式提示
- 多 APK 选择
- 版本信息确认
- 更新说明输入（支持多行）
- 发布前确认
- 自动打开浏览器（可选）

---

## 🎯 使用示例

### 示例 1：发布 Telecom v1.0.1

```bash
# 1. 准备 APK
cp build/app.apk to-publish/telecom/telecom-1.0.1-101.apk

# 2. 发布
./publish_telecom.sh

# 3. 按提示操作
# 版本号 [1.0.1]: ← 回车
# 构建号 [101]: ← 回车
# 更新说明: 修复登录问题
# 确认发布: y
```

### 示例 2：发布 Partner v2.0.0

```bash
# 1. 准备 APK
cp build/partner.apk to-publish/partner/partner-2.0.0-200.apk

# 2. 发布
./publish_partner.sh

# 3. 完成
```

### 示例 3：不确定发布哪个应用

```bash
# 1. 将 APK 放到对应目录
cp telecom.apk to-publish/telecom/
cp partner.apk to-publish/partner/

# 2. 使用通用脚本
./publish_interactive.sh

# 3. 界面显示：
# 1. 📞 Telecom (telecom)
#    Telecom 应用测试版
# 2. 🤝 Partner (partner)
#    Partner应用测试版
#
# 请选择要发布的应用 (输入序号 1-2):
```

---

## ⚠️ 注意事项

1. **APK 位置**：确保放在正确的应用目录
2. **版本递增**：构建号必须大于服务器上的最新值
3. **网络连接**：需要能连接到服务器上传文件
4. **SSH 密钥**：确保密钥路径正确

---

## 🔧 添加新应用脚本

```bash
# 1. 复制模板
cp publish_telecom.sh publish_game.sh

# 2. 编辑修改
vim publish_game.sh

# 3. 修改配置
# APP_ID="game"
# APP_NAME="Game"
# APP_ICON="🎮"

# 4. 设置权限
chmod +x publish_game.sh
```

---

## 🔄 版本回滚

```bash
# 查看版本历史
./rollback_version.sh telecom

# 回滚到指定版本
./rollback_version.sh telecom 50100038
```

---

## 📚 详细文档

- **发布脚本指南**：[PUBLISH_SCRIPTS_GUIDE.md](./PUBLISH_SCRIPTS_GUIDE.md)
- **版本回滚指南**：[ROLLBACK_GUIDE.md](./ROLLBACK_GUIDE.md)

---

## 🎉 快速开始

```bash
# 第一次使用
mkdir -p to-publish/telecom
cp your-app.apk to-publish/telecom/telecom-1.0.0-100.apk
./publish_telecom.sh
```
