# Chromium-iOS-Legacy · 给老 iPhone 的“较新 Chrome 内核”浏览器

把**较新的 Chromium 内核**移植到 **iOS 12+ 的 64 位越狱设备**（iPhone 5s / 6 / 6s / 7 / SE1 等，含 iOS 12/13/14… 直到该内核支持的上限），
以 **未签名 IPA** 形式交付，可用越狱机上的 TrollStore / AltStore / ldid 安装。

> ✅ **本工程已推送到 GitHub**：[github.com/zlanly/Chromium-iOS-Legacy](https://github.com/zlanly/Chromium-iOS-Legacy)
> （镜像访问：https://github-com-gh.zilan.ggff.net/zlanly/Chromium-iOS-Legacy）
> 直接 `git clone` 后按 §3.2 注册自托管 runner 即可，无需再手动推送。

> 本项目改编自社区项目 [`growtopiajaw/Chromium-for-iOS`](https://github.com/growtopiajaw/Chromium-for-iOS)
> （它原本在 GitHub 的 Mac runner 上把 Chromium 编成 IPA），并按“老设备 + iOS 12 + 越狱”的要求做了改造。

---

## 0. 先说清能做到 / 做不到什么（必读）

| 目标 | 结论 |
| --- | --- |
| 较新 Chromium 内核 | ✅ 能做到，但“较新”是相对的：面向 iOS 12 我们取 **2023 年初的 Chromium（M109 / 109.0.5414.119）**——它比 iOS 12 自带 Safari(2018) 新很多、能跑现代网页；**不是 2024 的最新版**（M114+ 已要求 iOS 13+）。 |
| 支持 iOS 12 以上所有越狱设备 | ⚠️ **64 位设备全覆盖**（iPhone 5s / 6 / 6s / 7 / SE1 等，iOS 12/13/14… 直到该内核支持的上限）。**32 位 iPhone 5 / 5c 做不到**——Chromium 自 2016 年起就不再出 32 位 iOS 包，物理上不可能。 |
| 以 IPA 形式交付 | ✅ 产出未签名 `Chromium-*.ipa`，越狱机可装。 |
| 在“我这”直接编译出 IPA | ❌ 编译需要 macOS + Xcode + 外网拉源码，本交付环境（Linux 沙箱）无外网、无 iOS 工具链，无法代编。**工程文件已备好，你在自己的 Mac 上跑即可。** |

**核心取舍**：现代 Chromium（M114+）最低只支持 iOS 13/15+ 且只有 arm64；要保住 iOS 12，必须用 M109 这一代老内核。
想要更新的内核（代价：放弃 iOS 12，升到 iOS 13+）→ 把 `chromium_ref` 调到 M114+ 并把 `deployment_target` 设 `13.0`，详见 §6。

---

## 1. 两种使用方式

两种方式底层步骤完全一致，选一个你顺手的：

- **A. GitHub Actions（自托管 runner）** —— 你只点一下，编译在你自己的 Mac 上自动跑，IPA 自动上传到 Artifacts。（你已选这个）
- **B. 本地脚本** —— 直接在 Mac 终端跑 `scripts/build_local.sh`，产物落在 `~/`。

> ⚠️ 无论哪种，**都不能用 GitHub 官方托管的 macOS runner**：实测托管 runner 为 macOS 26 / Xcode 26 / **3 核 / 7GB 内存** / 单任务 **6 小时**上限。
> 磁盘虽已有 ~97GB 空闲（够用），但 M109 这类老 Chromium 在 Xcode 26 下基本编不过，且 3核/7GB 链接阶段极易 OOM、6 小时内冷编不完。
> 所以 Actions 方案用的是**你的 Mac 作为自托管 runner**（配同代 Xcode，如 M109 → Xcode 14）。

---

## 2. 前置条件（你的 Mac）

- macOS（建议与所选 Chromium 同代：M109 → **Xcode 14**；越新越可能需要补丁，见 `patches/README.md`）
- Xcode 命令行工具：`xcode-select --install`
- Homebrew：`brew install ninja gnu-sed python3`
- 磁盘：**至少 50GB 空闲**（Chromium 源码 + 编译产物）
- 网络：能访问 `chromium.googlesource.com`（拉源码）
- 一个 GitHub 仓库放本工程

---

## 3. 方式 A：GitHub Actions（自托管 runner）

### 3.1 仓库已就绪（本工程已推送到 GitHub）

仓库地址：[github.com/zlanly/Chromium-iOS-Legacy](https://github.com/zlanly/Chromium-iOS-Legacy)
（镜像：https://github-com-gh.zilan.ggff.net/zlanly/Chromium-iOS-Legacy）

在你自己的 Mac 上克隆即可，代码已就绪，直接进入 3.2：

```bash
git clone https://github.com/zlanly/Chromium-iOS-Legacy.git
cd Chromium-iOS-Legacy
# 代码已就绪，直接进入 3.2 注册自托管 runner
```

### 3.2 把你的 Mac 注册为自托管 runner

仓库页面 → **Settings → Actions → Runners → New self-hosted runner → macOS**，
按页面给出的命令执行（大致是下载 `actions-runner`，`./config.sh`，`./run.sh`）。
标签保持 `self-hosted` + `macOS`（工作流靠这两个标签选 runner）。

> 让 `./run.sh` 保持运行（可配合 `launchd` 开机自启）。runner 在线时，Actions 才会派发任务。

### 3.3 触发构建

仓库 → **Actions → “Build Chromium IPA (legacy iOS 12+, arm64)” → Run workflow**。
可选填：
- `chromium_ref`：默认 `109.0.5414.119`（M109，仍支持 iOS 12 的一代附近）
- `deployment_target`：默认 `12.0`

编译完成后，在 **Actions → 本次运行 → Artifacts** 下载 `Chromium-*.ipa`。

---

## 4. 方式 B：本地脚本（不用 Actions）

```bash
# 默认 M109 + iOS 12.0
./scripts/build_local.sh
# 或指定版本 / iOS 最低版本（例如想要更新内核、仅 iOS 13+）
./scripts/build_local.sh 114.0.5735.198 13.0
```

产物：`~/Chromium-<版本>-ios<最低版本>.ipa`

---

## 5. 安装到越狱设备

拿到未签名 IPA 后，任选一种（均要求已越狱）：

1. **TrollStore**（最省事，支持到 iOS 15.4.1 / 部分 15.5–16.6.1）：把 IPA 用 TrollStore 打开即永久安装，无需证书。
2. **AltStore / Sideloadly**：用你的 Apple ID 免费重签安装（7 天有效期，AltStore 可自动续期）。
3. **ldid + 手动放置**（已越狱有 root）：
   ```bash
   ldid -S Chromium.app/Chromium        # 或用 entitlements 重签
   # 通过 SSH / Filza 把 Chromium.app 放到 /Applications，再 uicache 刷新
   ```
   > 注意：Chromium 的 iOS 版可能依赖某些 entitlement；如遇启动崩溃，用 `ldid -Sent.xml` 配上
   > `get-task-allow`、`com.apple.security.cs.allow-jit` 等常见 entitlements 再试。

---

## 6. 调参

| 想做的事 | 怎么做 |
| --- | --- |
| 想要**更新的内核**（代价：放弃 iOS 12，升到 iOS 13+） | `chromium_ref` 改为 `114.0.5735.198`(M114) 及以后，`deployment_target` 改 `13.0` 以上；注意越新的内核越需要新 Xcode、编译越久。 |
| 坚持 iOS 12 但想尽量新 | 在 M109 附近微调（M108~M109 仍支持 iOS 12；M110 起多已要求 iOS 13）。 |
| 编译报错（老 Xcode 不兼容） | 看报错，写补丁放进 `patches/`，机制会自动应用（见 `patches/README.md`）。 |
| 关闭 Google 账号/同步 | `config/args.gn` 已设 `use_official_google_api_keys = false`，无需 API key。 |
| 想减小体积 | 在 `args.gn` 增加 `is_official_build = true`（更激进优化，编译更慢）。 |

---

## 7. 已知风险 / 排错

- **编译中途 OOM / 磁盘满**：确保 ≥50GB 空闲、内存 ≥8GB；自托管 runner 不受 6 小时限制，但机器睡眠会中断，建议接电源 + 关闭睡眠。
- **`fetch`/`gclient` 卡在拉源码**：确认能访问 `chromium.googlesource.com`；可设代理环境变量。
- **老 Chromium + 新 Xcode 编译失败**：优先把 Xcode 降到与 Chromium 同代；或在 `patches/` 加兼容补丁。
- **iOS 12 真机启动闪退**：多为 API 不可用，需对应补丁或调 `deployment_target` 到 `13.0`（同时换 M114+ 内核）。
- **32 位设备（iPhone 5/5c）**：本项目覆盖不到；如需，请改用基于系统 WebKit 的浏览器方案另行处理。

---

## 8. 文件结构

```
Chromium-iOS-Legacy/
├── .github/workflows/build.yml     # GitHub Actions 工作流（自托管 runner 上编译并上传 IPA）
├── config/
│   ├── args.gn                     # Chromium 构建参数模板（注入 iOS 最低版本）
│   └── apply_patches.sh            # 应用 patches/ 下补丁的脚本
├── patches/                        # 兼容补丁目录（默认空，按实机报错补充）
│   └── README.md
├── scripts/build_local.sh          # 本地一键构建（不走 Actions）
└── README.md                       # 本文件
```

---

*免责声明：本项目仅用于老设备浏览器内核研究与个人使用；Chromium 相关代码版权归 Google 及其开源许可所有。*
