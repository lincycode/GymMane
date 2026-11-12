---
name: EnoGym
description: 延续 GymMane 的原生 Android 训练界面与已批准的个人品牌。
colors:
  light-ember: "#1A1713"
  light-onEmber: "#FFFFFF"
  light-accent: "#9E4E27"
  dark-ember: "#FFFFFF"
  dark-onEmber: "#0A0A0A"
  dark-accent: "#D9A184"
  light-sage: "#3D7A52"
  dark-sage: "#8FA377"
  light-bg: "#F7F4F0"
  light-bgRaised: "#FFFFFF"
  light-bgRaised2: "#ECE8E3"
  light-border: "#E0DBD5"
  light-text: "#1A1713"
  light-textSecondary: "#5F574F"
  dark-bg: "#0A0A0A"
  dark-bgRaised: "#1C1C1C"
  dark-bgRaised2: "#2B2B2B"
  dark-border: "#3E3E3E"
  dark-text: "#FFFFFF"
  dark-textSecondary: "#9A9A9A"
  amoled-bg: "#000000"
  amoled-bgRaised: "#111111"
  amoled-bgRaised2: "#1E1E1E"
  amoled-border: "#2E2E2E"
  amoled-onEmber: "#000000"
typography:
  d:
    fontFamily: Nunito
    fontWeight: 700
    lineHeight: 1
  f:
    fontFamily: Nunito
    fontWeight: 700
    lineHeight: 1.15
  s:
    fontFamily: Nunito
    fontWeight: 400
    lineHeight: 1.35
rounded:
  softCard: "22px"
  sheet: "28px"
  pill: "100px"
spacing:
  pageHorizontal: "20px"
  sheetTop: "12px"
  sheetBottom: "28px"
components:
  primaryButton-light:
    backgroundColor: "{colors.light-ember}"
    textColor: "{colors.light-onEmber}"
    rounded: "{rounded.pill}"
    padding: "0px 16px"
    height: "52px"
  primaryButton-dark:
    backgroundColor: "{colors.dark-ember}"
    textColor: "{colors.dark-onEmber}"
    rounded: "{rounded.pill}"
    padding: "0px 16px"
    height: "52px"
  softCard-light:
    backgroundColor: "{colors.light-bgRaised}"
    rounded: "{rounded.softCard}"
    padding: "20px"
  searchField-light:
    backgroundColor: "{colors.light-bgRaised}"
    textColor: "{colors.light-text}"
    rounded: "{rounded.pill}"
    padding: "0px 6px 0px 16px"
    height: "48px"
---

# Design System: EnoGym

## Overview

**Creative North Star: "延续 GymMane 的熟悉训练界面"**

EnoGym 延续原有的暖中性浅色、近黑深色、Nunito 字体、圆角内容面、Phosphor 图标与底部导航。个人品牌采用 Enoch 提供的米白跑者 E 与红色点缀；这次身份调整没有建立第二套视觉体系。

本文件记录 `2.1.0-own.5` 已实现的共享规则，不定义全应用重新设计。主题以 [GymColors](lib/theme/app_colors.dart)、字体以 [AppTheme](lib/theme/app_theme.dart)、组件以 [ui_kit.dart](lib/widgets/ui_kit.dart) 为实现来源；冲突时先核对代码和真实渲染，再同步文档。上方 `px` 仅用于可移植格式，原生实现使用 Flutter logical pixels；字形大小还受应用文字缩放影响。

**Key Characteristics:**
- 保留浅色、深色与 AMOLED 三套既有主题。
- 主操作使用黑白反差，铜色仍承担界面强调，图标使用米白与红色。
- 内容按圆角容器分组，浮层和底部导航保留原有层次。
- 品牌图形与个人维护归属并存，原作者署名持续可见。

