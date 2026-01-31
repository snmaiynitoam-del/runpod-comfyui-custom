# RunPod ComfyUI Worker with Flux + PuLID + Wan 2.1 Video
FROM --platform=linux/amd64 runpod/worker-comfyui:5.5.1-flux1-dev-fp8

# ========== FLUX UNCENSORED LORA ==========
RUN comfy model download \
    --url https://huggingface.co/enhanceaiteam/Flux-Uncensored-V2/resolve/main/lora.safetensors \
    --relative-path models/loras \
    --filename Flux-Uncensored-V2.safetensors

RUN ls -lh /comfyui/models/loras/Flux-Uncensored-V2.safetensors || \
    (echo "LoRA file not found!" && exit 1)

# ========== PULID FACE CONSISTENCY ==========
RUN pip install --no-cache-dir insightface onnxruntime-gpu

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/balazik/ComfyUI-PuLID-Flux && \
    cd ComfyUI-PuLID-Flux && pip install -r requirements.txt

RUN mkdir -p /comfyui/models/pulid /comfyui/models/insightface/models/antelopev2

RUN wget -O /comfyui/models/pulid/pulid_flux_v0.9.0.safetensors \
    "https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.0.safetensors"

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

# ========== TOOLING NODES (Base64 image loading) ==========
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Acly/comfyui-tooling-nodes

# ========== WAN 2.1 VIDEO GENERATION ==========

# Wan custom nodes
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper && \
    cd ComfyUI-WanVideoWrapper && pip install -r requirements.txt || true

# VideoHelperSuite for video output
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite && \
    cd ComfyUI-VideoHelperSuite && pip install -r requirements.txt || true

# Create directories
RUN mkdir -p /comfyui/models/diffusion_models \
    /comfyui/models/text_encoders \
    /comfyui/models/clip_vision

# Download Wan 2.1 I2V Model (FP8 scaled ~16.4GB)
RUN wget -O /comfyui/models/diffusion_models/wan2.1_i2v_480p_14B_fp8_scaled.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_fp8_scaled.safetensors"

# Download Text Encoder (FP8 scaled ~6.74GB)
RUN wget -O /comfyui/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# Download VAE (~254MB)
RUN wget -O /comfyui/models/vae/wan_2.1_vae.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

# Download CLIP Vision for I2V (~1.26GB)
RUN wget -O /comfyui/models/clip_vision/clip_vision_h.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

# Verify Wan installation
RUN ls -lh /comfyui/models/diffusion_models/wan2.1_i2v_480p_14B_fp8_scaled.safetensors || \
    (echo "Wan model not found!" && exit 1)

# ========== END WAN ==========

LABEL maintainer="snmaiynitoam"
LABEL description="RunPod ComfyUI: Flux + PuLID + Wan 2.1 Video"
LABEL version="3.0.0"
