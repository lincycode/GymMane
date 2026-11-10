# EnoGym 上游同步与 Android APK 验证

- GymMane 官方 `main` 从 `532827f` 更新到 `73b2786acda9a7ffeb08b60fa8578bef9b836555`，新增 14 个提交。合并基于 `own` 的 `9fa5987`。
- 上游更新包括训练次数区间、首页区块排序、笔记链接、方案导出改进和桌面开始训练入口。本轮设备验收范围为 Android APK。
- 首页将「管理训练计划」和每周训练打卡放在同一可排序区块。合并 ARB 源文件后重新生成翻译，新增文案补简体中文，其他语言缺项沿用待翻译清单。
- 模拟器初测发现 Android 将快捷方式里的包名资源当成字面量。改为打包时写入当前变体的实际包名，Release 和 Debug 分别指向各自的 EnoGym。

## 验证

- 完整 Flutter 测试最终 1108 通过、3 项既有跳过，涵盖备份恢复和方案导入导出。上游独立副本复现了缺译检查失败，修正后通过。首轮照片替换测试偶发失败，该实现和测试均与上游一致，完整复跑通过。
- Flutter 静态分析无问题。锁定依赖解析成功。本机缺完整 Xcode，Flutter 追加的 iOS 插件准备失败。使用 `bash scripts/build-own.sh release --no-pub` 完成 Android 构建。
- Android 37 arm64 隔离模拟器从 `2.1.0-own.5`（52）覆盖升级到 `2.1.0-own.6`（62）。覆盖后 SharedPreferences 字节相同，首次启动后应用数据一致，保留 3 个方案、2 次训练记录、2 个已保存周计划及原有偏好。
- 实测首页计划入口打开计划管理，模板、新建训练方案、每周安排和已保存周计划可见。最终包长按桌面图标并点击快捷方式，打开 EnoGym 的「开始训练」面板。
- APK 验证通过。包名 `com.echolin.gymmane`，ABI 为 `arm64-v8a`，Release 签名证书与 `own.5` 相同。真实 Ace 6T 尚未验证。

APK 位于 `artifacts/apk/EnoGym-2.1.0-own.6-Ace6T-arm64-v8a-release.apk`。SHA-256 为 `b0ee82708b72eabe99e2f3b9fdb8a7d048e77b1b3b63c85abe5d470e534315f0`。详细日志和截图位于 `artifacts/qa/2026-11-10-sync/`。
