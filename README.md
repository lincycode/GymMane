<img src="assets/brand/enogym_icon.png" width="96" alt="EnoGym 应用图标" />

# EnoGym

Enoch 维护的 Android 训练记录工具。可以安排每周训练，按组记录重量和次数，查看组间休息倒计时，再回顾训练历史。

[下载 EnoGym](https://github.com/lincycode/GymMane/releases/latest) · [维护说明](docs/OWN.md)

## EnoGym 的改动

- **训练计划**从首页进入。每周安排、轮换顺序和训练方案各有入口。导入模板前可预览动作、组数和排程，确认后才写入。
- **组间休息**移除了应用触发的震动，保留无声通知和可选铃声。支持 Android 实时通知的设备可在通知栏或状态栏查看倒计时。
- **简体中文**补齐了界面文案、动作说明、训练模板和预置菜品。
- **个人版更新**可在应用内检查、下载并验证安装包。训练、统计和备份可离线使用。

## 上游同步

已合并原作者 GymMane 主分支 `f7fd2ba`，包括可自托管的 Web 版、宽屏布局、Wear OS 更新和 Android 步数修复。自托管说明见 [SELFHOST.md](SELFHOST.md)。EnoGym 的 Android 版仍可离线使用，共享文件夹同步默认关闭。

## 安装与更新

下载 Release 中的 `arm64-v8a` APK，适用于 Android 7.0 及以上的 arm64 设备。已安装 EnoGym 时，在 **设置 → 关于 → 检查更新** 下载新版，然后按 Android 提示安装。手动更新也可直接覆盖安装，保留训练记录。

## 来源与许可

**Based on GymMane by InlitX.** EnoGym 基于 [GymMane](https://github.com/InlitX/GymMane) 开发，由本仓库独立维护与发布。感谢原作者 InlitX 和所有贡献者。

代码遵循 [GPL-3.0 许可证](LICENSE)，保留原有版权声明、贡献记录和各项依赖的许可。署名要求和素材许可见 [附加条款](ADDITIONAL_TERMS.md) 与 [贡献与素材来源](CREDITS.md)。
