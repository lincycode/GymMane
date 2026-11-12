# EnoGym 维护说明

个人版始于 GymMane v2.1.0，当前已合入 GymMane v2.2.0 的 a4f660153567ae300f6daa002615f572708117eb（2026-11-12 核实），保留上游 Flutter 结构与离线数据格式。个人版的下载和更新使用本仓库的 GitHub Releases。原版介绍、商店资料和下载渠道见 [InlitX/GymMane](https://github.com/InlitX/GymMane)。

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

上游加入 iOS 工程后，macOS 上的 `flutter pub get` 会同时准备 iOS 插件，需要完整的 Xcode 15 或以上。如果只安装了 Xcode Command Line Tools，且 `pub get` 已显示 `Got dependencies!`、仅在准备 iOS 插件时失败，可用 `bash scripts/build-own.sh release --no-pub` 构建 Android；测试和分析同样可加 `--no-pub`。依赖准备本身失败时需先解决依赖问题。

`setup-own-signing.py` 使用当前 JAVA_HOME。默认签名位置是 `~/.local/share/gymmane-own/`，也可通过 `GYMMANE_SIGNING_PROPERTIES` 指定仓库外的 properties 文件。脚本不会覆盖已有密钥或输出密码。请将整个签名目录安全备份；遗失私钥后无法给既有安装做同签名升级。

`own.properties` 是 applicationId、名称、版本和上游基线的事实来源。发新包先递增 versionCode，再使用构建脚本；脚本把版本传入 Dart 关于页。ABI 分包沿用上游规则：Android 实际版本码 = versionCode × 10 + ABI 编号（arm64 为 2）。

Release 包名 `com.echolin.gymmane`，Debug 包名 `com.echolin.gymmane.debug`，与官方 `com.gymmane.app` 及 EnoLift 隔离。Kotlin namespace 继续为 `com.gymmane.app`；它是组件类路径，不是安装包身份。小组件使用完整类名与当前应用 Context，通知使用显式目标组件，不能批量改掉这些引用。

个人打包脚本只构建一加 Ace 6T 使用的 `arm64-v8a` 包。正式产物位于 `artifacts/apk/EnoGym-<版本>-Ace6T-arm64-v8a-release.apk`。正式构建缺少专用签名会失败，不退回 Debug 签名。测试包与正式包不共享数据。

## 应用内更新与发布

「设置 → 关于 → 更新日志」可以离线查看 EnoGym 和 GymMane 的版本记录。EnoGym 卡片显示当前安装版本，GymMane 卡片显示随包收录的最新上游发布；上游标签和合入提交从 `own.properties` 读取。两页都可以直接打开 GitHub 查看最新发布。

- **EnoGym** 复用 `docs/releases/<版本>.md`。每次发版在原文件中用首个 `- ` 列表写简短更新要点，安装和升级说明另起一段。旧版纯段落说明取首段。应用只展示不晚于当前安装版本的条目。
- **GymMane** 有新正式发布时，依据 [原作者发布页](https://github.com/InlitX/GymMane/releases) 在 [上游摘要](upstream-releases.json) 顶部加入新版本、北京时间发布日期和中英文要点。仅合并主分支提交时按常规更新 `own.properties`，无须另造一个发布条目。

从 `2.1.0-own.7` 起，设置 → 关于 → 检查更新提供个人版更新。只有点击检查时才请求 GitHub；不后台轮询、不上传训练记录、不内置 GitHub token。上游 CONTRIBUTING 的禁止联网原则在个人版仅对这一功能例外，训练与本地数据功能保持离线。网络失败可重试或打开 Releases 页面。

首次建议安装 `2.1.0-own.8` 或以上。own.7 使用浏览器下载 URL，在本次网络环境中遭遇 GitHub 主站连接超时；own.8 改用公开 Release asset API 和 `Accept: application/octet-stream`，同时校验资源 ID、所属仓库和浏览器 URL，处理官方 CDN 重定向。不添加代理或第三方镜像，仍需设备能访问 GitHub API 和下载 CDN。

更新源固定为公开仓库 `lincycode/GymMane` 的 latest Release。每个 Release 使用 `enogym-v<versionName>` 标签，指向经过验证的 `own` 提交，并包含 arm64 APK、同名 `.sha256` 和 `enogym-update.json`。个人版标签中的 `own` 不代表 GitHub prerelease；正式更新发布为非草稿、非 prerelease。更新清单使用 Android 实际版本码（如 own.7 的 arm64 为 72），不只比较上游版本字符串。

`2.1.0-own.10` 是过渡版，更新器和发布脚本同时支持 `2.1.0-own.N` 与 `1.0.0` 形式。EnoGym 从 `1.0.0` 开始独立编号。上游版本与提交记录在 `own.properties`。从旧版通过应用内更新切到独立编号，需要先装过渡版。也可以手动覆盖安装独立编号的 APK。Android 版本码沿用同一递增序列。

应用检查发布身份、ABI、最低系统版本和大小，流式下载到专用缓存目录，校验 SHA-256、包名、版本和当前签名。安装通过系统安装器确认，首次可能需要允许 EnoGym 安装未知应用，返回后再次点击安装。正在训练时不安装；退出弹窗会取消未完成的下载。已下载且校验通过的包可复用，更新后再次检查会清理旧更新缓存，不接触训练数据。

首次使用需手动覆盖安装包含更新功能的 APK。不能卸载清数据，也不能使用原作者包或 Debug 包来覆盖。真实厂商系统的安装授权与后台行为仍需实机验收。

平时完成验证后，将本次改动提交并推送到 `origin/own`。收到用户明确的发布要求后，再按以下流程创建 GitHub Release，让手机可以在应用里检查更新。

1. 在 `own` 修改，递增 `own.properties` 的 versionName 和 versionCode，保留包名与固定签名。更新 `docs/releases/<版本>.md`。
2. 运行相关测试、完整分析，使用 `bash scripts/build-own.sh release --no-pub` 构建。仅在依赖已正确准备后使用 `--no-pub`。验证同签名升级和数据保留，审查并提交相关源码。
3. 加载本机工具环境后准备发布文件：

   ```bash
   source .toolchain/env.sh
   python3 scripts/prepare-own-release.py --previous-apk artifacts/apk/上一版.apk
   ```

   工具会从 APK 读取包名、版本、最低 SDK、ABI 和签名并核对配置，输出 `artifacts/releases/<版本>/`。`--previous-apk` 用于确认签名连续性。准备应在最后一次提交后执行，以记录正确的源码提交。

4. 推送个人分支并发布：

   ```bash
   bash scripts/publish-own-release.sh docs/releases/<版本>.md
   ```

   脚本只接受干净的 `own`。它先核对上一版的版本码和签名。若本地更新清单的 SHA-256 与 GitHub 上的资源一致，就用这份副本完成校验。通过后推送 `own` 至 `origin/own`，创建带全部资源的草稿 Release，再发布为 latest。它不更改 `main` 或默认分支，不强推，不覆盖已有 Release。若草稿阶段失败，检查并补齐该草稿后再发布，避免重复版本。

5. 确认 latest API 返回本版，并通过应用使用的资源 API 下载更新清单和 APK，核对 SHA-256。涉及更新器或安装兼容性时，用旧版模拟器走完整的检查、下载和覆盖安装流程，并核对数据。

当前沿用本机专用密钥签名，密钥不上传 GitHub。上游 `.github/workflows/build-apk.yml` 的签名路径和版本来源不是个人版发布流程，请勿直接用于发布 EnoGym；个人版目前使用上述脚本。`own` 是 GitHub 默认分支，承载个人版源码、首页和发布。`main` 用于对照上游。手机更新读取同一仓库的 latest Release。

## 共享文件夹同步

原作者的自托管 Web 版和服务器源码随上游合并。Android 客户端仍用本地存储，只有在「数据与备份 → 自动备份」主动开启「共享文件夹同步」后，才会扫描共享文件夹中的其他设备备份。Syncthing 由用户另行配置。关闭时沿用原有 `gymmane-auto-` ZIP 命名、目录和保留数量。进行中或暂停的训练会阻止同步合并。APK 更新仍使用 EnoGym 的 GitHub Release。

普通备份只清理不含设备标识的标准备份名；同步模式只清理本设备的备份。两种文件可以共存，不会互相轮转删除。

同步按快照合并记录，没有逐条记录的修改时间。手机存在尚未备份的本地编辑（或尚未建立备份基线）时，同一记录和设置保留本地值，只合入其他设备的新记录。手机状态与最近成功备份一致时，较新的远端快照可以更新冲突项。服务端以实际保存时间比较，保存期间发生新编辑则拒绝本次合并并等待重试。缺省偏好按所选快照恢复默认，记录集合仍保留两端内容；删除不跨设备传播。需要用某份备份完整替换时，继续使用手动导入。

同步涉及的照片必须写入成功后才应用数据、标记已处理；失败保留重试机会，并清理本次未使用的新文件。相同内容复用本地文件，不覆盖同名的其他图片。不会批量清理旧版本已留下的媒体，以免误删仍在使用的文件。

## 上游同步

- origin: https://github.com/lincycode/GymMane
- upstream: https://github.com/InlitX/GymMane
- `own`：个人版默认分支。GitHub 首页从此分支读取 README。
- `main`：上游对照分支。本地 `main` 跟踪 `upstream/main`。
- codex/功能名、codex/sync-版本: 短期开发与同步分支。

先提交当前工作，再获取更新。main 可以跟随上游最新代码，个人版通常优先合并稳定标签；如明确要求合入 main，固定待合并的提交并记录完整提交身份。

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

升级前导出备份。若上游升级数据格式，优先修复后继续向前升级，直接降级 APK 可能无法读取新版数据。合入个人版的功能更新通过验收后推送 `own`，发布时遵循用户当次要求。

## 验收与证据

自动检查覆盖模板预览、取消、重复确认、缺失动作、排程保护和原有测试；Android 验收覆盖原版共存、桌面小组件、通知、后台恢复、备份和覆盖升级。截图只证明静态布局，模拟器不代替真实手机手感、后台策略与长期使用。

每次结果记录到 `artifacts/qa/`，简短结论放 `docs/validation/`。原版基线在隔离副本中验证；不能把既有失败记成本次回归，也不能掩盖本次引入的失败。

## 许可证

保留 LICENSE、ADDITIONAL_TERMS.md、CREDITS.md 和字体许可证。关于页显示「基于 InlitX 开发的 GymMane」，保留原作者和原项目链接，并单列个人版源码。openGym 只作为产品参考，本轮没有引入其代码、动作文字或受限制媒体。
