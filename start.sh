#!/bin/bash

# Start ComfyUI in background
echo "Starting ComfyUI..."
cd /comfyui
python main.py --listen 0.0.0.0 --port 8188 &

# Wait for ComfyUI to be ready
echo "Waiting for ComfyUI to start..."
for i in {1..120}; do
    if curl -s http://127.0.0.1:8188/system_stats > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        break
    fi
    sleep 1
done

# Start our handler
echo "Starting RunPod handler..."
python /handler.py
