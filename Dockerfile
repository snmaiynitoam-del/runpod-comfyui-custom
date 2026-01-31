# RunPod ComfyUI Worker with Flux-Uncensored-V2 LoRA + PuLID + Wan 2.1 Video
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

# Install Wan dependencies
RUN pip install --no-cache-dir ftfy

# Wan Video Wrapper custom node (for I2V support)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper && \
    cd ComfyUI-WanVideoWrapper && pip install -r requirements.txt || true

# GGUF support for quantized models (saves VRAM)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF

# Create Wan model directories
RUN mkdir -p /comfyui/models/wan /comfyui/models/text_encoders

# Download Wan 2.1 I2V Model (GGUF Q8 quantized ~14GB - good quality/size balance)
RUN wget -O /comfyui/models/wan/Wan2.1-I2V-14B-480P-Q8_0.gguf \
    "https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/Wan2.1-I2V-14B-480P-Q8_0.gguf"

# Download Wan VAE
RUN wget -O /comfyui/models/vae/Wan2_1_VAE_bf16.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/Wan2_1_VAE_bf16.safetensors"

# Download UMT5-XXL Text Encoder (GGUF quantized to save space)
RUN wget -O /comfyui/models/text_encoders/umt5-xxl-Q8_0.gguf \
    "https://huggingface.co/city96/umt5-xxl-gguf/resolve/main/umt5-xxl-Q8_0.gguf"

# Verify Wan installation
RUN ls -lh /comfyui/models/wan/Wan2.1-I2V-14B-480P-Q8_0.gguf || \
    (echo "Wan model not found!" && exit 1)

# ========== END WAN ==========

LABEL maintainer="snmaiynitoam"
LABEL description="RunPod ComfyUI: Flux + PuLID + Wan 2.1 Video"
LABEL version="3.0.0"
