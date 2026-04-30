#!/usr/bin/env python3
"""
从 APK 文件中提取版本信息
支持多种方法提取 versionName 和 versionCode
"""

import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

def extract_with_zipfile(apk_path):
    """尝试从 APK 的 AndroidManifest.xml 中提取信息（文本格式）"""
    try:
        with zipfile.ZipFile(apk_path, 'r') as zf:
            # 尝试读取 AndroidManifest.xml
            manifest_data = zf.read('AndroidManifest.xml')

            # 检查是否是文本格式（某些构建工具会生成文本格式的 manifest）
            try:
                manifest_str = manifest_data.decode('utf-8')
                # 简单的文本搜索
                import re
                version_name_match = re.search(r'versionName="([^"]+)"', manifest_str)
                version_code_match = re.search(r'versionCode="([^"]+)"', manifest_str)
                package_name_match = re.search(r'package="([^"]+)"', manifest_str)

                if version_name_match and version_code_match:
                    return {
                        'versionName': version_name_match.group(1),
                        'versionCode': version_code_match.group(1),
                        'packageName': package_name_match.group(1) if package_name_match else 'unknown'
                    }
            except UnicodeDecodeError:
                pass  # 不是文本格式，继续尝试其他方法
    except Exception as e:
        print(f"Error reading ZIP: {e}", file=sys.stderr)

    return None

def extract_from_apk_tool_output(apk_path):
    """
    尝试使用 aapt/apktool 的输出
    这个方法会在脚本中被调用
    """
    return None

def main():
    if len(sys.argv) < 2:
        print("Usage: extract_apk_info.py <apk_file>")
        sys.exit(1)

    apk_path = sys.argv[1]

    if not Path(apk_path).exists():
        print(f"Error: APK file not found: {apk_path}", file=sys.stderr)
        sys.exit(1)

    # 方法1: 尝试直接读取文本格式的 manifest
    info = extract_with_zipfile(apk_path)
    if info:
        print(f"{info['versionName']}|{info['versionCode']}|{info['packageName']}")
        return

    # 方法2: 尝试使用 aapt
    import subprocess
    aapt_paths = [
        '/opt/homebrew/bin/aapt',
        '/opt/homebrew/share/android-commandlinetools/build-tools/34.0.0/aapt',
        'aapt'
    ]

    for aapt_path in aapt_paths:
        try:
            result = subprocess.run(
                [aapt_path, 'dump', 'badging', apk_path],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                import re
                version_name = re.search(r"name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", result.stdout)
                if version_name:
                    version_code = version_name.group(2)
                    v_name = version_name.group(3)
                    package_match = re.search(r"package: name='([^']+)'", result.stdout)
                    package = package_match.group(1) if package_match else 'unknown'
                    print(f"{v_name}|{version_code}|{package}")
                    return
        except FileNotFoundError:
            continue  # 尝试下一个 aapt 路径
        except Exception as e:
            print(f"Error running aapt ({aapt_path}): {e}", file=sys.stderr)
            continue

    # 方法3: 尝试使用 aapt2
    try:
        result = subprocess.run(
            ['aapt2', 'dump', 'badging', apk_path],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            import re
            version_name = re.search(r"name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", result.stdout)
            if version_name:
                version_code = version_name.group(2)
                v_name = version_name.group(3)
                package_match = re.search(r"package: name='([^']+)'", result.stdout)
                package = package_match.group(1) if package_match else 'unknown'
                print(f"{v_name}|{version_code}|{package}")
                return
    except FileNotFoundError:
        pass  # aapt2 不可用
    except Exception as e:
        print(f"Error running aapt2: {e}", file=sys.stderr)

    # 如果所有方法都失败，输出错误信息
    print("Error: Could not extract version info from APK", file=sys.stderr)
    print("Please install Android SDK build-tools to get aapt, or use aapt/apktool", file=sys.stderr)
    sys.exit(1)

if __name__ == '__main__':
    main()
