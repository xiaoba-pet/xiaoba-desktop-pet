# 小八素材生成记录

## 输入

用户提供的一张小狗照片，仅作为小八的身份与外观参考。原始照片未放入最终发布目录。

## 使用方式

- 图像生成：Codex 内置 image generation 工具。
- Aha：使用 aha-cli 查询了图片与视频生成能力。Aha 插件要求可访问的素材 URL，因此本次没有把本地原图上传到 Aha。
- 透明化：内置生成结果两次未输出真实 Alpha 通道，因此最终让模型生成纯绿色背景源图，再用 FFmpeg chromakey 转为真正透明的 RGBA PNG。

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

## 最终文件

`Assets/xiaoba.png`：1254 × 1254、RGBA、带真实 Alpha 通道，供 AppKit 透明窗口使用。
