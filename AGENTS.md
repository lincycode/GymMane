# EnoGym

默认使用简体中文。开始前阅读 README.md、PRODUCT.md、DESIGN.md、CONTRIBUTING.md、docs/OWN.md 和本次相关代码；先检查 Git 状态，保护已有改动。

- 原作者仓库是 `upstream`，个人 fork 是 `origin`。默认分支 `own` 展示 EnoGym，并作为个人版的开发和发布分支。`main` 用于对照上游。个人修改在 `own` 或从其创建的 `codex/` 功能分支完成。长期同步使用 merge，不重写已交付历史。
- 沿用 GymMane 的 Flutter、FitState、模型、离线存储、主题和训练流程。EnoLift 与 openGym 是参考，不复制其业务模型或素材进来。
- 每次决定同时考虑 UX 与 AX。优先清楚的布局、准确标签、可访问名称、稳定测试定位，不靠解释文案掩盖交互问题。
- 候选、模板和预填不等于实际记录；取消预览不写数据。不得静默覆盖周计划、轮换顺序、历史或活动训练。
- 保持备份兼容；不卸载清库，不以重置数据解决升级问题。真实数据、密钥、密码、APK、日志和截图不进入 Git。
- 新增代码遵循 CONTRIBUTING.md 的风格；界面文案使用 ARB。优先中文与英文，未翻译的新键通过现有 pending_translation_keys.txt 明确记录，不改动已有其他语言翻译。
- 个人构建身份由 own.properties 管理。com.echolin.gymmane 使用固定外部 Release 签名；Debug 使用 .debug 后缀。保留 Kotlin namespace，不全库替换包名字符串。
- 工具链与运行证据放 .toolchain/、artifacts/。维护文档放 docs/，可复用脚本放 scripts/，测试放 test/。
- 完成修改后审查完整 diff，运行相关测试、分析和构建；UI 修改必须检查实际渲染。区分原版失败、本次回归与未执行检查，不用构建通过替代视觉或真机验收。
- 只暂存本次明确文件，检查暂存 diff，运行 `git diff --cached --check` 与 `python3 scripts/check-staged-files.py`，按功能提交。
- EnoGym 个人版改动通过验证后，默认提交并推送 `own` 至 `origin/own`。用户当次要求仅本地交付时优先遵循。
- 收到用户当次明确的发布要求后，按 [维护说明](docs/OWN.md#应用内更新与发布) 创建带签名 APK、校验文件和更新清单的 GitHub Release，并验证应用内更新源。推送其他分支、发 PR、部署、强推或重写历史仍需明确授权。
- 更新日志由负责发版或同步上游的智能体维护。
  - 每次发布 EnoGym 时，一并更新 `docs/releases/<版本>.md`，用首个项目符号列表简写本版要点，供应用内更新日志和 GitHub Release 复用。
  - 发版或同步上游时核对 GymMane 的正式发布记录。发现尚未收录的新版本时，在 `docs/upstream-releases.json` 补上版本、北京时间发布日期及中英文摘要。
  - 合并上游时，同步更新 `own.properties` 的 `upstreamVersion` 和 `upstreamCommit`，以实际合入的版本基线和提交为准。
- 真机操作先协调设备使用，优先在隔离模拟器验证。不得触碰用户已有应用的数据；测试结束恢复临时调整的设备设置。
