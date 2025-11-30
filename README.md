# RunPod ComfyUI Worker with Flux-Uncensored-V2 LoRA

Custom Docker image for RunPod Serverless with NSFW-enhanced LoRA pre-installed.

## 🎯 Purpose

This image extends RunPod's official ComfyUI worker with:
- **Base**: `runpod/worker-comfyui:5.5.1-flux1-dev-fp8`
- **LoRA**: Flux-Uncensored-V2 (150MB) for NSFW quality enhancement
- **Platform**: linux/amd64 (RunPod GPU servers)

## 🚀 Usage

### Option 1: Use Pre-built Image (Recommended)

```bash
# In RunPod Endpoint settings
Container Image: eardori/comfyui-flux-uncensored:v1
```

### Option 2: Build Locally

```bash
docker build --platform linux/amd64 -t eardori/comfyui-flux-uncensored:v1 .
docker push eardori/comfyui-flux-uncensored:v1
```

### Option 3: Build via GitHub Actions

1. Fork this repository
2. Add Docker Hub secrets:
   - `DOCKER_USERNAME`: Your Docker Hub username
   - `DOCKER_PASSWORD`: Your Docker Hub password or access token
3. Push to `main` branch or manually trigger workflow

## 📦 What's Included

- FLUX.1-dev FP8 model (`flux1-dev-fp8.safetensors`)
- Flux-Uncensored-V2 LoRA (`Flux-Uncensored-V2.safetensors`)
- ComfyUI workflow ready for NSFW image generation

## 🔧 LoRA Configuration

- **Model**: Flux-Uncensored-V2
- **Source**: https://huggingface.co/enhanceaiteam/Flux-Uncensored-V2
- **Strength**: 0.85 (model + clip)
- **Path**: `/comfyui/models/loras/Flux-Uncensored-V2.safetensors`

## 📊 Version History

- **v1.0.38**: Docker Hub repository setup complete
- **v1.0.37**: Initial release with Flux-Uncensored-V2 LoRA integration

## 🏗️ Build Info

- **Image Size**: ~22GB (base) + 150MB (LoRA)
- **Build Time**: ~10-15 minutes (GitHub Actions)
- **Platform**: linux/amd64

## 📝 License

This project uses:
- RunPod Official Worker (MIT License)
- Flux-Uncensored-V2 LoRA (Check HuggingFace repo for license)

## 🔗 Related Links

- [RunPod Documentation](https://docs.runpod.io/)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- [Flux-Uncensored-V2](https://huggingface.co/enhanceaiteam/Flux-Uncensored-V2)
