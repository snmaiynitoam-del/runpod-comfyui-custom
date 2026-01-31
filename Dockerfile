# RunPod ComfyUI Worker with Flux-Uncensored-V2 LoRA + PuLID Face Consistency
# Base Image: RunPod Official ComfyUI Worker (FLUX.1-dev FP8 variant)
# FP8 matches the checkpoint we use: flux1-dev-fp8.safetensors
# Platform: linux/amd64 (RunPod servers are x86_64)
FROM --platform=linux/amd64 runpod/worker-comfyui:5.5.1-flux1-dev-fp8

# Download Flux-Uncensored-V2 LoRA (~150MB)
# Source: https://huggingface.co/enhanceaiteam/Flux-Uncensored-V2
RUN comfy model download \
    --url https://huggingface.co/enhanceaiteam/Flux-Uncensored-V2/resolve/main/lora.safetensors \
    --relative-path models/loras \
    --filename Flux-Uncensored-V2.safetensors

# Verify LoRA installation
RUN ls -lh /comfyui/models/loras/Flux-Uncensored-V2.safetensors || \
    (echo "❌ LoRA file not found!" && exit 1)

# ========== PULID FACE CONSISTENCY ==========

# Install InsightFace dependencies for PuLID
RUN pip install --no-cache-dir insightface onnxruntime-gpu

# Clone PuLID-Flux custom node
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/balazik/ComfyUI-PuLID-Flux && \
    cd ComfyUI-PuLID-Flux && pip install -r requirements.txt

# Create model directories
RUN mkdir -p /comfyui/models/pulid /comfyui/models/insightface/models/antelopev2

# Download PuLID model (~1.3GB)
RUN wget -O /comfyui/models/pulid/pulid_flux_v0.9.0.safetensors \
    "https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.0.safetensors"

# Download InsightFace AntelopeV2 models (~300MB total)
RUN wget -P /comfyui/models/insightface/models/antelopev2/ \
    "https://huggingface.co/DIAMONIK7777/antelopev2/resolve/main/1k3d68.onnx" && \
    wget -P /comfyui/models/insightface/models/antelopev2/ \
    "https://huggingface.co/DIAMONIK7777/antelopev2/resolve/main/2d106det.onnx" && \
    wget -P /comfyui/models/insightface/models/antelopev2/ \
    "https://huggingface.co/DIAMONIK7777/antelopev2/resolve/main/genderage.onnx" && \
    wget -P /comfyui/models/insightface/models/antelopev2/ \
    "https://huggingface.co/DIAMONIK7777/antelopev2/resolve/main/glintr100.onnx" && \
    wget -P /comfyui/models/insightface/models/antelopev2/ \
    "https://huggingface.co/DIAMONIK7777/antelopev2/resolve/main/scrfd_10g_bnkps.onnx"

# Verify PuLID installation
RUN ls -lh /comfyui/models/pulid/pulid_flux_v0.9.0.safetensors || \
    (echo "❌ PuLID model not found!" && exit 1)

# ========== END PULID ==========

# Label metadata
LABEL maintainer="snmaiynitoam"
LABEL description="RunPod ComfyUI Worker with Flux-Uncensored-V2 LoRA + PuLID for face consistency"
LABEL version="2.0.0"
