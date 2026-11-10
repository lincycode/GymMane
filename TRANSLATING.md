# EnoGym 翻译说明

界面文案在 [`lib/l10n/`](lib/l10n/)。[`app_en.arb`](lib/l10n/app_en.arb) 是模板，[`app_zh.arb`](lib/l10n/app_zh.arb) 是简体中文资源。动作名称和说明单独维护在 [`catalog_zh.dart`](lib/l10n/catalog_zh.dart) 等文件。

- 翻译时保留键名、占位符和 ICU 语法。写清动作、单位和状态，优先使用常用训练术语。
- 新文案先补简体中文和英文。其他语言的待译项记录在 [`pending_translation_keys.txt`](test/pending_translation_keys.txt)。
- 界面品牌使用 **EnoGym**。涉及原项目和许可证时保留 GymMane、InlitX 及其[署名](ADDITIONAL_TERMS.md)。

修改 ARB 后重新生成本地化代码，并验证译文覆盖。

```bash
bash scripts/flutter.sh gen-l10n
bash scripts/flutter.sh test --no-pub test/i18n_test.dart
```
