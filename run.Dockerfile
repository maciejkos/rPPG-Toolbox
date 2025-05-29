# 1. Start with Ubuntu 22.04 LTS as the base image.
# Python 3.8 packages are available directly in its repositories.
FROM ubuntu:22.04

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install basic utilities, Python 3.8, compilers, and system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    # Python 3.8 and related dev packages
    python3.8 \
    python3.8-venv \
    python3.8-dev \
    python3-pip \
    # Compilers (gcc-11 is compatible with CUDA 12.1)
    gcc-11 \
    g++-11 \
    clang \
    # HDF5 and pkg-config (for h5py build)
    pkg-config \
    libhdf5-dev \
    # Other build essentials and tools
    build-essential \
    ninja-build \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 3. Install CUDA Toolkit 12.1 core components
# Add NVIDIA CUDA repository for WSL-Ubuntu
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.0-1_all.deb -P /tmp && \
    dpkg -i /tmp/cuda-keyring_1.0-1_all.deb && \
    apt-get update && \
    rm /tmp/cuda-keyring_1.0-1_all.deb

# Install core CUDA 12.1 components
RUN apt-get install -y --no-install-recommends \
    cuda-compiler-12-1 \
    cuda-libraries-12-1 \
    cuda-libraries-dev-12-1 \
    cuda-nvcc-12-1 \
    cuda-cudart-dev-12-1 \
    cuda-driver-dev-12-1 \
    libcublas-12-1 \
    libcublas-dev-12-1 \
    libcufft-12-1 \
    libcufft-dev-12-1 \
    libcurand-12-1 \
    libcurand-dev-12-1 \
    libcusolver-12-1 \
    libcusolver-dev-12-1 \
    libcusparse-12-1 \
    libcusparse-dev-12-1 \
    libnvjpeg-12-1 \
    libnvjpeg-dev-12-1 \
    cuda-tools-12-1 \
    && rm -rf /var/lib/apt/lists/*

# Set up PATH and LD_LIBRARY_PATH for CUDA
ENV PATH="/usr/local/cuda-12.1/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda-12.1/lib64:${LD_LIBRARY_PATH}"

# 4. Set up the application directory and copy project files
WORKDIR /app
COPY . /app/
# IMPORTANT: Before building this Docker image, ensure that:
# 1. Your local 'requirements.txt' has the correct pinned versions 
#    (e.g., numpy==1.22.0, scipy==1.5.4, scikit-image==0.17.2, h5py==2.10.0).
# 2. Your local 'tools/mamba/setup.py' has 'transformers' pinned to 'transformers==4.25.1'.

# 5. Install uv (Python package manager) and create Python virtual environment
RUN apt-get update && apt-get install -y curl && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    rm -rf /var/lib/apt/lists/*

# Add uv to PATH. Default uv install path for root user if not using cargo.
# If cargo is used by the installer, /root/.cargo/bin might be it.
# $HOME for root is /root.
ENV PATH="/root/.local/bin:${PATH}" 
# If uv is installed via cargo by the script, it might be:
# ENV PATH="/root/.cargo/bin:${PATH}" 

# Create Python 3.8 virtual environment using uv
RUN uv venv --python python3.8 .venv

# "Activate" the virtual environment for subsequent RUN commands
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:${PATH}"

# 6. Install Python dependencies using the successful strategy
RUN uv pip install setuptools wheel
RUN uv pip install "Cython==0.29.37" "numpy~=1.21.6" pkgconfig 
    # Note: numpy~=1.21.6 is installed here. 
    # requirements.txt specifies numpy==1.22.0, which uv will resolve to.
RUN uv pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121
RUN uv pip install -r requirements.txt --no-build-isolation
RUN uv pip install "tokenizers==0.13.3"

# Build and install mamba_ssm
RUN cd tools/mamba && \
    rm -rf build && \
    CC=gcc-11 CXX=g++-11 python setup.py install && \
    cd /app # Go back to app root

# Install PyQt5
RUN uv pip install PyQt5

# 7. Set up entrypoint or default command (optional)
# e.g., CMD ["python", "your_main_script_to_run_rppg_toolbox.py"]
# For a development environment, you might just want a shell:
CMD ["bash"]

