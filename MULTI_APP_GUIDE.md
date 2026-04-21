# Android 测试分发平台 - 多应用支持指南

## 概述

平台现已升级支持多应用分发，每个应用拥有独立的版本历史和 APK 存储，同时保持向后兼容性。

## 目录结构

```
data/
├── index.html                 # 应用选择主页（新建）
├── apps.json                 # 应用配置清单（新建）
├── apps/                     # 应用根目录（新建）
│   ├── telecom/              # Telecom 应用
│   │   ├── index.html        # 应用下载页
│   │   ├── apk/
│   │   ├── qr/
│   │   ├── latest.json
│   │   └── versions.json
│   └── store/               # Store 应用
│       └── ...
├── apk/                      # 向后兼容（映射到 telecom）
├── qr/                       # 向后兼容（映射到 telecom）
├── latest.json              # 向后兼容（映射到 telecom）
└── versions.json            # 向后兼容（映射到 telecom）
```

## URL 访问规则

### 新的多应用路由
- **应用选择页**: `http://your-server/android/`
- **应用下载页**: `http://your-server/android/{app_id}/`
- **应用最新版本**: `http://your-server/android/{app_id}/latest.json`
- **应用历史版本**: `http://your-server/android/{app_id}/versions.json`
- **APK 下载**: `http://your-server/android/{app_id}/apk/{filename}.apk`
- **二维码图片**: `http://your-server/android/{app_id}/qr/latest.png`

### 向后兼容路由（映射到 telecom 应用）
- `http://your-server/android/latest.json` → telecom/latest.json
- `http://your-server/android/versions.json` → telecom/versions.json
- `http://your-server/android/apk/` → telecom/apk/
- `http://your-server/android/qr/` → telecom/qr/

## 发布新版本

### 方式 1：使用 publish_android_test.sh（保持兼容）

发布到默认应用（telecom）：
```bash
./publish_android_test.sh app-release.apk 1.0.0 100 "修复已知问题"
```

发布到指定应用：
```bash
./publish_android_test.sh telecom app-release.apk 1.0.0 100 "修复已知问题"
./publish_android_test.sh store store-release.apk 2.0.0 200 "新增功能"
```

### 方式 2：使用 publish_multi.sh（推荐）

专门用于多应用发布的脚本，参数更清晰：

```bash
./publish_multi.sh <app_id> <apk_path> <versionName> <versionCode> <changelog>
```

示例：
```bash
# 发布 telecom 应用
./publish_multi.sh telecom app-release.apk 1.0.0 100 "修复已知问题"

# 发布 store 应用
./publish_multi.sh store store-release.apk 2.0.0 200 "新增功能"
```

## 添加新应用

### 步骤 1：创建应用目录

```bash
mkdir -p data/apps/newapp/apk
mkdir -p data/apps/newapp/qr
```

### 步骤 2：更新应用配置

编辑 `data/apps.json`，在 `apps` 数组中添加：

```json
{
  "id": "newapp",
  "name": "新应用",
  "description": "新应用测试版",
  "icon": "📱",
  "color": "#667eea"
}
```

### 步骤 3：创建应用下载页

```bash
cp data/apps/telecom/index.html data/apps/newapp/index.html
```

### 步骤 4：发布第一个版本

```bash
./publish_multi.sh newapp newapp-1.0.0.apk 1.0.0 100 "首个版本"
```

### 步骤 5：同步到服务器

脚本会自动同步到服务器，完成后访问 `http://your-server/android/` 即可看到新应用。

## 应用配置说明

`data/apps.json` 配置格式：

```json
{
  "defaultApp": "telecom",
  "apps": [
    {
      "id": "telecom",           // 应用ID（用于URL路径，只能包含字母、数字、下划线、连字符）
      "name": "Telecom",          // 应用显示名称
      "description": "Telecom 应用测试版",  // 应用描述
      "icon": "📞",               // 应用图标（emoji）
      "color": "#667eea"          // 主题色（用于卡片边框）
    }
  ]
}
```

## 迁移说明

### 现有单应用迁移到多应用

如果之前是单应用模式，迁移步骤：

1. **确定应用ID**：选择一个应用ID（如：telecom, myapp 等）
2. **目录已自动创建**：脚本已自动迁移数据到 `data/apps/{app_id}/`
3. **更新 apps.json**：确保默认应用ID正确
4. **测试访问**：
   - 访问 `/android/` 应显示应用选择页
   - 访问 `/android/latest.json` 应返回默认应用数据（向后兼容）
   - 访问 `/android/{app_id}/` 应显示应用下载页

### 保持向后兼容性

原有的 URL 和访问方式仍然有效：
- `/android/latest.json` → 返回默认应用（telecom）的数据
- `/android/` → 显示应用选择页（不再是单应用页）
- 旧的下载链接仍然有效

## 测试验证

### 本地测试

启动本地环境：
```bash
docker-compose up -d
```

访问测试：
- 应用选择页: http://localhost:8080/android/
- Telecom 应用: http://localhost:8080/android/telecom/
- Store 应用: http://localhost:8080/android/store/
- 向后兼容测试: http://localhost:8080/android/latest.json

### 服务器测试

同步到服务器后，使用服务器的域名或 IP 进行相同的测试。

## 常见问题

### Q: 如何修改默认应用？
A: 编辑 `data/apps.json`，修改 `defaultApp` 字段为应用ID。

### Q: 应用ID有限制吗？
A: 只能包含字母、数字、下划线和连字符（`[a-zA-Z0-9_-]+`）。

### Q: 可以删除应用吗？
A: 可以，删除 `data/apps/{app_id}` 目录并从 `apps.json` 中移除对应配置即可。

### Q: 如何重命名应用？
A: 重命名目录，同时更新 `apps.json` 中的应用配置。

### Q: 旧的用户链接会失效吗？
A: 不会。原有的 `/android/latest.json` 和 `/android/apk/` 路径仍然有效，会重定向到默认应用。

## 技术架构

### Nginx 路由

- **多应用路由**（优先级高）：正则匹配 `/android/{app_id}/` 路径
- **向后兼容路由**（优先级低）：固定路径映射到默认应用
- **应用选择路由**：根路径 `/android/` 显示应用选择页

### 静态文件

- 纯静态架构，无需后端服务器
- JSON 文件存储版本信息
- HTML 页面通过 JavaScript 动态加载数据

### 发布流程

1. 脚本验证参数和文件
2. 复制 APK 到应用目录
3. 生成/更新 latest.json 和 versions.json
4. 生成二维码图片
5. 同步到服务器（rsync）

## 优势总结

✅ **完全隔离**：每个应用独立的版本历史和 APK 存储
✅ **易于扩展**：添加新应用只需创建目录和更新配置
✅ **向后兼容**：保留现有访问方式，无需通知所有测试人员
✅ **统一体验**：所有应用使用相同的界面风格
✅ **保持简单**：继续使用静态文件 + Docker，无后端依赖
