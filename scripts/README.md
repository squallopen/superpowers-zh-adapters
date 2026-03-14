# 脚本目录规范

当前仓库只官方维护一套脚本运行时：

- `scripts/powershell/`

这套运行时的定位是：

- 面向 `Windows`
- 使用 `PowerShell 7` (`pwsh`)
- 依赖 `Git for Windows`

## 目录约定

- 不再把安装脚本放在仓库根目录
- 每种脚本运行时单独占一个子目录
- 当前所有正式入口都放在 `scripts/powershell/`
- 共享数据、模板、vendored upstream 仍放在仓库根目录的 `data/`、`templates/`、`vendor/`

## 当前 PowerShell 入口

- `scripts/powershell/install-all.ps1`
- `scripts/powershell/update-all.ps1`
- `scripts/powershell/refresh-upstream-and-reinstall.ps1`
- `scripts/powershell/install-cline.ps1`
- `scripts/powershell/install-droid.ps1`
- `scripts/powershell/install-opencode.ps1`
- `scripts/powershell/install-codebuddy.ps1`

## 以后如果有人要补其他系统

直接新建同级目录，不要把逻辑混进 `scripts/powershell/`：

- `scripts/bash/`
- `scripts/python/`
- `scripts/<your-runtime>/`

建议尽量沿用同名入口，这样文档和调用约定更稳定：

- `install-all`
- `update-all`
- `refresh-upstream-and-reinstall`
- `install-<host>`

## 当前边界

- 现在不官方维护 macOS / Linux 脚本
- 现在不承诺跨运行时行为完全一致
- 如果未来要支持其他系统，先补新运行时目录和对应 README，再补实现
