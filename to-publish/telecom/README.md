# Telecom 自动发布目录

## 使用方法

### 1. 快速发布

```bash
# 运行自动发布脚本
./publish_telecom_auto.sh
```

脚本会自动：
- ✅ 扫描此目录中的 APK 文件
- ✅ 提取版本信息
- ✅ 要求输入更新说明
- ✅ 确认后自动发布
- ✅ 发布完成后通知你
- ✅ 将已发布的 APK 移动到 `archive/` 目录

### 2. 使用流程

1. **复制 APK 到此目录**
   ```bash
   cp ~/Downloads/telecom-app.apk /Volumes/macOS/dev/android-test-distribution/to-publish/telecom/
   ```

2. **运行发布脚本**
   ```bash
   cd /Volumes/macOS/dev/android-test-distribution
   ./publish_telecom_auto.sh
   ```

3. **按照提示操作**
   - 如果有多个 APK，选择要发布的文件
   - 确认版本信息
   - 输入更新说明
   - 确认发布

4. **等待发布完成**
   - 脚本会显示发布进度
   - 完成后会弹出桌面通知
   - APK 自动归档到 `archive/` 目录

## 目录结构

```
to-publish/telecom/
├── *.apk                    # 待发布的 APK 文件
├── archive/                 # 已发布的 APK 归档
│   ├── telecom-1.0.0-100.apk
│   └── publish.log         # 发布记录日志
└── README.md               # 本文件
```

## 发布记录

所有发布记录都会保存在 `archive/publish.log` 中：

```
[2026-04-24 14:30:00] 发布成功: 1.0.0 (100) - telecom-1.0.0-100.apk
[2026-04-24 15:20:00] 发布成功: 1.0.1 (101) - telecom-1.0.1-101.apk
```

## 注意事项

⚠️ **重要提示：**
- 确保 APK 文件完整且未损坏
- 脚本会自动检测版本是否已发布
- 已发布的 APK 会自动归档，避免重复发布
- 发布过程需要网络连接到服务器

## 快捷方式

创建别名方便使用（添加到 `~/.zshrc` 或 `~/.bashrc`）：

```bash
alias pub-telecom='cd /Volumes/macOS/dev/android-test-distribution && ./publish_telecom_auto.sh'
```

然后就可以直接运行：
```bash
pub-telecom
```
