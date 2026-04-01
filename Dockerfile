# Backstage Custom ComfyUI — RunPod Serverless
# Base: blib-la/runpod-worker-comfy:3.6.0-sdxl (includes SDXL base + ComfyUI at /comfyui/)
# Adds: IP-Adapter Plus, ControlNet Aux, RealVisXL V5.0, IP-Adapter models

FROM timpietruskyblibla/runpod-worker-comfy:3.6.0-sdxl

# ── Custom Nodes via comfy-cli registry ──────────────────────────────────────

# IP-Adapter Plus (identity conditioning)
RUN comfy-node-install comfyui-ipadapter-plus

# ControlNet Aux Preprocessors (depth, openpose, etc.)
RUN comfy-node-install comfyui-controlnet-aux

# ── Models ───────────────────────────────────────────────────────────────────

WORKDIR /comfyui

# SDXL Checkpoint — RealVisXL V5.0 (replace default SDXL base)
RUN wget -q --show-progress -O models/checkpoints/RealVisXL_V5.0_fp16.safetensors \
    "https://huggingface.co/SG161222/RealVisXL_V5.0/resolve/main/RealVisXL_V5.0_fp16.safetensors"

# IP-Adapter Plus Face (SDXL) — identity from face reference
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

WORKDIR /
