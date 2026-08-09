# 补丁目录（patches/）

本目录用于存放让旧版 Chromium 能在 **老 Xcode / 老 iOS SDK** 下编译通过的补丁（`.patch`）。

## 为什么需要补丁

你选的 Chromium（如 M75，2019 年）当初是用当时版本的 Xcode（Xcode 10/11）编译的。
若你的 Mac 装的是较新的 Xcode（12+），旧代码可能：

- 用到已被新 SDK 删除/重命名的 API；
- 触发新的编译器告警被当作错误（`-Werror`）；
- 用到 C++ 标准变更导致的不兼容。

这些错误需要先编译一次、看报错，再针对性写补丁放进来。**无法在出网受限的环境里凭空预置正确补丁**，所以这里默认留空，由你在自己的 Mac 上按实际报错补充。机制已就绪：把 `xxx.patch` 丢进本目录，工作流会自动尝试应用（失败则跳过并提示）。

## 补丁怎么写

在 `chromium/src` 里用 git 生成：

```bash
cd chromium/src
# 改完代码后
git diff > ../Chromium-iOS-Legacy/patches/fix-ios10-foo.patch
```

## 常见补丁方向（iOS 10 / 老 SDK）

- 把 `if (@available(iOS 11, *))` 等 unavailable API 调用加兼容分支或降级实现；
- 移除/替换已废弃的 UIKit/Foundation 符号；
- 在 `BUILD.gn` 里为 iOS 10 关闭用到新特性的模块；
- 给某些 `-Werror` 的第三方库临时放宽告警（不推荐长期，但能先跑通）。

> 提示：把 Chromium ref 固定在与你 Xcode 同代（例如 M75 配 Xcode 10.1–11）能大幅减少补丁量。
