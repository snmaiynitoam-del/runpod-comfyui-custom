# RunPod ComfyUI Worker - Flux + PuLID + Wan 2.2 Video

Custom Docker image for RunPod Serverless with NSFW-enhanced models pre-installed.

## Features

- **Flux** image generation with Uncensored-V2 LoRA
- **PuLID-Flux** face consistency
- **Wan 2.2 I2V** video generation with custom LoRAs
- Custom handler with LoRA selection support

## Usage

### Container Image

```
snmaiynitoam/comfyui-flux-nsfw:v2-wan22
```

### Video Generation API

```json
{
  "input": {
    "image_url": "https://example.com/input.png",
    "prompt": "blowjob, deepthroat, woman giving oral, smooth motion",
    "negative_prompt": "blurry, distorted, low quality",
    "width": 448,
    "height": 640,
    "length": 81,
    "steps": 30,
    "cfg": 5.0,
    "seed": -1,
    "lora": "blowjob",
    "lora_strength": 1.0
  }
}
```

### Available LoRAs

| Name | File | Description |
|------|------|-------------|
| `blowjob` | `WAN-2.2-I2V-HandjobBlowjobCombo-HIGH-v1.safetensors` | Blowjob/handjob actions |
| `deepthroat` | `jfj-deepthroat-W22-T2V-HN-v1.safetensors` | Deepthroat action |

## Pre-installed Models

### Image Generation
- FLUX.1-dev FP8
- Flux-Uncensored-V2 LoRA
- PuLID v0.9.1 + InsightFace AntelopeV2

### Video Generation
- Wan 2.2 I2V 480p BF16
- UMT5-XXL text encoder
- CLIP Vision H
- Wan 2.1 VAE

## Build

### GitHub Actions (Automatic)
Push to `main` branch triggers automatic build.

### Manual
```bash
docker build --platform linux/amd64 -t snmaiynitoam/comfyui-flux-nsfw:v2-wan22 .
docker push snmaiynitoam/comfyui-flux-nsfw:v2-wan22
```

## Version History

- **v2-wan22**: Wan 2.2 video + LoRA support + custom handler
- **v1**: Initial Flux + PuLID + Wan 2.1

## License

- RunPod Official Worker (MIT)
- Model licenses per their respective repositories
