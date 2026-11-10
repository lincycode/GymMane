# 维护 EnoGym

个人版改动以 `own` 为基础。报告问题时请附上 EnoGym 版本、设备型号、Android 版本和复现步骤。原版 GymMane 的资料见 [上游仓库](https://github.com/InlitX/GymMane)。

## 开发

- 训练、统计和备份保留离线使用。应用只在用户主动检查或下载更新时访问 GitHub。
- 训练记录以用户实际确认的数据为准。涉及本地数据或备份的改动，验证旧数据可以继续读取和恢复。
- 沿用现有 Flutter 结构。页面在 `lib/screens/`，训练状态在 `lib/state/`，本地存储、备份和更新在 `lib/services/`。
- 用户可见文案通过本地化资源读取，按[翻译说明](TRANSLATING.md)维护。优先沿用已有组件与测试。

使用[维护说明](docs/OWN.md)中的工具链和构建命令。提交前运行相关测试和静态分析，界面改动需检查实际渲染。

贡献适用 [GPL-3.0](LICENSE) 和[署名条款](ADDITIONAL_TERMS.md)。
