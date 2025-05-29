#!/bin/bash

# Check if a mode argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 {conda|uv}"
    exit 1
fi

MODE=$1

# Function to set up using conda
conda_setup() {
    echo "Setting up using conda..."
    conda remove --name rppg-toolbox --all -y || exit 1
    conda create -n rppg-toolbox python=3.8 -y || exit 1
    source "$(conda info --base)/etc/profile.d/conda.sh" || exit 1
    conda activate rppg-toolbox || exit 1
    pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121
    pip install -r requirements.txt || exit 1
    cd tools/mamba || exit 1
    python setup.py install || exit 1
}

# Function to set up using uv
# uv_setup() {
#     rm -rf .venv || exit 1
#     uv venv --python 3.8 || exit 1
#     source .venv/bin/activate || exit 1
#     uv pip install setuptools wheel || exit 1
#     uv pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121 || exit 1
#     # uv pip install -r requirements.txt || exit 1
#     uv pip install -r requirements.txt --no-build-isolation || exit 1
#     # cd tools/mamba && python setup.py install || exit 1
#     echo "Attempting to build mamba_ssm with workaround for GCC version..."
#     # cd tools/mamba && CUDAFLAGS="-allow-unsupported-compiler" python setup.py install || exit 1
#     export CUDAFLAGS="-allow-unsupported-compiler"
#     cd tools/mamba && python setup.py install
#     INSTALL_STATUS=$? # Capture the exit status of the install command
#     unset CUDAFLAGS   # Unset the variable so it doesn't affect other commands
#     if [ $INSTALL_STATUS -ne 0 ]; then
#         echo "Mamba_ssm installation failed!"
#         exit 1
#     fi
#     # Explicitly install PyQt5 to use interactive plotting and avoid non-interactive backends
#     # See this relevant issue for more details: https://github.com/astral-sh/uv/issues/6893
#     uv pip install PyQt5
# }
# uv_setup() {
#     rm -rf .venv || exit 1
#     uv venv --python 3.8 || exit 1
#     source .venv/bin/activate || exit 1
#     uv pip install setuptools wheel || exit 1
#     uv pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121 || exit 1
#     uv pip install -r requirements.txt --no-build-isolation || exit 1
    
#     echo "Attempting to build mamba_ssm using gcc-11/g++-11..."
#     cd tools/mamba # Navigate into the mamba directory
    
#     echo "Cleaning up previous mamba_ssm build directory..."
#     rm -rf build   # Remove the old build directory

#     # Explicitly use gcc-11 and g++-11 for this specific build
#     CC=gcc-11 CXX=g++-11 python setup.py install
#     INSTALL_STATUS=$? # Capture the exit status of the install command
    
#     cd ../.. # Go back to the project root directory (e.g., ~/GitHub/rPPG-Toolbox/)
#              # This is important so subsequent commands like PyQt5 install run from the correct place

#     if [ $INSTALL_STATUS -ne 0 ]; then
#         echo "Mamba_ssm installation failed with gcc-11/g++-11!"
#         exit 1
#     fi
    
#     # Explicitly install PyQt5 to use interactive plotting and avoid non-interactive backends
#     # See this relevant issue for more details: https://github.com/astral-sh/uv/issues/6893
#     uv pip install PyQt5
# }

# uv_setup() {
#     rm -rf .venv || exit 1
#     uv venv --python 3.9 || exit 1
#     source .venv/bin/activate || exit 1
#     uv pip install setuptools wheel || exit 1

#     echo "Installing build dependencies: Cython, NumPy, and pkgconfig..."
#     # Add pkgconfig to this line
#     uv pip install Cython "numpy<2" pkgconfig || exit 1 

#     uv pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121 || exit 1

#     echo "Installing packages from requirements.txt..."
#     uv pip install -r requirements.txt --no-build-isolation || exit 1

#     echo "Pre-installing tokenizers to satisfy mamba_ssm dependency..."
#     uv pip install "tokenizers>=0.21,<0.22" || exit 1

#     echo "Attempting to build mamba_ssm using gcc-11/g++-11..."
#     cd tools/mamba 
#     echo "Cleaning up previous mamba_ssm build directory..."
#     rm -rf build   
#     CC=gcc-11 CXX=g++-11 python setup.py install
#     INSTALL_STATUS=$? 
#     cd ../.. 
#     if [ $INSTALL_STATUS -ne 0 ]; then
#         echo "Mamba_ssm installation (or its dependency installation) failed!"
#         exit 1
#     fi

#     uv pip install PyQt5
# }

# uv_setup() {
#     echo "Removing existing .venv directory if present..."
#     rm -rf .venv || exit 1

#     echo "Creating Python 3.9 virtual environment with uv..."
#     uv venv --python 3.9 || exit 1
    
#     echo "Activating virtual environment..."
#     source .venv/bin/activate || exit 1
    
#     echo "Installing setuptools and wheel..."
#     uv pip install setuptools wheel || exit 1
    
#     echo "Installing build dependencies: Cython (0.29.37), NumPy (<2), and pkgconfig..."
#     uv pip install "Cython==0.29.37" "numpy<2" pkgconfig || exit 1 

