#!/bin/bash

# Check if a mode argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 {conda|uv}"
    exit 1
fi

MODE=$1

# Function to set up using conda (original, not modified in this process for this report)
conda_setup() {
    echo "Setting up using conda..."
    conda remove --name rppg-toolbox --all -y || exit 1
    conda create -n rppg-toolbox python=3.8 -y || exit 1
    source "$(conda info --base)/etc/profile.d/conda.sh" || exit 1
    conda activate rppg-toolbox || exit 1
    # It's better to install PyTorch via conda if using conda environment
    # pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121
    echo "Installing PyTorch, torchvision, torchaudio with CUDA 12.1 using conda..."
    conda install pytorch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 pytorch-cuda=12.1 -c pytorch -c nvidia -y || { echo "Conda install of PyTorch failed"; exit 1; }
    
    echo "Installing packages from requirements.txt using pip..."
    pip install -r requirements.txt || exit 1
    
    echo "Building and installing mamba_ssm..."
    cd tools/mamba || exit 1
    # Ensure mamba_ssm uses a compatible compiler if needed from conda env, e.g. conda install gcc_linux-64 gxx_linux-64
    python setup.py install || exit 1
    cd ../.. # Go back to project root
    
    echo "Installing PyQt5 using pip..."
    pip install PyQt5 || exit 1
    echo "conda_setup completed."
}

# Function to set up using uv (incorporates all fixes for Python 3.8)
uv_setup() {
    echo "Removing existing .venv directory if present..."
    rm -rf .venv || exit 1

    echo "Creating Python 3.8 virtual environment with uv..."
    uv venv --python python3.8 || exit 1 # Explicitly use python3.8
    
    echo "Activating virtual environment..."
    source .venv/bin/activate || exit 1
    
    echo "Installing setuptools and wheel..."
    uv pip install setuptools wheel || exit 1
    
    echo "Installing pinned build dependencies: Cython (0.29.37), NumPy (~1.21.6), and pkgconfig..."
    # numpy~=1.21.6 is specified here. requirements.txt has numpy==1.22.0. 
    # The one in requirements.txt will likely take precedence or cause uv to resolve.
    # For consistency, it's best if this pre-install matches or is compatible with requirements.txt.
    # Given requirements.txt now dictates numpy==1.22.0, this line could be:
    # uv pip install "Cython==0.29.37" "numpy==1.22.0" pkgconfig || exit 1 
    # Or, if we let requirements.txt handle numpy:
    # uv pip install "Cython==0.29.37" pkgconfig || exit 1 
    # And ensure numpy==1.22.0 is first in requirements.txt or installed before things that need it for build.
    # Current strategy: pre-install an older numpy, let requirements.txt finalize to 1.22.0
    uv pip install "Cython==0.29.37" "numpy~=1.21.6" pkgconfig || exit 1 

    echo "Installing PyTorch with CUDA 12.1 support..."
    uv pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121 || exit 1
    
    echo "Installing packages from requirements.txt..."
    # requirements.txt now contains numpy==1.22.0
    uv pip install -r requirements.txt --no-build-isolation || exit 1
    
    echo "Pre-installing tokenizers==0.13.3 (known compatible version for mamba_ssm's older transformers)..."
    uv pip install "tokenizers==0.13.3" || exit 1

    echo "Ensuring clang is installed (as per rPPG-Toolbox README suggestion for mamba)..."
    if ! command -v clang &> /dev/null || ! command -v clang++ &> /dev/null; then
        echo "clang or clang++ not found. This script assumes the outer script installed it."
        echo "If running independently, please ensure clang is installed or use gcc-11."
        # We will proceed assuming gcc-11 is the primary target based on previous success.
        if ! command -v gcc-11 &> /dev/null; then 
             echo "Warning: gcc-11 also not found. mamba_ssm build might fail."
        fi
    else
        echo "clang and clang++ found."
    fi
    # clang --version # Optional: check version

    echo "Attempting to build mamba_ssm using gcc-11/g++-11..."
    cd tools/mamba 
    echo "Cleaning up previous mamba_ssm build directory..."
    rm -rf build   
    echo "Running mamba_ssm setup.py install with CC=gcc-11 CXX=g++-11..."
    CC=gcc-11 CXX=g++-11 python setup.py install
    INSTALL_STATUS=$? 
    cd ../.. # Go back to the project root directory
    if [ $INSTALL_STATUS -ne 0 ]; then
        echo "Mamba_ssm installation (or its dependency installation) failed!"
        exit 1
    else
        echo "Mamba_ssm successfully installed."
    fi
    
    echo "Installing PyQt5..."
    uv pip install PyQt5 || exit 1

    echo "uv_setup completed successfully!"
}

# Execute the appropriate setup based on the mode
case $MODE in
    conda)
        conda_setup
        ;;
    uv)
        uv_setup
        ;;
    *)
        echo "Invalid mode: $MODE"
        echo "Usage: $0 {conda|uv}"
        exit 1
        ;;
esac
