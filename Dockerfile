# Backstage Custom ComfyUI — RunPod Serverless
# Base: blib-la/runpod-worker-comfy:3.6.0-sdxl (ComfyUI at /comfyui/, venv at /opt/venv/)
# Adds: IP-Adapter Plus, ControlNet Aux, RealVisXL V5.0, IP-Adapter models

FROM timpietruskyblibla/runpod-worker-comfy:3.6.0-sdxl

# Ensure we use the base image's venv for all pip installs
ENV PATH="/opt/venv/bin:${PATH}"

# Increase timeouts for heavy model loading (IP-Adapter + CLIP Vision + SDXL)
ENV COMFY_API_AVAILABLE_MAX_RETRIES=1000
ENV COMFY_API_AVAILABLE_INTERVAL_MS=500
ENV WEBSOCKET_RECONNECT_ATTEMPTS=20
ENV WEBSOCKET_RECONNECT_DELAY_S=10

# ── Custom Nodes ─────────────────────────────────────────────────────────────

WORKDIR /comfyui/custom_nodes

# IP-Adapter Plus (identity conditioning)
RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git && \
    if [ -f ComfyUI_IPAdapter_plus/requirements.txt ]; then \
      pip install --no-cache-dir -r ComfyUI_IPAdapter_plus/requirements.txt; \
    fi

# ControlNet Aux Preprocessors (depth, openpose, etc.)
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    if [ -f comfyui_controlnet_aux/requirements.txt ]; then \
      pip install --no-cache-dir -r comfyui_controlnet_aux/requirements.txt; \
    fi

# ── Models ───────────────────────────────────────────────────────────────────

WORKDIR /comfyui

# SDXL Checkpoint — RealVisXL V5.0
RUN wget -q --show-progress -O models/checkpoints/RealVisXL_V5.0_fp16.safetensors \
    "https://huggingface.co/SG161222/RealVisXL_V5.0/resolve/main/RealVisXL_V5.0_fp16.safetensors"

# IP-Adapter Plus Face (SDXL)
RUN mkdir -p models/ipadapter && \
    wget -q --show-progress -O models/ipadapter/ip-adapter-plus-face_sdxl_vit-h.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus-face_sdxl_vit-h.safetensors"

# CLIP Vision ViT-H (required by IP-Adapter)
RUN mkdir -p models/clip_vision && \
    wget -q --show-progress -O models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors"

# ControlNet Depth (SDXL, fp16)
RUN mkdir -p models/controlnet && \
    wget -q --show-progress -O models/controlnet/controlnet-depth-sdxl-fp16.safetensors \
    "https://huggingface.co/diffusers/controlnet-depth-sdxl-1.0/resolve/main/diffusion_pytorch_model.fp16.safetensors"

# Verify custom nodes are discoverable
RUN ls -la /comfyui/custom_nodes/ && \
    python -c "import sys; sys.path.insert(0, '/comfyui'); print('Custom nodes dir OK')"

WORKDIR /
