#!/bin/bash

# Full Setup Script for rPPG-Toolbox on WSL2 Ubuntu 22.04 LTS
# Assumes it's run with sudo privileges or the user can sudo when prompted.
# Assumes NVIDIA host drivers are already installed on Windows.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
# RPPG_TOOLBOX_REPO_URL="https://github.com/ubicomplab/rPPG-Toolbox.git" # Or your fork
RPPG_TOOLBOX_REPO_URL="https://github.com/maciejkos/rPPG-Toolbox.git" 
RPPG_TOOLBOX_DIR_NAME="rPPG-Toolbox"
INSTALL_DIR="$HOME/GitHub" # Directory where the repo will be cloned
YOUR_USERNAME="macie" # Define your username here


# --- Helper Functions ---
print_header() {
    echo "================================================================================"
    echo "$1"
    echo "================================================================================"
}

check_command_success() {
    if [ $? -ne 0 ]; then
        echo "Error: The last command failed. Aborting script."
        exit 1
    fi
}

# --- Main Script ---

print_header "Starting rPPG-Toolbox Full Setup for WSL2 Ubuntu 22.04 LTS"

# 1. Update package lists and install essential build tools & utilities
print_header "Updating system and installing prerequisites..."
sudo apt-get update
check_command_success
sudo apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    git \
    build-essential \
    python3.8 \
    python3.8-venv \
    python3.8-dev \
    gcc-11 \
    g++-11 \
    clang \
    pkg-config \
    libhdf5-dev \
    curl # For installing uv
check_command_success
echo "System prerequisites installed."

# 2. Install uv (Python package manager)
print_header "Installing uv..."
if ! command -v uv &> /dev/null; then
    # Ensure .profile sources .bashrc or that .local/bin is in PATH for non-interactive shells if needed
    # For interactive shells, uv installer usually updates .bashrc or .profile
    curl -LsSf https://astral.sh/uv/install.sh | sh
    check_command_success
    # Add uv to PATH for the current script execution
    # This depends on where 'uv' was installed. Common locations are $HOME/.cargo/bin or $HOME/.local/bin for user installs.
    # The uv installer script itself should ideally make 'uv' available in new shells.
    # For the current script, we might need to explicitly add its typical installation path if not already there.
    if [ -f "$HOME/.cargo/env" ]; then # If installed via rust/cargo
        source "$HOME/.cargo/env"
    fi
    # Attempt to add common uv install path if not already in PATH
    UV_PATH_CANDIDATE="$HOME/.local/bin"
    if [ -d "$UV_PATH_CANDIDATE" ] && [[ ":$PATH:" != *":${UV_PATH_CANDIDATE}:"* ]]; then
        export PATH="$UV_PATH_CANDIDATE:$PATH"
    fi
    
    if ! command -v uv &> /dev/null; then
       echo "Error: uv installation failed or uv is not in PATH. Please install uv manually and ensure it's in your PATH."
       echo "Visit https://astral.sh/uv for instructions."
       exit 1
    fi
    echo "uv installed successfully."
else
    echo "uv is already installed."
fi
uv --version

# 3. Install CUDA Toolkit 12.1 (Core Components)
print_header "Setting up NVIDIA CUDA Toolkit 12.1 repository and installing core components..."
# Download the keyring
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.0-1_all.deb -P /tmp
check_command_success
# Install the keyring
sudo dpkg -i /tmp/cuda-keyring_1.0-1_all.deb
check_command_success
sudo apt-get update
check_command_success
# Clean up the downloaded .deb file
rm /tmp/cuda-keyring_1.0-1_all.deb

# Install Core CUDA 12.1 Components
sudo apt-get install -y --no-install-recommends \
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
    cuda-tools-12-1
check_command_success
echo "Core CUDA 12.1 components installed."

# Verify nvcc installation and add to PATH for this session if needed
if ! command -v nvcc &> /dev/null || ! nvcc --version | grep -q "release 12.1"; then
    echo "nvcc not found correctly or is not version 12.1. Attempting to set PATH for this session."
    export PATH=/usr/local/cuda-12.1/bin${PATH:+:${PATH}}
    export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
    if ! command -v nvcc &> /dev/null || ! nvcc --version | grep -q "release 12.1"; then
        echo "Error: nvcc 12.1 still not found or not the correct version after attempting to set PATH."
        echo "Please check your CUDA Toolkit 12.1 installation."
        exit 1
    fi
fi
echo "Current nvcc version:"
nvcc --version
check_command_success

# Add CUDA Paths to Shell Configuration for future sessions
print_header "Configuring CUDA environment variables in ~/.bashrc..."
if ! grep -Fxq 'export PATH=/usr/local/cuda-12.1/bin${PATH:+:${PATH}}' ~/.bashrc; then
    echo '' >> ~/.bashrc # Add a newline for separation
    echo '# NVIDIA CUDA Toolkit 12.1 Paths' >> ~/.bashrc
    echo 'export PATH=/usr/local/cuda-12.1/bin${PATH:+:${PATH}}' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
    echo "CUDA paths added to ~/.bashrc. Please source it or open a new terminal after this script finishes."
else
    echo "CUDA paths already seem to be in ~/.bashrc."
