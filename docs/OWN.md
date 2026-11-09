# EnoGym 维护说明

个人版始于 GymMane v2.1.0，当前已合入 upstream/main 的 532827f4b04d7af14b9031ac489f0fcce0dd1c74（2026-11-08 核实），保留上游 Flutter 结构与离线数据格式。原版 README 和 CONTRIBUTING 继续适用；以下记录个人版差异。

## 使用与范围

- 首页周概览附近的「管理训练计划」进入计划页。
- 「从模板创建」浏览原有 10 套模板，点击后预览动作、组数及安排影响，确认才添加。
- 固定周且安排为空时可勾选「同时安排到空白周计划」。已有周计划、日期调整或轮换模式只添加训练方案，不覆盖安排。
- 模板是可编辑参考，不是已完成训练；未知动作阻止整套添加。取消预览不写数据。
- 「每周安排 / 轮换顺序」「我的训练方案」「计划模板」「已保存周计划」区分不同层级。
- 不迁移 EnoLift 的计划、动作库或历史。原应用与备份保留；个人版从空历史开始。
- 日期循环、多周 Programme、自动进阶改造不在首轮范围。GymMane 原有训练、计时、主题和其他功能保留。

## 个人品牌与署名

显示名为 **EnoGym**，定制与维护为 **Enoch**。关于页保留「基于 InlitX 开发的 GymMane」、原作者与原项目链接；不能把原有代码和素材的作者改署为个人原创。

启动器图标采用 Enoch 于 2026-11-08 提供的第二张设计：米白跑者与斜体 E 融合，右下角为红色点缀。原稿完整保存在 `assets/brand/enogym_source.png`。内置图像工具只用于分离前景，去掉外部白边和预绘制圆角背景；Android 使用深色底和系统图标遮罩，避免双重圆角或白边。前景、图内负空间与红色元素的构图保留，平台缩放不重绘图案。PNG 元数据记录来源与处理方式。原始 `assets/icon/`、训练插图、字体和成就系统保留，项目许可证与原作者署名保留。

重新生成图标：

```bash
.toolchain/flutter/bin/dart --packages=.dart_tool/package_config.json scripts/generate_brand_assets.dart
bash scripts/flutter.sh pub run flutter_launcher_icons -f own-launcher-icons.yaml
.toolchain/flutter/bin/dart --packages=.dart_tool/package_config.json scripts/generate_brand_assets.dart --stamp-android
```

图标工具使用锁文件中已有的 `image` 传递依赖，不增加应用依赖。`--stamp-android` 补充平台 PNG 的来源元数据，检查深浅背景和实际桌面大小。应用、分享卡片、小组件、通知及导出文档显示 EnoGym；内部存储键、备份格式和组件类名保持原值，旧备份仍可读取。既有用户资料不自动改名，新用户默认名称为 Enoch。

## 构建

使用 Flutter **3.41.9 / Dart 3.11.5**、Java 17 和 Android SDK 36。Flutter 安装到 `.toolchain/flutter`，也可设置 `GYMMANE_FLUTTER` 指定可执行文件。`.toolchain/env.sh` 可保存本机 JAVA_HOME、ANDROID_HOME 等工具路径，禁止提交。

```bash
bash scripts/flutter.sh pub get --enforce-lockfile
bash scripts/flutter.sh gen-l10n
bash scripts/flutter.sh analyze --no-fatal-infos
bash scripts/flutter.sh test
python3 scripts/setup-own-signing.py
bash scripts/build-own.sh release
```

`setup-own-signing.py` 使用当前 JAVA_HOME。默认签名位置是 `~/.local/share/gymmane-own/`，也可通过 `GYMMANE_SIGNING_PROPERTIES` 指定仓库外的 properties 文件。脚本不会覆盖已有密钥或输出密码。请将整个签名目录安全备份；遗失私钥后无法给既有安装做同签名升级。

`own.properties` 是 applicationId、名称、版本和上游基线的事实来源。发新包先递增 versionCode，再使用构建脚本；脚本把版本传入 Dart 关于页。ABI 分包沿用上游规则：Android 实际版本码 = versionCode × 10 + ABI 编号（arm64 为 2）。

Release 包名 `com.echolin.gymmane`，Debug 包名 `com.echolin.gymmane.debug`，与官方 `com.gymmane.app` 及 EnoLift 隔离。Kotlin namespace 继续为 `com.gymmane.app`；它是组件类路径，不是安装包身份。小组件使用完整类名与当前应用 Context，通知使用显式目标组件，不能批量改掉这些引用。

个人打包脚本只构建一加 Ace 6T 使用的 `arm64-v8a` 包。正式产物位于 `artifacts/apk/EnoGym-<版本>-Ace6T-arm64-v8a-release.apk`。正式构建缺少专用签名会失败，不退回 Debug 签名。测试包与正式包不共享数据。

## 上游同步

- origin: https://github.com/lincycode/GymMane
- upstream: https://github.com/InlitX/GymMane
- main: 上游镜像，不提交个人改动。
- own: 已验证个人版。
- codex/功能名、codex/sync-版本: 短期开发与同步分支。

先提交当前工作，再获取更新。main 可以跟随上游最新代码，个人版通常优先合并稳定标签；本轮按明确要求合入 main 的 532827f，并记录完整提交身份。

```bash
git fetch upstream --tags
git switch main
git merge --ff-only upstream/main
git switch own
git switch -c codex/sync-版本
git merge --no-ff 上游稳定标签
```

审查冲突、数据格式及所有个人改动的行为；运行完整测试、Release 构建、备份恢复和同签名覆盖升级。通过后回到 own 合并同步分支。新增上游功能不是自动启用个人新规则的理由。

观察 Releases 及与计划、记录、备份相关的 Issues/PR。只有已落地的提交可合入；紧急 cherry-pick 要记录原始提交和依赖。不要对长期 own 反复 rebase。

代码回退不等于数据回退。升级前导出备份；若上游升级数据格式，不能直接降级 APK，优先修复后继续向前升级。GitHub fork 的创建不代表个人提交已经上传，push 与发布需另行授权。

## 验收与证据

自动检查覆盖模板预览、取消、重复确认、缺失动作、排程保护和原有测试；Android 验收覆盖原版共存、桌面小组件、通知、后台恢复、备份和覆盖升级。截图只证明静态布局，模拟器不代替真实手机手感、后台策略与长期使用。

每次结果记录到 `artifacts/qa/`，简短结论放 `docs/validation/`。原版基线在隔离副本中验证；不能把既有失败记成本次回归，也不能掩盖本次引入的失败。

## 许可证

保留 LICENSE、ADDITIONAL_TERMS.md、CREDITS.md 和字体许可证。关于页显示「基于 InlitX 开发的 GymMane」，保留原作者和原项目链接，并单列个人版源码。openGym 只作为产品参考，本轮没有引入其代码、动作文字或受限制媒体。
