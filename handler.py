"""
RunPod Handler for Wan 2.2 Video Generation with LoRA support
"""
import runpod
import json
import base64
import os
import requests
import time
from pathlib import Path

# Import ComfyUI execution
import sys
sys.path.insert(0, '/comfyui')
from main import main as comfy_main

COMFYUI_URL = "http://127.0.0.1:8188"

# Available LoRAs (pre-installed in Docker image)
AVAILABLE_LORAS = {
    "blowjob": "wan/WAN-2.2-I2V-HandjobBlowjobCombo-HIGH-v1.safetensors",
    "deepthroat": "wan/jfj-deepthroat-W22-T2V-HN-v1.safetensors",
}

def download_image(url: str, save_path: str) -> bool:
    """Download image from URL"""
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        with open(save_path, 'wb') as f:
            f.write(response.content)
        return True
    except Exception as e:
        print(f"Failed to download image: {e}")
        return False

def wait_for_comfyui(max_wait: int = 60) -> bool:
    """Wait for ComfyUI to be ready"""
    for i in range(max_wait):
        try:
            response = requests.get(f"{COMFYUI_URL}/system_stats", timeout=5)
            if response.status_code == 200:
                print(f"ComfyUI ready after {i} seconds")
                return True
        except:
            pass
        time.sleep(1)
    return False

def build_workflow(
    image_path: str,
    prompt: str,
    negative_prompt: str,
    width: int = 448,
    height: int = 640,
    num_frames: int = 81,
    steps: int = 30,
    cfg: float = 5.0,
    seed: int = -1,
    lora_name: str = None,
    lora_strength: float = 1.0
) -> dict:
    """Build ComfyUI workflow for Wan 2.2 I2V generation"""

    # Generate random seed if -1
    if seed == -1:
        import random
        seed = random.randint(0, 2147483647)

    workflow = {
        "1": {
            "class_type": "LoadImage",
            "inputs": {
                "image": image_path
            }
        },
        "2": {
            "class_type": "WanVideoModelLoader",
            "inputs": {
                "model": "wan2.2_i2v_14B_fp8.safetensors",
                "precision": "fp8_scaled",
                "quantization": "disabled",
                "attention": "sdpa"
            }
        },
        "3": {
            "class_type": "WanVideoVAELoader",
            "inputs": {
                "vae": "wan_2.1_vae.safetensors",
                "precision": "bf16"
            }
        },
        "4": {
            "class_type": "WanVideoTextEncoderLoader",
            "inputs": {
                "text_encoder": "umt5_xxl_fp16.safetensors",
                "precision": "fp16",
                "attention": "sdpa"
            }
        },
        "5": {
            "class_type": "CLIPVisionLoader",
            "inputs": {
                "clip_name": "clip_vision_h.safetensors"
            }
        },
        "6": {
            "class_type": "WanVideoTextEncode",
            "inputs": {
                "prompt": prompt,
                "negative_prompt": negative_prompt,
                "t5": ["4", 0]
            }
        },
        "7": {
            "class_type": "WanVideoClipVisionEncode",
            "inputs": {
                "clip_vision": ["5", 0],
                "image": ["1", 0],
                "strength": 1.0
            }
        },
        "8": {
            "class_type": "WanVideoImageToVideoLatents",
            "inputs": {
                "vae": ["3", 0],
                "clip_embeds": ["7", 0],
                "start_image": ["1", 0],
                "width": width,
                "height": height,
                "num_frames": num_frames
            }
        }
    }

    # Add LoRA if specified
    model_output = ["2", 0]
    if lora_name and lora_name in AVAILABLE_LORAS:
        workflow["lora"] = {
            "class_type": "LoraLoader",
            "inputs": {
                "model": ["2", 0],
                "lora_name": AVAILABLE_LORAS[lora_name],
                "strength_model": lora_strength,
                "strength_clip": 0  # Video LoRAs typically don't affect CLIP
            }
        }
        model_output = ["lora", 0]

    # Sampler
    workflow["9"] = {
        "class_type": "WanVideoSampler",
        "inputs": {
            "model": model_output,
            "text_embeds": ["6", 0],
            "image_embeds": ["8", 0],
            "seed": seed,
            "steps": steps,
            "cfg": cfg,
            "shift": 5.0,
            "sampler": "unipc"
        }
    }

    # Decode
    workflow["10"] = {
        "class_type": "WanVideoDecode",
        "inputs": {
            "vae": ["3", 0],
            "samples": ["9", 0]
        }
    }

    # Output as video
    workflow["11"] = {
        "class_type": "VHS_VideoCombine",
        "inputs": {
            "images": ["10", 0],
            "frame_rate": 16,
            "format": "video/mp4",
            "save_output": False
        }
    }

    return workflow

