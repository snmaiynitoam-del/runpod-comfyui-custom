"""
RunPod Handler for Wan 2.2 Video Generation with LoRA support
"""
import runpod
import json
import base64
import os
import requests
import time
import shutil
from pathlib import Path

print("Handler module loading...")

COMFYUI_URL = "http://127.0.0.1:8188"

# Available LoRAs (pre-installed in Docker image)
AVAILABLE_LORAS = {
    "blowjob": "wan/WAN-2.2-I2V-HandjobBlowjobCombo-HIGH-v1.safetensors",
    "deepthroat": "wan/jfj-deepthroat-W22-T2V-HN-v1.safetensors",
}

def download_image(url: str, save_path: str) -> bool:
    """Download image from URL"""
    try:
        print(f"Downloading image from {url[:50]}...")
        response = requests.get(url, timeout=60)
        response.raise_for_status()
        with open(save_path, 'wb') as f:
            f.write(response.content)
        print(f"Image saved to {save_path}")
        return True
    except Exception as e:
        print(f"Failed to download image: {e}")
        return False

def wait_for_comfyui(max_wait: int = 120) -> bool:
    """Wait for ComfyUI to be ready"""
    print("Waiting for ComfyUI to be ready...")
    for i in range(max_wait):
        try:
            response = requests.get(f"{COMFYUI_URL}/system_stats", timeout=5)
            if response.status_code == 200:
                print(f"ComfyUI ready after {i} seconds")
                return True
        except Exception as e:
            if i % 10 == 0:
                print(f"Waiting... ({i}s) - {e}")
        time.sleep(1)
    print("ComfyUI did not become ready in time")
    return False

