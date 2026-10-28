# Realtek / Microarray `3274:9011` 指纹适配

[English](README.md)

为 libfprint 已有的 **Realtek MOC 驱动**增加设备兼容性补丁，提供固定上游版本的构建、安装和卸载脚本。适用于实验性验证，尚未合并至 libfprint 上游。

## 实测本机

- **机械革命 无界14X 2026 斗战版**
- 指纹 USB ID：**`3274:9011`**
- USB 产品名称：`Realtek USB2.0 Finger Print Bridge`
- Ubuntu 24.04、GNOME 46、x86_64
- 2026 年 9 月在一台实机上测试

请先运行 `lsusb -d 3274:9011` 确认硬件 ID。同型号电脑可能有不同指纹模块，不能只凭机型安装。

## 修改内容

补丁基于 libfprint 现有 Realtek 驱动，增加 `3274:9011` 设备 ID，并适配该固件读取 Linux 指纹模板表后返回 `0x01` 的行为。兼容规则只用于这个设备和这条读取命令，且检查完整响应长度及已占用槽位的记录头。其他非零状态仍然报错。

固定上游版本：`6f9479c3d55f847c1b3769f28ceb99227f9858cf`。
[查看补丁](patches/0001-realtek-support-3274-9011.patch)；[libfprint 上游](https://gitlab.freedesktop.org/libfprint/libfprint)。

## 验证情况

实机已完成：设备打开和初始化、读取 Linux 模板表、在 GNOME 设置中录入右手食指、通过 fprintd 列出已录入指纹，以及一次返回 `verify-match` 的现场指纹验证。

发布版本通过编译及上游 `fpi-device`、`fpi-ssm` 核心单元测试。这些测试未覆盖新增固件规则；该规则的实机依据是上述录入与验证。公开补丁去除了初期实验中的原始响应诊断输出。

锁屏认证、PAM 配置、错误手指拒绝、休眠唤醒及重启恢复尚未系统验证。本项目没有固件更新或删除指纹模板的工具。

## 构建

Ubuntu 24.04：

```sh
sudo apt install git build-essential meson ninja-build pkg-config \
  libglib2.0-dev libgusb-dev fprintd libpam-fprintd

git clone https://github.com/liudenghui63-stack/libfprint-3274-9011.git
cd libfprint-3274-9011
./scripts/build.sh
```

用普通用户构建。脚本下载固定版本源码、应用补丁，以两个并行任务编译，并运行两组核心单元测试。源码与构建结果保存在 Git 忽略的 `.work/` 目录。重复运行会识别已应用的补丁，遇到意外源码版本则停止。

构建只启用 Realtek 驱动。该覆盖配置生效期间，fprintd 无法使用由其他 libfprint 驱动负责的指纹设备。

## 安装

先完成正在进行的指纹录入或认证。在桌面会话内运行，优先通过系统图形化对话框输入密码：

```sh
pkexec "$PWD/scripts/install.sh"
```

如果没有 PolicyKit，可在独立终端运行 `sudo ./scripts/install.sh`。

库安装至 `/usr/local/lib/libfprint-3274-9011`；服务覆盖文件为 `/etc/systemd/system/fprintd.service.d/3274-9011-local.conf`。脚本重新加载 systemd 并停止 fprintd，下一次激活时使用本地库。

安装不会替换 `/usr/lib` 中的发行版文件，不修改 PAM 认证策略，也不增删已有指纹模板。无需运行 `meson install`。

安装后，可自行进入「设置 → 用户 → 指纹登录」录入，或运行 `fprintd-enroll`。录入是会新增模板的独立操作。随后用 `fprintd-verify` 验证；测试期间保留密码登录方式。

## 卸载

```sh
pkexec "$PWD/scripts/uninstall.sh"
```

仅移除本项目的库和服务覆盖文件，fprintd 下次激活即恢复使用系统库，不删除指纹模板。卸载脚本也兼容最初本地实验的安装路径。

## 反馈与许可

反馈请注明机型、USB ID、系统版本和失败操作。请勿上传指纹模板、原始 USB 抓包或未经脱敏的日志。仓库不含生物识别数据、机器日志、Windows 驱动二进制或编译后的库。

基于 Realtek Corp. 和 libfprint 社区的开源工作，保留原有署名。补丁、脚本与文档采用 **LGPL-2.1-or-later**，详见 [LICENSE](LICENSE)。维护者：[liudenghui63-stack](https://github.com/liudenghui63-stack)。
