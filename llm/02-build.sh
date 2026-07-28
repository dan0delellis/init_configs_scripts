#!/bin/bash
# Redirect logs so you can inspect output later if running completely headless
exec > /var/log/llama_setup_part2.log 2>&1

# 1. Clean up the cron entry immediately so it never loops
rm -f /etc/cron.d/part2

# 2. Configure Docker to mount the live NVIDIA runtime
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker


# 4. Clone and compile llama.cpp locally targeting Compute Capability 7.5
if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggml-org/llama.cpp.git
else
	git -C llama.cpp pull -r
fi
cd llama.cpp

# Clean up any failed manual build attempts if the folder somehow existed
rm -rf build

cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=75 -DLLAMA_CURL=ON
cmake --build build --config Release -j$(nproc)

echo "=== AUTOMATION SUCCESSFUL ==="
echo "You can check your GPU state using: nvidia-smi"
echo "You can run your compiled binary at: /root/llama.cpp/build/bin/llama-cli"
