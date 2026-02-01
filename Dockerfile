# RunPod ComfyUI Worker with Flux + PuLID + Wan 2.2 Video + Custom LoRAs
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
RUN pip install --no-cache-dir insightface==0.7.3 onnxruntime-gpu

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/balazik/ComfyUI-PuLID-Flux && \
    cd ComfyUI-PuLID-Flux && pip install -r requirements.txt

RUN mkdir -p /comfyui/models/pulid /comfyui/models/insightface/models/antelopev2

RUN wget -O /comfyui/models/pulid/pulid_flux_v0.9.1.safetensors \
    "https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.1.safetensors"

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

RUN mkdir -p /comfyui/models/eva_clip && \
    wget -O /comfyui/models/eva_clip/EVA02_CLIP_L_336_psz14_s6B.pt \
    "https://huggingface.co/QuanSun/EVA-CLIP/resolve/main/EVA02_CLIP_L_336_psz14_s6B.pt"

RUN mkdir -p /root/.insightface/models && \
    ln -sf /comfyui/models/insightface/models/antelopev2 /root/.insightface/models/antelopev2

# ========== WAN 2.2 VIDEO GENERATION ==========

# Wan custom nodes (supports Wan 2.2)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper && \
    cd ComfyUI-WanVideoWrapper && pip install -r requirements.txt

# VideoHelperSuite for video output
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite && \
    cd ComfyUI-VideoHelperSuite && pip install -r requirements.txt

# Create directories
RUN mkdir -p /comfyui/models/diffusion_models \
    /comfyui/models/text_encoders \
    /comfyui/models/clip_vision \
    /comfyui/models/loras/wan

# Download Wan 2.2 I2V Model (BF16 ~26GB)
RUN wget -O /comfyui/models/diffusion_models/wan2.2_i2v_480p_bf16.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_480p_bf16.safetensors"

# Download Text Encoder FP16 (~11.4GB)
RUN wget -O /comfyui/models/text_encoders/umt5_xxl_fp16.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp16.safetensors"

# Download VAE (~254MB)
RUN wget -O /comfyui/models/vae/wan_2.1_vae.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

# Download CLIP Vision for I2V (~1.26GB)
RUN wget -O /comfyui/models/clip_vision/clip_vision_h.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

# ========== WAN 2.2 VIDEO LORAS ==========
# Download from HuggingFace (uploaded from CivitAI originals)
RUN wget -O /comfyui/models/loras/wan/WAN-2.2-I2V-HandjobBlowjobCombo-HIGH-v1.safetensors \
    "https://huggingface.co/snailmana99/wan22-video-loras/resolve/main/WAN-2.2-I2V-HandjobBlowjobCombo-HIGH-v1.safetensors"

RUN wget -O /comfyui/models/loras/wan/jfj-deepthroat-W22-T2V-HN-v1.safetensors \
    "https://huggingface.co/snailmana99/wan22-video-loras/resolve/main/jfj-deepthroat-W22-T2V-HN-v1.safetensors"

# ========== CUSTOM HANDLER ==========
COPY handler.py /handler.py

# ========== VERIFICATION ==========
RUN ls -lh /comfyui/models/diffusion_models/ || echo "Check diffusion models"
RUN ls -lh /comfyui/models/text_encoders/ || echo "Check text encoders"
RUN ls -lh /comfyui/models/loras/wan/ || echo "Check Wan LoRAs"

# Use custom handler that supports LoRA selection
CMD ["python", "/handler.py"]

LABEL maintainer="snmaiynitoam"
LABEL description="RunPod ComfyUI: Flux + PuLID + Wan 2.2 Video with LoRAs"
LABEL version="5.0.0"
