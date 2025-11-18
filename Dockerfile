# RunPod ComfyUI Worker with Flux-Uncensored-V2 LoRA
# Base Image: RunPod Official ComfyUI Worker (FLUX.1-dev FP8 variant)
# FP8 matches the checkpoint we use: flux1-dev-fp8.safetensors
# Platform: linux/amd64 (RunPod servers are x86_64)
FROM --platform=linux/amd64 runpod/worker-comfyui:5.5.1-flux1-dev-fp8

# Download Flux-Uncensored-V2 LoRA (~150MB)
# Source: https://huggingface.co/enhanceaiteam/Flux-Uncensored-V2
RUN comfy model download \
    --url https://huggingface.co/enhanceaiteam/Flux-Uncensored-V2/resolve/main/Flux-Uncensored-V2.safetensors \
    --relative-path models/loras \
    --filename Flux-Uncensored-V2.safetensors

# Verify LoRA installation
RUN ls -lh /comfyui/models/loras/Flux-Uncensored-V2.safetensors || \
    (echo "❌ LoRA file not found!" && exit 1)

# Label metadata
LABEL maintainer="eardori"
LABEL description="RunPod ComfyUI Worker with Flux-Uncensored-V2 LoRA for NSFW image generation"
LABEL version="1.0.37"
