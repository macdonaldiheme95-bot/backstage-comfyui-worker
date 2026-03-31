# Deploy Custom ComfyUI on RunPod Serverless

No Docker needed on your machine. GitHub Actions builds the image.

## What's Included

- RealVisXL V5.0 (SDXL checkpoint, baked in)
- ComfyUI_IPAdapter_plus (identity preservation)
- comfyui_controlnet_aux (depth/pose preprocessing)
- IP-Adapter Plus Face SDXL + CLIP Vision
- ControlNet Depth SDXL fp16

## Deploy (5 steps)

### 1. Create accounts (if needed)

- **RunPod**: [runpod.io](https://www.runpod.io) — add a payment method
- **Docker Hub**: [hub.docker.com](https://hub.docker.com) — free account

### 2. Create a GitHub repo

Push the contents of this directory (`deploy/runpod-comfyui/`) to a new GitHub repo:

```bash
cd deploy/runpod-comfyui
git init
git add .
git commit -m "Backstage custom ComfyUI for RunPod"
gh repo create backstage-comfyui-worker --public --push --source .
```

### 3. Add GitHub Secrets

Go to your repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|--------|-------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (Account Settings → Security → New Access Token) |

### 4. Trigger the build

Push a commit or go to Actions tab → "Build ComfyUI Worker" → "Run workflow".

GitHub Actions will build the Docker image (~15-20 min) and push it to Docker Hub as:
```
your-dockerhub-username/backstage-comfyui:latest
```

### 5. Create RunPod Serverless Endpoint

1. Go to [runpod.io/console/serverless](https://www.runpod.io/console/serverless)
2. Click **"New Endpoint"**
3. Configure:
   - **Container Image**: `your-dockerhub-username/backstage-comfyui:latest`
   - **GPU**: RTX A5000 (24GB) or RTX 4090
   - **Min Workers**: 0 (scale to zero)
   - **Max Workers**: 2
   - **Idle Timeout**: 5s
   - **Execution Timeout**: 300s
   - **Container Disk**: 30 GB
4. Create and note the **Endpoint ID**

### 6. Connect to Backstage

Add to `.env.local`:

```env
RUNPOD_API_KEY=your-runpod-api-key
RUNPOD_ENDPOINT_ID=your-endpoint-id
```

The router auto-routes `ipadapter_face` workflows to RunPod. Everything else stays on `fal-ai/comfy`.

## Test

```bash
curl -X POST "https://api.runpod.ai/v2/YOUR_ENDPOINT_ID/runsync" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "workflow": {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "RealVisXL_V5.0_fp16.safetensors"}},
        "5": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"text": "portrait of a woman", "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": "blurry", "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {"model": ["4", 0], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["5", 0], "seed": 42, "steps": 20, "cfg": 5, "sampler_name": "dpmpp_2m_sde", "scheduler": "karras", "denoise": 1.0}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage", "inputs": {"images": ["8", 0], "filename_prefix": "test"}}
      }
    }
  }'
```

## Routing

```
Workflow              → Provider
───────────────────────────────
txt2img               → fal-ai/comfy (vanilla, fast)
img2img               → fal-ai/comfy
inpaint               → fal-ai/comfy
txt2img_lora          → fal-ai/comfy
controlnet_depth      → fal-ai/comfy
ipadapter_face        → RunPod (custom, has IP-Adapter)
```

## Cost

| GPU | Per second | ~Per image (30s) |
|-----|-----------|-----------------|
| RTX A5000 | $0.00025 | ~$0.008 |
| RTX 4090 | $0.00039 | ~$0.012 |

Scale-to-zero: you only pay while generating.
