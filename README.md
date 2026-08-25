# 小八桌面宠物

一个以用户提供的小狗照片为形象参考制作的 macOS 桌面宠物。小八不读取 Codex、不上传账号信息，也没有遥测。

## 已有互动

- 单击小八：摸摸它，显示随机回应和爱心。
- 双击小八：切换真实睡姿或唤醒。
- 拖动小八：移动到喜欢的位置，位置会自动记住。
- 鼠标悬浮：小八会打招呼。
- 右键小八：叫名字、喂零食、睡觉、自动散步、切换置顶、复位或退出；开关项带勾选状态。
- 菜单栏小狗图标：在小八被窗口挡住时也能叫它回来。
- 自动散步：开启后小八会以 1.5 倍速播放本地透明连续走路视频，窗口位置以 60 FPS 刷新；到左右边缘会同步镜像身体朝向并掉头，睡觉和拖动时暂停。

## 本地运行

需要 macOS 13 或更新版本，以及 Xcode Command Line Tools。

```bash
xcode-select --install
./scripts/xiaoba start
```

常用命令：

```bash
./scripts/xiaoba start
./scripts/xiaoba stop
./scripts/xiaoba restart
./scripts/xiaoba status
./scripts/xiaoba autostart install
./scripts/xiaoba autostart uninstall
```

安装全局命令：

```bash
./scripts/install_cli.sh
xiaoba start
```

程序会在首次启动或源码、素材更新后自动构建 `dist/小八.app`。

## 一行安装并启动

在 macOS 终端执行：

```bash
curl -fsSL "https://raw.githubusercontent.com/xiaoba-pet/xiaoba-desktop-pet/main/install.sh?$(date +%s)" | zsh \
  && "$HOME/.local/bin/xiaoba" start
```

安装脚本会把源码放到 `~/.local/share/xiaoba-desktop-pet`，并把命令安装为 `~/.local/bin/xiaoba`。

## 项目结构

```text
Assets/xiaoba.png         小八透明 PNG
Assets/xiaoba-sleep.png   小八透明睡姿 PNG
Assets/xiaoba-walk.mov    本地透明无缝走路视频（ProRes 4444）
Sources/XiaobaPet.swift   AppKit 桌宠程序
scripts/build_app.sh      构建本地 .app
scripts/xiaoba            启动、停止和自启动 CLI
scripts/install_cli.sh    安装全局命令
install.sh                GitHub 一行安装入口
```

## 发布提醒

当前构建使用临时签名，适合本机运行和内部测试。公开分发时建议在 GitHub Actions 中构建，并使用 Apple Developer ID 签名和 Notarization，避免 Gatekeeper 警告。

形象素材的生成和透明化过程记录在 [ASSET_GENERATION.md](ASSET_GENERATION.md)。
