# RunPod ComfyUI Worker with Flux + PuLID + Wan 2.1 Video
FROM --platform=linux/amd64 runpod/worker-comfyui:5.5.1-flux1-dev-fp8

# ========== FLUX UNCENSORED LORA ==========
RUN comfy model download \
    --url https://huggingface.co/enhanceaiteam/Flux-Uncensored-V2/resolve/main/lora.safetensors \
    --relative-path models/loras \
    --filename Flux-Uncensored-V2.safetensors

RUN ls -lh /comfyui/models/loras/Flux-Uncensored-V2.safetensors || \
    (echo "LoRA file not found!" && exit 1)

# ========== TOOLING NODES (Base64 image loading) ==========
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Acly/comfyui-tooling-nodes

# ========== PULID FACE CONSISTENCY ==========
RUN pip install --no-cache-dir insightface onnxruntime-gpu

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/balazik/ComfyUI-PuLID-Flux && \
    cd ComfyUI-PuLID-Flux && pip install -r requirements.txt

RUN mkdir -p /comfyui/models/pulid /comfyui/models/insightface/models/antelopev2

# Download PuLID model v0.9.1 (~1.14GB)
RUN wget -O /comfyui/models/pulid/pulid_flux_v0.9.1.safetensors \
    "https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.1.safetensors"

# Download InsightFace AntelopeV2 models
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

# Download EVA-CLIP model for PuLID (~856MB)
RUN mkdir -p /comfyui/models/eva_clip && \
    wget -O /comfyui/models/eva_clip/EVA02_CLIP_L_336_psz14_s6B.pt \
    "https://huggingface.co/QuanSun/EVA-CLIP/resolve/main/EVA02_CLIP_L_336_psz14_s6B.pt"

# Create symlink for InsightFace (it looks in ~/.insightface by default)
RUN mkdir -p /root/.insightface/models && \
    ln -sf /comfyui/models/insightface/models/antelopev2 /root/.insightface/models/antelopev2

# ========== WAN 2.1 VIDEO GENERATION ==========

# Wan custom nodes (removed || true to catch errors)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper && \
    cd ComfyUI-WanVideoWrapper && pip install -r requirements.txt

# VideoHelperSuite for video output (removed || true to catch errors)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite && \
    cd ComfyUI-VideoHelperSuite && pip install -r requirements.txt

# Create directories
RUN mkdir -p /comfyui/models/diffusion_models \
    /comfyui/models/text_encoders \
    /comfyui/models/clip_vision

# Download Wan 2.1 I2V Model (FP8 scaled ~16.4GB)
RUN wget -O /comfyui/models/diffusion_models/wan2.1_i2v_480p_14B_fp8_scaled.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_fp8_scaled.safetensors"

# Download Text Encoder FP16 (~11.4GB) - WanVideoWrapper doesn't support fp8_scaled
RUN wget -O /comfyui/models/text_encoders/umt5_xxl_fp16.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp16.safetensors"

# Download VAE (~254MB)
RUN wget -O /comfyui/models/vae/wan_2.1_vae.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

# Download CLIP Vision for I2V (~1.26GB)
RUN wget -O /comfyui/models/clip_vision/clip_vision_h.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

# ========== VERIFICATION ==========
RUN ls -lh /comfyui/models/diffusion_models/wan2.1_i2v_480p_14B_fp8_scaled.safetensors || \
    (echo "Wan model not found!" && exit 1)
RUN ls -lh /comfyui/models/text_encoders/umt5_xxl_fp16.safetensors || \
    (echo "Text encoder not found!" && exit 1)
RUN ls -lh /comfyui/models/pulid/pulid_flux_v0.9.1.safetensors || \
    (echo "PuLID model not found!" && exit 1)
RUN ls -lh /comfyui/models/eva_clip/EVA02_CLIP_L_336_psz14_s6B.pt || \
    (echo "EVA-CLIP model not found!" && exit 1)

LABEL maintainer="snmaiynitoam"
LABEL description="RunPod ComfyUI: Flux + PuLID + Wan 2.1 Video"
LABEL version="4.0.0"
