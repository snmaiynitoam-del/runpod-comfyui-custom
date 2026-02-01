# RunPod ComfyUI Worker - Wan 2.2 Video Only (Lightweight)
FROM runpod/worker-comfyui:5.7.1-base

# ========== WAN 2.2 VIDEO NODES ==========
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper && \
    cd ComfyUI-WanVideoWrapper && pip install -r requirements.txt

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite && \
    cd ComfyUI-VideoHelperSuite && pip install -r requirements.txt

# ========== CREATE DIRECTORIES ==========
RUN mkdir -p /comfyui/models/diffusion_models \
    /comfyui/models/text_encoders \
    /comfyui/models/clip_vision \
    /comfyui/models/vae \
    /comfyui/models/loras/wan

# ========== WAN 2.2 MODELS ==========
# Wan 2.2 I2V Model FP8 (~14.3GB) - using high_noise variant for better quality
RUN wget -O /comfyui/models/diffusion_models/wan2.2_i2v_14B_fp8.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"

# Text Encoder FP16 (~11.4GB)
RUN wget -O /comfyui/models/text_encoders/umt5_xxl_fp16.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp16.safetensors"

# VAE (~254MB)
RUN wget -O /comfyui/models/vae/wan_2.1_vae.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

# CLIP Vision for I2V (~1.26GB)
RUN wget -O /comfyui/models/clip_vision/clip_vision_h.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

# ========== VIDEO LORAS ==========
RUN wget -O /comfyui/models/loras/wan/WAN-2.2-I2V-HandjobBlowjobCombo-HIGH-v1.safetensors \
    "https://huggingface.co/snailmana99/wan22-video-loras/resolve/main/WAN-2.2-I2V-HandjobBlowjobCombo-HIGH-v1.safetensors"

RUN wget -O /comfyui/models/loras/wan/jfj-deepthroat-W22-T2V-HN-v1.safetensors \
    "https://huggingface.co/snailmana99/wan22-video-loras/resolve/main/jfj-deepthroat-W22-T2V-HN-v1.safetensors"

# ========== CUSTOM HANDLER ==========
RUN pip install runpod requests
COPY handler.py /handler.py
COPY start.sh /start.sh
RUN chmod +x /start.sh && sed -i 's/\r$//' /start.sh

# ========== VERIFICATION ==========
RUN ls -lh /comfyui/models/diffusion_models/ && \
    ls -lh /comfyui/models/text_encoders/ && \
    ls -lh /comfyui/models/loras/wan/

CMD ["/start.sh"]

LABEL maintainer="snmaiynitoam"
LABEL description="RunPod ComfyUI: Wan 2.2 Video with LoRAs (Lightweight)"
LABEL version="5.1.0"
