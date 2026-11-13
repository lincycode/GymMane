# 浅色配色切换与 EnoGym 1.0.7 验收

2026-11-13。用户确认保留作者的原版配色，并将鼠尾草白作为另一套浅色配色，在检查通过后推送和发布。

## 实现

- 设置 → 通用新增「浅色配色」：鼠尾草白（默认）、原版暖米灰。配色与外观明暗模式独立，跟随系统时仅影响浅色状态，深色和 AMOLED 不变。
- 原版颜色完整恢复自改为鼠尾草白前的 `GymColors.light`，使用 `lightOriginal` 保留，未重新调色。
- 新增 `lightPalette` 设置，使用既有保存、备份恢复和同步通道。旧数据缺失或不识别的值回退为鼠尾草白。桌面小组件使用同一选项。
- 新增中英文 ARB 文案，其他语言生成英文回退并登记 pending keys；未改写已有其他语言译文。
- 版本 1.0.7，Android arm64 versionCode 182。更新说明同时收录上一发布之后已完成的松绿奶油图标。

## 已通过

| 验证 | 结果 |
| --- | --- |
| `light_palette_test`、`theme_test`、`settings_test`、`backup_roundtrip_test`、`i18n_test`、`home_widgets_test`、`app_update_test`、`changelog_test`、`sync_backup_test` | 81 项通过 |
| 正式 `GymManeApp` 入口的页面渲染 | 20 项通过：两套浅色各 7 页，深色与 AMOLED 各 3 页 |
| 全项目 `flutter analyze --no-pub --no-fatal-infos` | No issues found |
| Android arm64 Release 构建 | 成功；已逐字检查 APK 内含 1.0.7 更新日志及版本配置 |
| 独立 `EnoGymPalette_API37` / `emulator-5584` 覆盖升级 | 1.0.6（172）→ 1.0.7（182），安装前后设置文件字节完全相同 |
| 升级后启动 | profile、favorites、routines、weeklyPlan、planId、sessions、live、liveElapsed、livePaused 与升级前一致 |
| Android 实际点选两种配色并重启 | 均保存成功；旧数据默认鼠尾草白；原版重启后训练页仍使用暖米灰；双向切换后历史、计划、活动训练保持一致 |
| 上游正式发布核对 | 最新仍为 GymMane v2.2.0（北京时间 2026-11-12），已在 upstream-releases.json 收录 |

最终 APK：`artifacts/apk/EnoGym-1.0.7-Ace6T-arm64-v8a-release.apk`，SHA-256 `9d61bce059e424c21a1b3274026b045c1d62b62caa1a85935b3c0c586fc1af66`。

本地证据位于 `artifacts/qa/2026-11-13-palette-switch/` 和 `artifacts/qa/2026-11-13/screens/palette-*.png`，不进入 Git。所有升级记录为专用模拟器的合成数据，未连接或操作真实手机。

## 过程与限制

首次交互测试在弹层动画尚未结束时点选，另有默认成就弹层遮挡测试；等待动画并明确关闭测试无关成就后通过。一次回归命令误写了更新测试文件名，改用实际 `app_update_test.dart` 后 81 项全部通过。

增量构建曾遗漏新增日志资源；清理生成缓存后重新构建并直接检查 APK 归档，确认日志完整。恢复依赖时遇到现有 macOS `app_settings` / Swift Package Manager 配置限制；依赖缓存恢复后使用 Android `--no-pub` 正式构建成功，未修改其他平台或依赖版本。俄语/乌克兰语 ICU 与其他语言未翻译提示为已有内容，不扩大翻译范围。

Flutter 截图测试为显示中文使用本机字体替代，生产字体未改动；Android 截图来自正式 APK 的真实渲染。小组件验证覆盖渲染与主题映射，未执行桌面添加小组件的人工验收。未进行真实手机长期训练、后台策略或实际 Syncthing 双设备验收。
