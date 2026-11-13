# 鼠尾草白浅色主题验收

2026-11-13。用户对比首页、训练记录、计划、进度、动作库与设置后，确认将「鼠尾草白」落实到 EnoGym 浅色主题。

## 变更

- 仅调整 `GymColors.light` 的页面、内容面、边界、文字、主操作与强调色，采用已确认的浅灰绿背景、白色卡片和深松绿按钮。同步 `DESIGN.md`。
- 深色和 AMOLED、成功/警告/错误等状态色、计划卡片自定义色与出勤热力图独立色阶未改动。布局、字体、导航、持久化和主题偏好逻辑未改动。
- 更新既有主题测试的暖色断言，并检查页面、卡片、次级内容面与选中背景上的文字和强调色对比度。未新增主题选项或改变用户的主题选择。

## 已执行

| 检查 | 结果 |
| --- | --- |
| `bash scripts/flutter.sh test --no-pub test/theme_test.dart test/settings_test.dart test/smoke_test.dart test/template_preview_test.dart --reporter expanded` | 46 项通过 |
| 正式 `GymManeApp` 入口渲染，使用模拟存储与合成训练记录 | 13 项通过：浅色 7 页，深色和 AMOLED 各 3 页 |
| 浅色首页、训练记录、计划、进度、动作库、设置、通用设置截图检查 | 已检查，配色与选定预览一致 |
| 深色和 AMOLED 首页截图检查 | 已检查，保留原配色 |
| `bash scripts/flutter.sh analyze --no-pub --no-fatal-infos` | 最终无问题 |
| `bash scripts/build-own.sh debug --no-pub` | Android arm64 Debug APK 构建成功 |
| `git diff --check` | 通过 |

截图和本地渲染脚本位于 `artifacts/qa/2026-11-13-sage-theme/`，不入 Git。首次全项目分析检查到了本轮放在 `artifacts/` 的测试截图脚本；已补充仅测试用途标注并修正格式提示，复核无问题。

Debug 产物为 `artifacts/apk/EnoGym-1.0.6-Ace6T-arm64-v8a-debug.apk`，SHA-256：`9656e59262008be95a04d640fc96b49d9bcb69b808fa895dee6614106aebfd4a`。本轮没有发布请求，保留当前版本号，只构建验证用测试包。

## 验证边界

未安装或操作真机，未执行手机长期训练验收，也未创建 GitHub Release。截图通过 Flutter 测试渲染器生成；为显示中文，截图脚本使用本机字体替代，生产字体配置未改动。没有将演示数据写入应用初始化或真实存储。构建输出的未翻译消息提示属于现有本地化内容，本轮未新增或修改文案。
