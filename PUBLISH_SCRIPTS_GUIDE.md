# 多应用发布脚本使用指南

## 脚本列表

项目中有多个发布脚本，根据不同的使用场景选择：

### 1. publish_interactive.sh - 通用多应用发布工具 🌟

**适用场景**：发布任意应用，交互式选择

**特点**：
- 自动加载所有已配置的应用
- 交互式选择要发布的应用
- 支持从应用专属目录或通用目录查找 APK
- 自动从服务器获取最新构建号

**使用方法**：
```bash
# 1. 将 APK 放到对应目录
# 方式1：应用专属目录（推荐）
cp your-app.apk to-publish/telecom/

# 方式2：通用目录
cp your-app.apk to-publish/

# 2. 运行脚本
./publish_interactive.sh

# 3. 按提示操作
# - 选择应用（telecom 或 partner）
# - 确认 APK 文件
# - 输入版本信息
# - 输入更新说明
# - 确认发布
```

**目录结构**：
```
to-publish/
├── telecom/              # Telecom 应用的 APK
│   └── telecom-1.0.0-100.apk
├── partner/                # Partner 应用的 APK
│   └── partner-2.0.0-200.apk
└── app-1.0.0-100.apk     # 通用目录（任何应用）
```

---

### 2. publish_telecom.sh - Telecom 应用专用 📞

**适用场景**：只发布 Telecom 应用

**特点**：
- 直接发布到 Telecom 应用
- 自动从 `to-publish/telecom/` 查找 APK
- 预配置应用信息
- 操作流程最简洁

**使用方法**：
```bash
# 1. 将 APK 放到 telecom 目录
cp telecom-app.apk to-publish/telecom/

# 2. 运行脚本
./publish_telecom.sh

# 3. 按提示输入版本信息即可
```

**示例**：
```bash
# 准备 APK（推荐使用标准命名）
cp build/app/outputs/apk/debug/telecom-1.0.0-100.apk to-publish/telecom/

# 发布
./publish_telecom.sh

# 脚本会自动：
# ✓ 检测版本号：1.0.0
# ✓ 检测构建号：100
# ✓ 获取服务器最新构建号并建议下一个
# ✓ 确认发布
```

---

### 3. publish_partner.sh - Partner 应用专用 🤝

**适用场景**：只发布 Partner 应用

**特点**：
- 直接发布到 Partner 应用
- 自动从 `to-publish/partner/` 查找 APK
- 预配置应用信息
- 操作流程简洁

**使用方法**：
```bash
# 1. 将 APK 放到 partner 目录
cp partner-app.apk to-publish/partner/

# 2. 运行脚本
./publish_partner.sh

# 3. 按提示输入版本信息即可
```

**示例**：
```bash
# 准备 APK
cp build/app/outputs/apk/debug/partner-2.0.0-200.apk to-publish/partner/

# 发布
./publish_partner.sh
```

---

### 4. publish_multi.sh - 命令行参数发布

**适用场景**：自动化脚本、CI/CD 集成

**特点**：
- 通过命令行参数传递所有信息
- 无需交互
- 适合集成到自动化流程

**使用方法**：
```bash
./publish_multi.sh <app_id> <apk_path> <versionName> <versionCode> <changelog>
```

**示例**：
```bash
# 发布 Telecom 应用
./publish_multi.sh telecom \
  to-publish/telecom/app.apk \
  1.0.0 \
  100 \
  "修复已知问题"

# 发布 Partner 应用
./publish_multi.sh partner \
  to-publish/partner/app.apk \
  2.0.0 \
  200 \
  "新增功能"
```

---

### 5. publish_android_test.sh - 兼容旧版本

**适用场景**：保持向后兼容

**特点**：
- 兼容旧的单应用发布方式
- 默认发布到 telecom 应用
- 支持可选的应用 ID 参数

**使用方法**：
```bash
# 旧方式（仍然有效，发布到 telecom）
./publish_android_test.sh app.apk 1.0.0 100 "更新说明"

# 新方式（指定应用）
./publish_android_test.sh telecom app.apk 1.0.0 100 "更新说明"
./publish_android_test.sh partner app.apk 2.0.0 200 "更新说明"
```

---

### 6. publish.sh - 原始单应用脚本

**适用场景**：保留用于参考，不推荐使用

**说明**：这是原始的单应用发布脚本，已保留但建议使用新的多应用脚本。

---

## APK 文件命名规范

### 推荐格式（应用专属）

```
{app_id}-{versionName}-{versionCode}.apk
```

**示例**：
- `telecom-1.0.0-100.apk`
- `partner-2.0.0-200.apk`
- `game-3.1.0-301.apk`

### 旧格式（仍然支持）

```
app-{versionName}-{versionCode}.apk
```

**示例**：
- `app-1.0.0-100.apk`
- `app-2.0.0-200.apk`

### 无格式名称

如果不遵循命名规范，脚本会提示手动输入版本信息。

---

## 版本信息说明

### versionName（版本号）

**格式**：`x.y.z`
- `x`：主版本号（重大更新）
- `y`：次版本号（功能新增）
- `z`：修订号（bug修复）

**示例**：
- `1.0.0` - 首个正式版本
- `1.1.0` - 新增功能
- `1.1.1` - bug修复

### versionCode（构建号）

