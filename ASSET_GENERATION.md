# 小八素材生成记录

## 输入

用户提供的一张小狗照片，仅作为小八的身份与外观参考。原始照片未放入最终发布目录。

## 使用方式

- 图像生成：Codex 内置 image generation 工具。
- Aha：使用 aha-cli 调用 Seedance 2.0 Pro 参考图生视频（外层插件 2247、核心插件 2246）。参考图先上传到 Aha 素材入口，生成结果下载并固化到项目；桌宠运行时只读本地视频，不依赖 Aha 或任何远程链接。
- 透明化：内置生成结果两次未输出真实 Alpha 通道，因此最终让模型生成纯绿色背景源图，再用 FFmpeg chromakey + despill 转为真正透明、无明显绿边的 RGBA PNG。
- 睡眠姿态：以内置 image generation 工具对 `Assets/xiaoba.png` 做身份保持的睡姿衍生，再单独执行背景提取；最终用 `sips` 验证为真实 RGBA Alpha 后保存为 `Assets/xiaoba-sleep.png`。
- 行走姿态：Seedance 2.0 Pro 生成 640 × 640、24 FPS、4 秒连续走路片段。下载后用 FFmpeg chromakey + despill 去除绿幕；从原视频中保留首尾步态最吻合的一整段连续步态，并在视频文件内部无缝重复，编码为带 Alpha 的 ProRes 4444。本流程不生成运行时 PNG 帧。AppKit 通过 AVFoundation 以 1.5 倍速循环播放；左行只镜像内部视频层，保证身体和腿部朝向与移动方向一致。
- 互动姿态：继续使用 Seedance 2.0 Pro，分别生成摸摸、吃零食、回应名字、入睡、熟睡循环、醒来六段 640 × 640、24 FPS、4 秒视频。每段都经过接触表检查后下载到本地，再执行独立绿幕采样、chromakey、despill 和 Alpha 合成检查，最后缩放为 360 × 360 ProRes 4444。运行时只播放这些本地文件。
- 播放衔接：摸摸、零食、回应、入睡和醒来使用一次性播放器；媒体结束通知之外另有 4.3 秒本地兜底，避免 Alpha 视频偶发漏发结束回调而停在末帧。熟睡使用 `AVPlayerLooper` 无缝循环，叫醒时先退出循环再播放连续起身视频。

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

### 4. Seedance 2.0 Pro 互动视频约束

六段提示词根据动作分别描述，但共享以下核心约束：

```text
Locked camera, square green-screen asset. Preserve the exact identity, face, cream-white curly fur, dark round eyes, black nose, body proportions and size of Xiaoba from the reference. Keep the complete body and all four paws visible and centered at a constant scale. Motion must be continuous, soft and anatomically natural, with no teleporting, jitter, duplicated/fused/disappearing limbs, people, hands, props, text, watermark, camera motion or audio. Use one uniform chroma-green background and ground. For one-shot actions, begin and end in a stable pose suitable for switching to the desktop pet's next state.
```

具体动作分别为：被画面外轻柔抚摸后眯眼蹭头和摇尾巴；接住小零食后咀嚼并舔嘴；听见名字后竖耳歪头并轻跳；从站姿打哈欠后自然伏下熟睡；保持蜷卧仅做轻柔呼吸和偶尔动耳且首尾一致；从蜷卧睁眼、伸懒腰、站起并摇尾巴。

## 最终文件

`Assets/xiaoba.png`：1254 × 1254、RGBA、带真实 Alpha 通道，供 AppKit 透明窗口使用。

`Assets/xiaoba-sleep.png`：1536 × 1024、RGBA、带真实 Alpha 通道，供睡眠状态切换使用。

`Assets/xiaoba-walk.mov`：480 × 480、24 FPS、约 6.33 秒、ProRes 4444 Alpha 本地无缝走路视频，供自动散步离线循环播放。

`Assets/xiaoba-pat.mov`、`xiaoba-feed.mov`、`xiaoba-call.mov`、`xiaoba-sleep-enter.mov`、`xiaoba-sleep-loop.mov`、`xiaoba-wake.mov`：360 × 360、24 FPS、约 4.04 秒、ProRes 4444 Alpha 本地互动视频。
