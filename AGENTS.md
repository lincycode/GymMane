# EnoGym

默认使用简体中文。开始前阅读 README.md、PRODUCT.md、DESIGN.md、CONTRIBUTING.md、docs/OWN.md 和本次相关代码；先检查 Git 状态，保护已有改动。

- 原作者仓库是 upstream，个人 fork 是 origin。main 只跟随上游；个人修改在 own 或从 own 创建的 codex/ 功能分支上完成。长期同步使用 merge，不重写已交付历史。
- 沿用 GymMane 的 Flutter、FitState、模型、离线存储、主题和训练流程。EnoLift 与 openGym 是参考，不复制其业务模型或素材进来。
- 每次决定同时考虑 UX 与 AX。优先清楚的布局、准确标签、可访问名称、稳定测试定位，不靠解释文案掩盖交互问题。
- 候选、模板和预填不等于实际记录；取消预览不写数据。不得静默覆盖周计划、轮换顺序、历史或活动训练。
- 保持备份兼容；不卸载清库，不以重置数据解决升级问题。真实数据、密钥、密码、APK、日志和截图不进入 Git。
- 新增代码遵循 CONTRIBUTING.md 的风格；界面文案使用 ARB。优先中文与英文，未翻译的新键通过现有 pending_translation_keys.txt 明确记录，不改动已有其他语言翻译。
- 个人构建身份由 own.properties 管理。com.echolin.gymmane 使用固定外部 Release 签名；Debug 使用 .debug 后缀。保留 Kotlin namespace，不全库替换包名字符串。
- 工具链与运行证据放 .toolchain/、artifacts/。维护文档放 docs/，可复用脚本放 scripts/，测试放 test/。
- 完成修改后审查完整 diff，运行相关测试、分析和构建；UI 修改必须检查实际渲染。区分原版失败、本次回归与未执行检查，不用构建通过替代视觉或真机验收。
- 只暂存本次明确文件，检查暂存 diff，运行 `git diff --cached --check` 与 `python3 scripts/check-staged-files.py`，按功能提交。
- EnoGym 个人版的可安装更新通过验收后，默认推送 `own` 至 `origin/own`，创建带签名 APK、校验文件和更新清单的 GitHub Release，并设为 latest。用户已持续授权，按 [维护说明](docs/OWN.md#应用内更新与发布) 执行并确认应用内更新源可见。仅文档或其他无需更新手机的改动不单独发版。用户当次要求仅本地交付时优先遵循。
- 上述发布授权限于 EnoGym 个人版。推送其他分支、发 PR、部署、强推或重写历史仍需明确授权。
- 真机操作先协调设备使用，优先在隔离模拟器验证。不得触碰用户已有应用的数据；测试结束恢复临时调整的设备设置。
