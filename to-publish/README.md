# APK 发布目录

此目录用于存放待发布的 APK 文件。

## 目录结构

```
to-publish/
├── telecom/           ← Telecom 应用的 APK 文件
├── partner/           ← Partner 应用的 APK 文件
└── README.md          <- 本文件
```

## 使用方法

### 1. 应用专属目录（推荐）

将 APK 放到对应应用的目录：

```bash
# Telecom 应用
cp your-telecom-app.apk to-publish/telecom/

# Partner 应用
cp your-partner-app.apk to-publish/partner/
```

### 2. 使用发布脚本

```bash
# Telecom 应用
./publish_telecom.sh

# Partner 应用
./publish_partner.sh

# 通用多应用发布
./publish_interactive.sh
```

## APK 命名规范

推荐使用标准命名格式，脚本可自动检测版本信息：

```
{app_id}-{versionName}-{versionCode}.apk
```

示例：
- `telecom-1.0.0-100.apk`
- `partner-1.0.0-200.apk`

如果不使用标准命名，脚本会提示手动输入版本信息。

## 注意事项

1. **一个目录一个 APK**：如果目录中有多个 APK，脚本会提示选择
2. **发布后自动清理**：脚本会询问是否删除已发布的 APK
3. **版本递增**：确保新版本的构建号大于服务器上的最新值

## 快速开始

```bash
# 1. 复制 APK
cp build/app.apk to-publish/telecom/telecom-1.0.1-101.apk

# 2. 运行发布脚本
./publish_telecom.sh

# 3. 按提示完成发布
```
