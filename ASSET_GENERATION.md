# 小八素材生成记录

## 输入

用户提供的一张小狗照片，仅作为小八的身份与外观参考。原始照片未放入最终发布目录。

## 使用方式

- 图像生成：Codex 内置 image generation 工具。
- Aha：使用 aha-cli 调用 Seedance 2.0 Pro 参考图生视频（外层插件 2247、核心插件 2246）。参考图先上传到 Aha 素材入口，生成结果下载并固化到项目；桌宠运行时只读本地视频，不依赖 Aha 或任何远程链接。
- 透明化：内置生成结果两次未输出真实 Alpha 通道，因此最终让模型生成纯绿色背景源图，再用 FFmpeg chromakey + despill 转为真正透明、无明显绿边的 RGBA PNG。
- 睡眠姿态：以内置 image generation 工具对 `Assets/xiaoba.png` 做身份保持的睡姿衍生，再单独执行背景提取；最终用 `sips` 验证为真实 RGBA Alpha 后保存为 `Assets/xiaoba-sleep.png`。
- 行走姿态：Seedance 2.0 Pro 生成 640 × 640、24 FPS、4 秒连续走路片段。下载后用 FFmpeg chromakey + despill 去除绿幕；从原视频中保留首尾步态最吻合的一整段连续步态，并在视频文件内部无缝重复，编码为带 Alpha 的 ProRes 4444。本流程不生成运行时 PNG 帧。AppKit 通过 AVFoundation 以 1.5 倍速循环播放；左行只镜像内部视频层，保证身体和腿部朝向与移动方向一致。

## 最终提示词组

### 1. 身份保持的桌宠素材

```text
Use case: background-extraction
Asset type: transparent macOS desktop pet character sprite
Transform the puppy in the reference photo into a polished, high-fidelity desktop pet cutout named 小八. Keep the puppy unmistakably faithful to the reference: very small fluffy cream-white puppy, soft curly coat, warm light-beige floppy ears, round dark eyes, small black nose, gentle curious expression, slight head tilt, compact proportions, short legs, fluffy upward tail. Show the complete body and all paws in a natural standing idle pose. Remove the cage, bedding, furniture and every part of the original background. No text, collar, clothes, accessories, people or watermark.
```

### 2. 可可靠抠图的最终源图

```text
Keep the puppy exactly unchanged in identity, pose, expression, fur, size and framing. Replace only the background with a perfectly flat, uniform saturated chroma green #00FF00. No gradient, texture, floor or cast shadow. Preserve clean separation around every fur edge. Do not change the dog or add any object, text or watermark.
```

### 3. Seedance 2.0 Pro 连续走路视频

```text
Use the reference puppy as the exact subject and preserve its identity, face, cream-white curly fur, beige floppy ears, compact size and proportions. Locked side three-quarter camera. The puppy performs a natural in-place walk cycle facing screen-right while remaining centered. Its paws contact an invisible fixed horizontal plane. Mechanically correct canine gait: alternating diagonal leg pairs, clear lift-swing-plant-push phases, planted feet do not slide, no kicking, no duplicated, fused, disappearing or extra legs, no sudden pose jumps. Constant tempo and fixed body scale. Full body, tail and all four paws always visible with generous empty padding. The entire background and ground are one perfectly flat uniform chroma green #00FF00 field. Absolutely no treadmill, platform, floor line, floor texture, shadow, props, border, text, camera motion or audio. Aim for a seamless loop with matching first and last gait phase.
```

## 最终文件

`Assets/xiaoba.png`：1254 × 1254、RGBA、带真实 Alpha 通道，供 AppKit 透明窗口使用。

`Assets/xiaoba-sleep.png`：1536 × 1024、RGBA、带真实 Alpha 通道，供睡眠状态切换使用。

`Assets/xiaoba-walk.mov`：480 × 480、24 FPS、约 6.33 秒、ProRes 4444 Alpha 本地无缝走路视频，供自动散步离线循环播放。
