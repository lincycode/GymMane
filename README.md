<img src="assets/brand/enogym_icon.png" width="96" alt="EnoGym 应用图标" />

# EnoGym

EnoGym 是 Enoch 基于 GymMane 定制和维护的 Android 训练记录工具。可以安排每周训练、按组记录重量和次数、查看组间休息倒计时，并回顾训练历史。

[下载 EnoGym APK](https://github.com/lincycode/GymMane/releases/latest) · [个人版维护说明](docs/OWN.md)

## 安装与更新

- 当前发布包适用于 Android 7.0 及以上的 `arm64-v8a` 设备，包括一加 Ace 6T。从 Releases 下载 `EnoGym-…-arm64-v8a-release.apk`。
- 已安装 EnoGym 时，打开 **设置 → 关于 → 检查更新**，下载后按 Android 提示确认安装。手动更新时也可用新版 APK 直接覆盖安装，保留原有训练数据。
- EnoGym 使用独立包名 `com.echolin.gymmane` 和个人版签名，可与原版 GymMane 共存。两者的安装包和本地数据分开。

## 个人版改动

- **从首页管理训练计划。** 每周安排、轮换顺序和训练方案各有入口。添加模板前可预览动作、组数与排程，确认后再写入。
- **安静的组间休息。** 移除应用主动触发的震动，保留休息结束通知和可选铃声。支持 Android 实时通知的系统可在通知栏或状态栏显示倒计时。
- **简体中文。** 补齐界面、内置动作说明、训练模板和预置菜品的中文内容。
- **个人版更新。** 通过 GitHub Releases 下载并验证同签名安装包。训练、统计和备份可离线使用。

## 源码与署名

个人版源码在默认分支 [`own`](https://github.com/lincycode/GymMane/tree/own)，构建、签名和发布流程见[维护说明](docs/OWN.md)。

**Based on GymMane by InlitX.** EnoGym 的定制与维护由 Enoch 完成。原项目与原版文档见 [InlitX/GymMane](https://github.com/InlitX/GymMane)。

源码按 [GPL-3.0](LICENSE) 发布，适用[署名条款](ADDITIONAL_TERMS.md)。动作插图、字体及其他素材的来源和许可证见 [CREDITS.md](CREDITS.md)。
