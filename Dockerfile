# Backstage Custom ComfyUI — RunPod Serverless
# Base: blib-la/runpod-worker-comfy (SDXL variant, CUDA + ComfyUI pre-installed)
# Adds: IP-Adapter Plus, ControlNet Aux, pre-baked models

FROM timpietruskyblibla/runpod-worker-comfy:3.6.0-sdxl

# ── Custom Nodes ─────────────────────────────────────────────────────────────

WORKDIR /comfyui/custom_nodes

# IP-Adapter Plus (identity preservation)
RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git && \
    (cd ComfyUI_IPAdapter_plus && pip install --no-cache-dir -r requirements.txt 2>/dev/null || true)

# ControlNet Aux Preprocessors (depth estimation, pose detection, etc.)
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    (cd comfyui_controlnet_aux && pip install --no-cache-dir -r requirements.txt 2>/dev/null || true)

# ── Models ───────────────────────────────────────────────────────────────────

# SDXL Checkpoint — RealVisXL V5.0 (photorealistic)
RUN wget -q --show-progress -O /comfyui/models/checkpoints/RealVisXL_V5.0_fp16.safetensors \
    "https://huggingface.co/SG161222/RealVisXL_V5.0/resolve/main/RealVisXL_V5.0_fp16.safetensors"

# IP-Adapter Plus Face (SDXL) — identity from face reference
RUN mkdir -p /comfyui/models/ipadapter && \
    wget -q --show-progress -O /comfyui/models/ipadapter/ip-adapter-plus-face_sdxl_vit-h.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus-face_sdxl_vit-h.safetensors"

# CLIP Vision ViT-H (required by IP-Adapter)
RUN mkdir -p /comfyui/models/clip_vision && \
    wget -q --show-progress -O /comfyui/models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors"

# ControlNet Depth (SDXL, fp16)
RUN mkdir -p /comfyui/models/controlnet && \
    wget -q --show-progress -O /comfyui/models/controlnet/controlnet-depth-sdxl-fp16.safetensors \
    "https://huggingface.co/diffusers/controlnet-depth-sdxl-1.0/resolve/main/diffusion_pytorch_model.fp16.safetensors"

WORKDIR /