def build_workflow(
    image_filename: str,
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
    """Build ComfyUI API workflow for Wan 2.2 I2V generation"""

    import random
    if seed == -1:
        seed = random.randint(0, 2147483647)

    # Resolve LoRA path if specified
    lora_path = None
    if lora_name and lora_name in AVAILABLE_LORAS:
        lora_path = AVAILABLE_LORAS[lora_name]
        print(f"Using LoRA: {lora_name} -> {lora_path} (strength: {lora_strength})")

    # Build the workflow using ComfyUI API format
    workflow = {
        "1": {
            "class_type": "LoadImage",
            "inputs": {
                "image": image_filename
            }
        },
        "2": {
            "class_type": "DownloadAndLoadWanVideoModel",
            "inputs": {
                "model": "wan2.2_i2v_14B_fp8.safetensors",
                "base_precision": "fp8_e4m3fn",
                "quantization": "disabled"
            }
        },
        "3": {
            "class_type": "DownloadAndLoadWanVideoVAE",
            "inputs": {
                "vae": "wan_2.1_vae.safetensors",
                "precision": "bf16"
            }
        },
        "4": {
            "class_type": "DownloadAndLoadWanVideoTextEncoder",
            "inputs": {
                "model": "umt5_xxl_fp16.safetensors",
                "precision": "bf16"
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
                "positive_prompt": prompt,
                "negative_prompt": negative_prompt,
                "wan_text_encoder": ["4", 0]
            }
        },
        "7": {
            "class_type": "CLIPVisionEncode",
            "inputs": {
                "clip_vision": ["5", 0],
                "image": ["1", 0]
            }
        },
        "8": {
            "class_type": "WanVideoImageEncode",
            "inputs": {
                "wan_vae": ["3", 0],
                "image": ["1", 0],
                "enable_vae_encode": True
            }
        }
    }

    # Determine which model output to use for sampler
    # If LoRA is specified, we need to add LoRA nodes and use modified model
    model_output_node = "2"  # Default: direct from model loader

    if lora_path:
        # Add LoRA selection node
        workflow["12"] = {
            "class_type": "WanVideoLoraSelect",
            "inputs": {
                "lora": lora_path,
                "strength": lora_strength
            }
        }
        # Add LoRA application node
        workflow["13"] = {
            "class_type": "WanVideoSetLoRAs",
            "inputs": {
                "model": ["2", 0],
                "lora": ["12", 0]
            }
        }
        model_output_node = "13"  # Use LoRA-modified model

    # Add sampler with correct model reference
    workflow["9"] = {
        "class_type": "WanVideoSampler",
        "inputs": {
            "wan_model": [model_output_node, 0],
            "wan_embeds": ["6", 0],
            "wan_latent_image": ["8", 0],
            "clip_image_embeds": ["7", 0],
            "seed": seed,
            "steps": steps,
            "cfg": cfg,
            "shift": 5.0,
            "scheduler": "dpm",
            "width": width,
            "height": height,
            "num_frames": num_frames
        }
    }

    # Add decoder and video output
    workflow["10"] = {
        "class_type": "WanVideoDecode",
        "inputs": {
            "wan_vae": ["3", 0],
            "samples": ["9", 0]
        }
    }
    workflow["11"] = {
        "class_type": "VHS_VideoCombine",
        "inputs": {
            "images": ["10", 0],
            "frame_rate": 16,
            "loop_count": 0,
            "filename_prefix": "wan_video",
            "format": "video/h264-mp4",
            "pingpong": False,
            "save_output": True
        }
    }

    return workflow

def execute_workflow(workflow: dict) -> dict:
    """Execute workflow in ComfyUI and get result"""
    import uuid

    client_id = str(uuid.uuid4())

    print(f"Queueing workflow with client_id: {client_id}")

    # Queue the prompt
    response = requests.post(
        f"{COMFYUI_URL}/prompt",
        json={
            "prompt": workflow,
            "client_id": client_id
        }
    )

    if response.status_code != 200:
        raise Exception(f"Failed to queue prompt: {response.status_code} - {response.text}")

    result = response.json()
    prompt_id = result.get("prompt_id")
    print(f"Prompt queued with ID: {prompt_id}")

    # Poll for completion
    max_wait = 600  # 10 minutes
    start = time.time()

    while time.time() - start < max_wait:
        try:
            history_response = requests.get(f"{COMFYUI_URL}/history/{prompt_id}")
            if history_response.status_code == 200:
                history = history_response.json()
                if prompt_id in history:
                    status = history[prompt_id].get("status", {})
                    if status.get("completed", False):
                        print("Workflow completed!")
                        return history[prompt_id]
                    if status.get("status_str") == "error":
                        raise Exception(f"Workflow error: {history[prompt_id]}")
        except Exception as e:
            print(f"Poll error: {e}")

        time.sleep(3)
        elapsed = int(time.time() - start)
        if elapsed % 30 == 0:
            print(f"Still processing... ({elapsed}s)")

    raise Exception("Timeout waiting for generation")

def handler(event):
    """RunPod handler function"""
    print(f"=== Handler received job ===")
    try:
        job_input = event.get("input", {})
        job_id = event.get("id", "unknown")

        print(f"Job ID: {job_id}")
        print(f"Input keys: {list(job_input.keys())}")

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
        lora = job_input.get("lora")
        lora_strength = job_input.get("lora_strength", 1.0)

        if not image_url:
            return {"error": "image_url is required"}

        print(f"Prompt: {prompt[:80]}...")
        print(f"LoRA: {lora}, Size: {width}x{height}, Frames: {length}")

        # Wait for ComfyUI
        if not wait_for_comfyui():
            return {"error": "ComfyUI not ready after 120s"}

        # Download input image to ComfyUI input folder
        input_dir = Path("/comfyui/input")
        input_dir.mkdir(exist_ok=True)

        image_filename = f"input_{job_id}.png"
        image_path = input_dir / image_filename

        if not download_image(image_url, str(image_path)):
            return {"error": "Failed to download input image"}

        # Build and execute workflow
        print("Building workflow...")
        workflow = build_workflow(
            image_filename=image_filename,
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

        print("Executing workflow...")
        result = execute_workflow(workflow)

        # Extract video output
        outputs = result.get("outputs", {})
        print(f"Output nodes: {list(outputs.keys())}")

        for node_id, output in outputs.items():
            print(f"Node {node_id} output keys: {list(output.keys())}")
            if "gifs" in output or "videos" in output:
                videos = output.get("videos", output.get("gifs", []))
                if videos:
                    video_info = videos[0]
                    video_filename = video_info.get("filename")
                    subfolder = video_info.get("subfolder", "")

                    if video_filename:
                        if subfolder:
                            full_path = Path("/comfyui/output") / subfolder / video_filename
                        else:
                            full_path = Path("/comfyui/output") / video_filename

                        print(f"Looking for video at: {full_path}")

                        if full_path.exists():
                            print(f"Video found! Size: {full_path.stat().st_size} bytes")
                            with open(full_path, "rb") as f:
                                video_data = base64.b64encode(f.read()).decode()

                            # Cleanup
                            try:
                                image_path.unlink()
                                full_path.unlink()
                            except:
                                pass

                            return {"video": video_data}
                        else:
                            print(f"Video file not found at {full_path}")

        return {"error": "No video output found in workflow result"}

    except Exception as e:
        import traceback
        print(f"Handler error: {e}")
        print(traceback.format_exc())
        return {"error": str(e)}

print("Starting RunPod serverless handler...")
runpod.serverless.start({"handler": handler})