#     echo "Installing PyTorch with CUDA 12.1 support..."
#     uv pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121 || exit 1
    
#     echo "Installing packages from requirements.txt..."
#     uv pip install -r requirements.txt --no-build-isolation || exit 1
    
#     echo "Pre-installing tokenizers to satisfy mamba_ssm dependency..."
#     uv pip install "tokenizers>=0.21,<0.22" || exit 1

#     echo "Attempting to build mamba_ssm using gcc-11/g++-11..."
#     cd tools/mamba 
#     echo "Cleaning up previous mamba_ssm build directory..."
#     rm -rf build   
#     echo "Running mamba_ssm setup.py install with CC=gcc-11 CXX=g++-11..."
#     CC=gcc-11 CXX=g++-11 python setup.py install
#     INSTALL_STATUS=$? 
#     cd ../.. # Go back to the project root directory (e.g., ~/GitHub/rPPG-Toolbox/)
#     if [ $INSTALL_STATUS -ne 0 ]; then
#         echo "Mamba_ssm installation (or its dependency installation) failed!"
#         exit 1
#     else
#         echo "Mamba_ssm successfully installed."
#     fi
    
#     echo "Installing PyQt5..."
#     uv pip install PyQt5 || exit 1

#     echo "uv_setup completed."
# }

uv_setup() {
    echo "Removing existing .venv directory if present..."
    rm -rf .venv || exit 1

    echo "Creating Python 3.8 virtual environment with uv..."
    uv venv --python 3.8 || exit 1 # Reverted to Python 3.8
    
    echo "Activating virtual environment..."
    source .venv/bin/activate || exit 1
    
    echo "Installing setuptools and wheel..."
    uv pip install setuptools wheel || exit 1
    
    echo "Installing pinned build dependencies: Cython (0.29.x), NumPy (~1.21.6), and pkgconfig..."
    # Pinning to versions closer to what's known to work for rPPG-Toolbox
    uv pip install "Cython==0.29.37" "numpy~=1.21.6" pkgconfig || exit 1 

    echo "Installing PyTorch with CUDA 12.1 support..."
    uv pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121 || exit 1
    
    echo "Installing packages from requirements.txt (ensure versions like scipy, scikit-image, h5py align with a known good config, e.g., scipy==1.5.4)..."
    # It's best if requirements.txt is already aligned with numpy~=1.21.6, scipy==1.5.4, scikit-image==0.17.2, h5py==2.10.0
    uv pip install -r requirements.txt --no-build-isolation || exit 1
    
    echo "Pre-installing tokenizers==0.13.3 to satisfy mamba_ssm dependency (known compatible version)..."
    uv pip install "tokenizers==0.13.3" || exit 1

    echo "Attempting to build mamba_ssm using gcc-11/g++-11..."
    cd tools/mamba 
    echo "Cleaning up previous mamba_ssm build directory..."
    rm -rf build   
    echo "Running mamba_ssm setup.py install with CC=gcc-11 CXX=g++-11..."
    CC=gcc-11 CXX=g++-11 python setup.py install
    INSTALL_STATUS=$? 
    cd ../.. 
    if [ $INSTALL_STATUS -ne 0 ]; then
        echo "Mamba_ssm installation (or its dependency installation) failed!"
        exit 1
    else
        echo "Mamba_ssm successfully installed."
    fi
    
    echo "Installing PyQt5..."
    uv pip install PyQt5 || exit 1

    echo "uv_setup completed."
}


# uv_setup() {
#     echo "Setting up using uv (GCC version should be 11.x)..."
#     rm -rf .venv || exit 1
#     uv venv --python 3.8 || exit 1
#     source .venv/bin/activate || exit 1
#     uv pip install setuptools wheel || exit 1 # Ensure wheel is present for robust installations
#     uv pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121 || exit 1
#     uv pip install -r requirements.txt --no-build-isolation || exit 1

#     echo "Attempting to pre-install 'tokenizers==0.21.1' with uv pip..."
#     # mamba-ssm (via transformers) pulls in tokenizers<0.22,>=0.21, which results in 0.21.1
#     # Installing it with uv pip first should use a wheel or build it correctly.
#     uv pip install tokenizers==0.21.1 || { echo "Failed to install tokenizers==0.21.1 with uv pip!"; exit 1; }

#     echo "Cleaning previous mamba_ssm build..."
#     # Assuming your script is run from the root of rPPG-Toolbox
#     rm -rf tools/mamba/build

#     echo "Attempting to build and install mamba_ssm from local source..."
#     # Navigate to the mamba directory
#     cd tools/mamba || exit 1
#     python setup.py install # This step installs mamba_ssm and its other dependencies like transformers, einops
#     INSTALL_STATUS=$? # Capture the exit status of the install command
#     # Navigate back to the project root
#     cd ../.. || exit 1

#     if [ $INSTALL_STATUS -ne 0 ]; then
#         echo "Mamba_ssm installation failed!" # Reverted to your simpler original message
#         exit 1
#     fi
    
#     echo "Installing PyQt5 for interactive plotting..."
#     uv pip install PyQt5
#     echo "UV setup complete."
# }

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