fi


# 4. Clone the rPPG-Toolbox repository
print_header "Cloning rPPG-Toolbox repository..."
mkdir -p "$INSTALL_DIR"
check_command_success
cd "$INSTALL_DIR"
check_command_success
if [ -d "$RPPG_TOOLBOX_DIR_NAME" ]; then
    echo "Directory $RPPG_TOOLBOX_DIR_NAME already exists. Removing existing directory for a clean clone..."
    sudo rm -rf "$RPPG_TOOLBOX_DIR_NAME" # Ensure clean state if re-running
    check_command_success
fi
git clone "$RPPG_TOOLBOX_REPO_URL" "$RPPG_TOOLBOX_DIR_NAME"
check_command_success
cd "$RPPG_TOOLBOX_DIR_NAME"
check_command_success
echo "Cloned rPPG-Toolbox to $(pwd)."

# Set ownership and permissions for the cloned repository
# This ensures the user running the script owns the cloned content.
print_header "Setting ownership and permissions for cloned repository..."
sudo chown -R "$YOUR_USERNAME:$YOUR_USERNAME" . # Use . for current directory (which is the RPPG_TOOLBOX_DIR_NAME)
check_command_success
chmod -R 700 . # Use . for current directory
check_command_success
echo "Ownership and permissions set for $(pwd)."


# # 5. Create requirements.txt with specified known-good versions
# print_header "Creating requirements.txt with specified versions..."
# REQUIREMENTS_FILE="requirements.txt" # In the root of the cloned rPPG-Toolbox repo

# cat > "$REQUIREMENTS_FILE" << 'EOF_REQUIREMENTS'
# h5py==2.10.0
# yacs==0.1.8
# scipy==1.5.4
# pandas==1.1.5
# scikit-image==0.17.2
# numpy==1.22.0
# matplotlib==3.1.2
# opencv_python==4.5.2.54
# PyYAML==6.0
# scikit_learn==1.0.2
# tensorboardX==2.4.1
# tqdm==4.64.0
# mat73==0.59
# ipykernel==6.26.0
# ipywidgets==8.1.1
# fsspec==2024.10.0
# timm==1.0.11
# causal-conv1d==1.0.0
# protobuf==3.20.3
# neurokit2==0.2.10
# thop==0.1.1.post2209072238
# EOF_REQUIREMENTS
# check_command_success
# echo "$REQUIREMENTS_FILE created/overwritten successfully."

# Modify tools/mamba/setup.py
MAMBA_SETUP_FILE="tools/mamba/setup.py"
if [ -f "$MAMBA_SETUP_FILE" ]; then
    echo "Modifying $MAMBA_SETUP_FILE..."
    # Change "transformers", to "transformers==4.25.1",
    # This sed command looks for "transformers", with or without version specifiers and replaces it.
    sed -i.bak -E "s/(\"transformers\")(,[[:space:]]*#[^\n]*)?/\1==4.25.1\2/" "$MAMBA_SETUP_FILE"
    sed -i.bak -E "s/(\"transformers==)[^\",]+(\",)/\14.25.1\2/" "$MAMBA_SETUP_FILE" # If it was already pinned differently
    
    # Verify the change (optional check)
    if grep -q "\"transformers==4.25.1\"," "$MAMBA_SETUP_FILE"; then
        echo "$MAMBA_SETUP_FILE modified successfully for transformers."
    else
        echo "Warning: Failed to modify transformers version in $MAMBA_SETUP_FILE to '==4.25.1'. Manual check needed."
        echo "Please ensure the install_requires list in $MAMBA_SETUP_FILE has 'transformers==4.25.1',"
    fi
else
    echo "Error: $MAMBA_SETUP_FILE not found. Cannot apply modifications."
    exit 1
fi

# 6. Create the inner setup.sh script (based on the working version from our report)
print_header "Creating the inner setup.sh script for rPPG-Toolbox..."
INNER_SETUP_SCRIPT="setup.sh" # This will be created in the rPPG-Toolbox root

cat > "$INNER_SETUP_SCRIPT" << 'INNER_EOF_SETUP_SH'
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
    uv pip install "Cython==0.29.37" pkgconfig || exit 1 
    # And ensure numpy==1.22.0 is first in requirements.txt or installed before things that need it for build.
    # For now, let's keep the original numpy~=1.21.6 here, uv will resolve with requirements.txt's numpy==1.22.0.

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
INNER_EOF_SETUP_SH
check_command_success
chmod +x "$INNER_SETUP_SCRIPT"
check_command_success
echo "Inner setup.sh script created in $(pwd)/$INNER_SETUP_SCRIPT."

# 7. Run the inner setup.sh script with the 'uv' option
print_header "Running the rPPG-Toolbox setup.sh script with 'uv' option..."
bash "$INNER_SETUP_SCRIPT" uv
check_command_success

print_header "rPPG-Toolbox Full Setup Script Completed Successfully!"
echo "To activate the environment in a new terminal, navigate to $INSTALL_DIR/$RPPG_TOOLBOX_DIR_NAME and run: source .venv/bin/activate"
echo "Remember to also source your ~/.bashrc (or open a new terminal) if CUDA paths were added for the first time by this script."

exit 0
