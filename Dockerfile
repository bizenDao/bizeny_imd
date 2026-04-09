FROM bizenyakiko/genai-base:1.1

# Install ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI && \
    cd /ComfyUI && \
    pip install -r requirements.txt

# Install ComfyUI-Manager
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git && \
    cd ComfyUI-Manager && \
    pip install -r requirements.txt || true

# Install handler dependencies
RUN pip install runpod websocket-client Pillow

# Download checkpoint at build time for stable mmap loading
RUN mkdir -p /ComfyUI/models/checkpoints
ARG CIVITAI_API_TOKEN
RUN if [ -n "$CIVITAI_API_TOKEN" ]; then \
      wget -q "https://civitai.com/api/download/models/2824082?token=${CIVITAI_API_TOKEN}" \
        -O /ComfyUI/models/checkpoints/UnholyDesireMixSinisterAesthetic_V8.safetensors && \
      echo "Checkpoint baked in ($(du -h /ComfyUI/models/checkpoints/UnholyDesireMixSinisterAesthetic_V8.safetensors | cut -f1))"; \
    else \
      echo "WARNING: CIVITAI_API_TOKEN not provided, checkpoint will be downloaded at runtime"; \
    fi

# Copy files
COPY handler.py /handler.py
COPY download_lora.py /download_lora.py
COPY model.json /model.json
COPY lora.json /lora.json
COPY extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Fallback dummy LoRA for strength=0 passthrough
RUN touch /ComfyUI/models/loras/default.safetensors

ENTRYPOINT ["/entrypoint.sh"]