def execute_workflow(workflow: dict) -> dict:
    """Execute workflow in ComfyUI and get result"""
    import uuid

    prompt_id = str(uuid.uuid4())

    # Queue the prompt
    response = requests.post(
        f"{COMFYUI_URL}/prompt",
        json={
            "prompt": workflow,
            "client_id": prompt_id
        }
    )

    if response.status_code != 200:
        raise Exception(f"Failed to queue prompt: {response.text}")

    result = response.json()
    prompt_id = result.get("prompt_id", prompt_id)

    # Poll for completion
    max_wait = 600  # 10 minutes
    start = time.time()

    while time.time() - start < max_wait:
        history_response = requests.get(f"{COMFYUI_URL}/history/{prompt_id}")
        if history_response.status_code == 200:
            history = history_response.json()
            if prompt_id in history:
                return history[prompt_id]
        time.sleep(2)

    raise Exception("Timeout waiting for generation")

def handler(event):
    """RunPod handler function"""
    try:
        job_input = event.get("input", {})

        # Extract parameters
        image_url = job_input.get("image_url")
        prompt = job_input.get("prompt", "smooth motion, high quality video")
        negative_prompt = job_input.get("negative_prompt", "blurry, distorted, low quality")
        width = job_input.get("width", 448)
        height = job_input.get("height", 640)
        length = job_input.get("length", 81)
        steps = job_input.get("steps", 30)
        cfg = job_input.get("cfg", 5.0)
        seed = job_input.get("seed", -1)
        lora = job_input.get("lora")  # "blowjob" or "deepthroat"
        lora_strength = job_input.get("lora_strength", 1.0)

        if not image_url:
            return {"error": "image_url is required"}

        print(f"Received job: prompt={prompt[:50]}..., lora={lora}")

        # Wait for ComfyUI
        if not wait_for_comfyui():
            return {"error": "ComfyUI not ready"}

        # Download input image
        work_dir = Path(f"/tmp/job_{event.get('id', 'unknown')}")
        work_dir.mkdir(exist_ok=True)
        input_image = work_dir / "input.png"

        if not download_image(image_url, str(input_image)):
            return {"error": "Failed to download image"}

        # Build and execute workflow
        workflow = build_workflow(
            image_path=str(input_image),
            prompt=prompt,
            negative_prompt=negative_prompt,
            width=width,
            height=height,
            num_frames=length,
            steps=steps,
            cfg=cfg,
            seed=seed,
            lora_name=lora,
            lora_strength=lora_strength
        )

        result = execute_workflow(workflow)

        # Extract video output
        outputs = result.get("outputs", {})
        for node_id, output in outputs.items():
            if "gifs" in output or "videos" in output:
                videos = output.get("videos", output.get("gifs", []))
                if videos:
                    video_path = videos[0].get("filename")
                    if video_path:
                        # Read and encode video
                        full_path = Path("/comfyui/output") / video_path
                        if full_path.exists():
                            with open(full_path, "rb") as f:
                                video_data = base64.b64encode(f.read()).decode()
                            return {"video": video_data}

        return {"error": "No video output found"}

    except Exception as e:
        print(f"Error: {e}")
        return {"error": str(e)}

# Start the handler
runpod.serverless.start({"handler": handler})