**格式**：纯数字
- 每次发布必须递增
- 通常与版本号对应
- 自动从服务器获取当前最大值

**建议规则**：
- `100` = 1.0.0
- `110` = 1.1.0
- `111` = 1.1.1

---

## 完整发布流程示例

### 场景 1：发布 Telecom 应用新版本

```bash
# 1. 构建 APK
# 在 Android Studio 中构建，或使用命令行
./gradlew assembleDebug

# 2. 复制到发布目录（假设构建输出在 app/build/outputs/apk/debug/）
cp app/build/outputs/apk/debug/app-debug.apk to-publish/telecom/telecom-1.0.1-101.apk

# 3. 运行发布脚本
./publish_telecom.sh

# 4. 输入版本信息（脚本会自动检测）
# 版本号: 1.0.1
# 构建号: 101

# 5. 输入更新说明
# 修复登录问题
# 优化性能

# 按 Ctrl+D 结束输入

# 6. 确认发布
# 输入 y

# 7. 完成！
# 脚本会自动：
# - 生成版本文件
# - 上传到服务器
# - 询问是否打开浏览器
```

### 场景 2：快速发布（自动检测版本）

```bash
# 1. 使用标准命名复制 APK
cp app-debug.apk to-publish/telecom/telecom-1.0.2-102.apk

# 2. 运行脚本
./publish_telecom.sh

# 3. 脚本自动检测版本信息，直接按回车使用默认值
# 版本号 [1.0.2]: ← 直接回车
# 构建号 [102]: ← 直接回车

# 4. 输入简单更新说明
# Bug修复

# 5. 确认并发布
```

### 场景 3：使用通用脚本发布不同应用

```bash
# 发布 Telecom
cp telecom.apk to-publish/telecom/
./publish_interactive.sh
# 选择 1. Telecom

# 发布 Partner
cp partner.apk to-publish/partner/
./publish_interactive.sh
# 选择 2. Partner
```

---

## 常见问题

### Q: 脚本报错 "未找到 APK 文件"

**A**: 确保 APK 文件放在正确的目录：
- Telecom 应用：`to-publish/telecom/`
- Partner 应用：`to-publish/partner/`
- 通用目录：`to-publish/`

### Q: 如何添加新应用的发布脚本？

**A**: 复制现有脚本并修改配置：
```bash
# 复制 telecom 脚本
cp publish_telecom.sh publish_game.sh

# 编辑文件，修改以下变量
# APP_ID="game"
# APP_NAME="Game"
# APP_ICON="🎮"
```

### Q: 版本号格式错误怎么办？

**A**: 确保使用 `x.y.z` 格式，如 `1.0.0`、`2.3.1`

### Q: 构建号从哪里获取？

**A**: 脚本会自动从服务器获取当前最新构建号，并建议下一个号码

### Q: 发布失败怎么办？

**A**: 检查：
1. 网络连接（需要连接服务器）
2. SSH 密钥路径（`/Volumes/macOS/Donwloads/claude.pem`）
3. APK 文件是否完整
4. 版本号和构建号是否正确

---

## 脚本对比表

| 脚本 | 应用选择 | APK目录 | 交互式 | 适用场景 |
|------|---------|---------|--------|---------|
| publish_interactive.sh | ❓ 选择 | to-publish/{app}/ 或 to-publish/ | ✅ | 通用发布 |
| publish_telecom.sh | ✅ Telecom | to-publish/telecom/ | ✅ | Telecom专用 |
| publish_partner.sh | ✅ Partner | to-publish/partner/ | ✅ | Partner专用 |
| publish_multi.sh | ⚙️ 参数 | 任意 | ❌ | 自动化/CI/CD |
| publish_android_test.sh | ⚙️ 可选 | 任意 | ✅ | 向后兼容 |

---

## 快速开始

### 第一次使用

```bash
# 1. 创建发布目录
mkdir -p to-publish/telecom
mkdir -p to-publish/partner

# 2. 复制测试 APK
cp your-app.apk to-publish/telecom/telecom-1.0.0-100.apk

# 3. 运行发布脚本
./publish_telecom.sh

# 4. 按提示完成首次发布
```

### 日常发布

```bash
# 1. 复制新版本 APK（使用标准命名）
cp app-release.apk to-publish/telecom/telecom-1.0.1-101.apk

# 2. 运行脚本，使用自动检测的版本信息
./publish_telecom.sh

# 3. 输入更新说明，确认发布
```

---

## 自动化集成示例

### Makefile 集成

```makefile
.PHONY: publish-telecom publish-partner

publish-telecom:
	@echo "发布 Telecom 应用..."
	./publish_telecom.sh

publish-partner:
	@echo "发布 Partner 应用..."
	./publish_partner.sh
```

### 脚本集成

```bash
#!/bin/bash
# auto-publish.sh

APPS=("telecom" "partner")

for app in "${APPS[@]}"; do
    APK_FILE="to-publish/$app/*.apk"
    if [ -f $APK_FILE ]; then
        echo "发布 $app 应用..."
        ./publish_${app}.sh
    fi
done
```

---

## 技术支持

如有问题，请检查：
1. 脚本权限：`chmod +x publish_*.sh`
2. 网络连接：`ssh ubuntu@43.136.56.11`
3. 文件路径：确保所有路径正确
4. 版本格式：versionName 为 x.y.z，versionCode 为数字
