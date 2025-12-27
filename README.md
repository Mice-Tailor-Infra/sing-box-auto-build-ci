# Sing-Box Auto Build CI

Automated CI/CD pipeline for building [reF1nd/sing-box](https://github.com/reF1nd/sing-box) binaries across multiple platforms and architectures.

## Supported Platforms and Architectures

This pipeline builds for modern production environments only. Legacy 32-bit and MIPS architectures are excluded.

| Platform    | Arch    | Micro-Arch       | Branches                |
| :---------- | :------ | :--------------- | :---------------------- |
| **Android** | `arm64` | -                | reF1nd-main, reF1nd-dev |
| **Linux**   | `amd64` | `v1`, `v3`, `v4` | reF1nd-main, reF1nd-dev |
| **Linux**   | `arm64` | -                | reF1nd-main, reF1nd-dev |
| **Windows** | `amd64` | `v1`, `v3`, `v4` | reF1nd-main, reF1nd-dev |
| **Windows** | `arm64` | -                | reF1nd-main, reF1nd-dev |
| **macOS**   | `amd64` | -                | reF1nd-main, reF1nd-dev |
| **macOS**   | `arm64` | -                | reF1nd-main, reF1nd-dev |

## Build Features

All builds include the following feature tags:

- `with_gvisor`
- `with_quic`
- `with_dhcp`
- `with_wireguard`
- `with_utls`
- `with_clash_api`
- `with_tailscale`
- `with_acme`

## Automation

- **Trigger**: Manual dispatch or daily at 19:00 UTC.
- **Build Scripts**: Located in `scripts/` directory.
- **Releases**: Binaries are published to [Releases](https://github.com/cagedbird/sing-box-auto-build-ci/releases) with tags like `v1.x.x` for main and `v1.x.x-dev` for dev.

---

# Sing-Box 自动构建 CI

用于自动构建 [reF1nd/sing-box](https://github.com/reF1nd/sing-box) 二进制文件的 CI/CD 流水线，支持多种平台和架构。

## 支持的平台和架构

此流水线仅针对现代生产环境构建。排除遗留的 32 位和 MIPS 架构。

| 平台        | 架构    | 微架构           | 分支                    |
| :---------- | :------ | :--------------- | :---------------------- |
| **Android** | `arm64` | -                | reF1nd-main, reF1nd-dev |
| **Linux**   | `amd64` | `v1`, `v3`, `v4` | reF1nd-main, reF1nd-dev |
| **Linux**   | `arm64` | -                | reF1nd-main, reF1nd-dev |
| **Windows** | `amd64` | `v1`, `v3`, `v4` | reF1nd-main, reF1nd-dev |
| **Windows** | `arm64` | -                | reF1nd-main, reF1nd-dev |
| **macOS**   | `amd64` | -                | reF1nd-main, reF1nd-dev |
| **macOS**   | `arm64` | -                | reF1nd-main, reF1nd-dev |

## 构建特性

所有构建均包含以下特性标签：

- `with_gvisor`
- `with_quic`
- `with_dhcp`
- `with_wireguard`
- `with_utls`
- `with_clash_api`
- `with_tailscale`
- `with_acme`

## 自动化

- **触发器**：手动调度或每日 UTC 19:00。
- **构建脚本**：位于 `scripts/` 目录。
- **发布**：二进制文件发布到 [Releases](https://github.com/cagedbird/sing-box-auto-build-ci/releases)，标签如 `v1.x.x` 用于主分支，`v1.x.x-dev` 用于开发分支。
