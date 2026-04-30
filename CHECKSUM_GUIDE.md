# APK SHA256 校验使用指南

## 📱 从网页获取校验和

### 访问下载页面
```
http://43.136.56.11:8080/android/telecom/
```

### 复制校验和
1. 在页面上找到 **🔐 SHA256校验和** 部分
2. 点击 **📋 复制** 按钮
3. 校验和已复制到剪贴板

---

## 🔐 校验方法

### 方法 1：交互式校验（最简单）⭐

**适合：** 不熟悉命令行的用户

```bash
# 运行交互式脚本
./verify_apk_simple.sh
```

**操作步骤：**
1. 拖拽 APK 文件到终端窗口
2. 按 Enter
3. 粘贴网页上的校验和
4. 按 Enter
5. 查看校验结果

**示例输出：**
```
======================================
   APK SHA256 校验工具
======================================

请输入 APK 文件路径（可直接拖拽文件）: ~/Downloads/telecom-5.10.51-50100051.apk

正在计算 SHA256 校验和...

计算结果:
  文件: telecom-5.10.51-50100051.apk
  SHA256: 970aa31f809bd8b4c69b75cba09c0e869e9a5de0ad022b131b6b1b7998c31fbd

请输入网页上的校验和（或按 Enter 仅复制计算结果）: 970aa31f809bd8b4c69b75cba09c0e869e9a5de0ad022b131b6b1b7998c31fbd

======================================
✓ 校验成功！文件完整且未被篡改
```

---

### 方法 2：命令行校验（快速）⚡

**适合：** 熟悉命令行的用户

#### 使用 verify_apk.sh

```bash
./verify_apk.sh <apk文件> <校验和>
```

**示例：**
```bash
./verify_apk.sh \
  ~/Downloads/telecom-5.10.51-50100051.apk \
  970aa31f809bd8b4c69b75cba09c0e869e9a5de0ad022b131b6b1b7998c31fbd
```

#### 使用 shasum 命令

```bash
# 计算校验和
shasum -a 256 telecom-5.10.51-50100051.apk

# 输出：
# 970aa31f809bd8b4c69b75cba09c0e869e9a5de0ad022b131b6b1b7998c31fbd  telecom-5.10.51-50100051.apk

# 对比：复制前面的哈希值，与网页上的校验和对比
```

---

## 🪟 Windows 用户

### PowerShell

```powershell
# 1. 打开 PowerShell，进入下载目录
cd Downloads

# 2. 计算 SHA256
certutil -hashfile telecom-5.10.51-50100051.apk SHA256

# 3. 对比输出的哈希值
```

### 使用第三方工具

- **7-Zip**: 右键文件 → CRC SHA → SHA-256
- **HashTab**: 安装后直接在文件属性中查看
- **WinSHA256**: 简单的哈希计算工具

---

## 📋 完整示例流程

### 场景：下载并验证 APK

```bash
# 1. 下载 APK
wget http://43.136.56.11:8080/android/telecom/apk/telecom-5.10.51-50100051.apk

# 2. 访问网页，复制校验和
open http://43.136.56.11:8080/android/telecom/
# 点击 📋 复制 按钮

# 3. 运行校验脚本
./verify_apk.sh \
  telecom-5.10.51-50100051.apk \
  970aa31f809bd8b4c69b75cba09c0e869e9a5de0ad022b131b6b1b7998c31fbd

# 4. 查看结果
# ✓ 文件校验成功！APK 文件完整且未被篡改。
```

---

## ❓ 常见问题

### Q1: 校验失败怎么办？

**可能原因：**
1. 下载未完成
2. 网络传输错误
3. 文件被篡改

**解决方法：**
```bash
# 重新下载
rm telecom-5.10.51-50100051.apk
wget http://43.136.56.11:8080/android/telecom/apk/telecom-5.10.51-50100051.apk

# 再次校验
./verify_apk.sh telecom-5.10.51-50100051.apk <校验和>
```

### Q2: 网页上没有校验和怎么办？

**可能原因：**
- 旧版本数据没有校验和字段

**解决方法：**
```bash
# 只计算哈希值，用于自己验证文件完整性
shasum -a 256 telecom-5.10.51-50100051.apk
```

### Q3: 校验和不完整怎么办？

**SHA256 校验和是 64 位十六进制字符**

完整示例：
```
970aa31f809bd8b4c69b75cba09c0e869e9a5de0ad022b131b6b1b7998c31fbd
```

如果复制时不完整，重新点击 **📋 复制** 按钮。

---

## 🛡️ 安全建议

1. **总是校验**: 下载 APK 后养成校验习惯
2. **来源可信**: 只从可信来源下载
3. **及时更新**: 使用最新版本
4. **报告问题**: 发现校验失败及时报告

---

## 📞 获取帮助

如有问题，请联系开发团队或查看文档：
- 项目目录：`/Volumes/macOS/dev/android-test-distribution/`
- 校验脚本：`./verify_apk.sh` 或 `./verify_apk_simple.sh`