品牌素材来源、派生方式及署名规则统一见 [OWN.md](docs/OWN.md#个人品牌与署名)，不另建重复品牌手册。计划页的任务顺序见 [surface brief](.impeccable/surfaces/lib-screens-routines-screen-dart.md)，不提升为所有页面的布局规则。

## Colors

### Primary

`ember` / `onEmber` 是黑白主操作配对；`accent` 是随主题变化的铜色强调。保留源码命名，不能因 `ember` 这个名称把主按钮改成橙色。AMOLED 共享深色强调和文字角色，但主操作的 `onEmber` 使用纯黑。

### Secondary

`sage` 表达成功反馈，模板添加后的提示沿用这一角色。其余状态色、`brass`、透明叠层、`pageBg` 和 `navBg` 继续从 `GymColors` 读取；这里没有复制完整色表或生成新的色阶。

### Neutral

浅色是暖灰底与白色内容面；深色和 AMOLED 使用各自的近黑底与灰色内容面。`text` 承担正文，`textSecondary` 承担次要但必须辨识的字段与说明。边界使用主题 `border`。

**The Theme Roles Rule.** 组件从当前 `context.gc` 取色；品牌 PNG 的米白与红色不替换界面主题角色，也不要求深浅主题使用同一个十六进制值。

**The Required Labels Rule.** 本轮计划分组与 About 归属字段使用 `textSecondary`；新增必要标签不能因沿用 `textTertiary` 就省略对实际背景的可读性检查。

## Typography

Display、正文和圆润标题均使用项目内置 Nunito，`disp`、`sans`、`round` 是同一字体的代码别名。中文沿用系统字形回退，当前没有单独指定中文字体；不把截图中的回退字形误记为新品牌字体。

上方 `d`、`f`、`s` 是 `AppTheme` 工厂的实际默认字重与行高，不是一套固定字号阶梯。调用方仍明确传字号、字重和行高：共享 `ScreenTitle` 默认为 22 / 800，`SheetTitle` 为 19 / 800、行高 1.2；预览正文为 14 / 500、行高 1.4，日标题为 16 / 700、行高 1.35。关于页名称使用 24 / 800。不要把局部例外扩成新的全局字体规范。

## Layout

手机纵向滚动为当前基线。首页、计划与 About 保留两侧页面留白；底部空间按导航和安全区域处理。共享 `sheetPad` 在底部基值上加系统安全区，`AppSheet` 默认最高为可用屏高的 0.88。

计划创建动作使用 `Wrap` 随可用宽度换行，不依赖新断点。模板预览最高为屏高的 0.9，正文独立滚动，确认按钮位于滚动区外。窄屏截图证明了本次布局重排；应用仍沿用 `GymManeApp` 的文字缩放上限，不代表任意字号、平板或全部页面已完成适配。

## Elevation & Depth

内容卡片主要用主题面色和细边界区分层次；不是全应用无阴影规则。原有 `GlassSurface`、底部导航与拖动状态保留透明、模糊、柔和阴影及动画，关闭模糊时回退为实体主题面色。「通用 → 显示效果」提供独立的背景模糊和减少动画开关。刷新率跟随系统。共享 sheet 的遮罩透明度为 0.38，圆角和边界由 `ui_kit.dart` 管理。不要为新增计划内容再引入一套材质。

## Shapes

`SoftCard`、sheet 与 pill 使用上方记录的共享默认圆角。关于页品牌图标使用 16，模板列表项使用 16；这是既有调用方式，不应为了整齐而全部归一。sheet 只对顶部圆角处理。保留真实的 Phosphor 和已有 SVG path 图标；启动器前景使用 `assets/brand/enogym_foreground.png`，关于页使用同一前景加深色底，按显示尺寸解码。

## Components

- **Buttons:** 共享 `PrimaryButton` 使用 `ember` / `onEmber`，`GhostButton` 使用 `bgRaised2` 与 `text`。计划顶部使用 Material `FilledButton` / `OutlinedButton`，最小高度 48；预览确认最小高度 52。两者不是同一个组件实现，不从截图推断相同的禁用或焦点样式。
- **Cards / Containers:** `SoftCard` 默认有主题边界；模板卡片采用实际面色和圆角。保持信息分组，不把每条说明包装成额外卡片。
- **Inputs / Fields:** 共享 `SearchField` 为 pill 外形、无内层描边，文字为 `text`，提示为 `textSecondary`，光标为 `accent`。未建立额外的通用错误或焦点样式。
- **Chips:** `Pill` 的背景和前景由调用方传入；`SegToggle` 用 `ember` / `onEmber` 标记选中项，未选文字为 `textSecondary`。不把调用方颜色固化成统一芯片色。
- **Navigation:** 沿用 `app_shell.dart` 的浮动底栏、四个位置及中央开始训练动作。选中项使用填充 Phosphor 图标和移动底片；不增设计划标签或更换导航结构。
- **Sheets:** 继续通过 `showAppSheet` 和共享 sheet 样式呈现。模板预览保持内容滚动、明确的安排影响和单一确认操作；取消退出不依赖动画完成来写入。

共享 `Pressable` 默认按下缩放至 0.965，按下 90ms / `easeOut`，松开 260ms / `easeOutBack`；这些是现有反馈参数，不是帧率或真实设备流畅度证明。

关于页将品牌、版本和「检查更新」放在首屏，随后显示来源与作者署名。更新按钮高度至少 48，沿用当前主题与下载图标。更新状态使用可滚动的 Material 对话框，显示版本、大小、发布说明、下载与校验状态；下载和安装由用户分别触发。错误保留原因及重试入口，安装授权提示明确返回后的操作；不以颜色替代状态文字。窄屏与大字号通过按钮换行和内容滚动容纳。

## Do's and Don'ts

### Do:
- **Do** 沿用当前主题、Nunito、Phosphor 与现有共享组件，保持原训练、计时和成就界面的视觉连续性。
- **Do** 保留 EnoGym / Enoch 身份、跑者 E 素材来源及原作者与原项目署名。
- **Do** 对新必要文字按实际主题和背景检查可读性，并保留可访问名称与稳定操作定位。

### Don't:
- **Don't** 因个人品牌更新而替换 GymMane 的主题、字体、导航或训练流程。
- **Don't** 把本轮页面顺序、局部字号或验证范围误写成全应用规则或完整无障碍合规结论。
- **Don't** 将旧组件的低对比度三级文字、装饰性眉题或字符图标提升为新增界面规范。
