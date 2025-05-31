#!/bin/bash

# Full Setup Script for rPPG-Toolbox on WSL2 Ubuntu 22.04 LTS
# Assumes it's run with sudo privileges or the user can sudo when prompted.
# Assumes NVIDIA host drivers are already installed on Windows.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
RPPG_TOOLBOX_REPO_URL="https://github.com/ubicomplab/rPPG-Toolbox.git" # Or your fork
RPPG_TOOLBOX_DIR_NAME="rPPG-Toolbox"
INSTALL_DIR="$HOME/GitHub" # Directory where the repo will be cloned

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
    echo "Directory $RPPG_TOOLBOX_DIR_NAME already exists. Skipping clone."
else
    git clone "$RPPG_TOOLBOX_REPO_URL" "$RPPG_TOOLBOX_DIR_NAME"
    check_command_success
fi
cd "$RPPG_TOOLBOX_DIR_NAME"
check_command_success
echo "Cloned rPPG-Toolbox to $(pwd)."

# 5. Modify project files
print_header "Modifying project files (requirements.txt and tools/mamba/setup.py)..."

# Modify requirements.txt
REQUIREMENTS_FILE="requirements.txt"
if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "Modifying $REQUIREMENTS_FILE..."
    # Ensure numpy is pinned to a compatible older version (uv pip install in setup.sh will handle exact version)
    # Comment out any existing numpy line
    sed -i.bak '/^numpy[[:space:]]*[<=>~]\{0,2\}[0-9]/s/^/# NPY_COMMENTED /' "$REQUIREMENTS_FILE" 
    # Add our preferred numpy if a line for numpy (even commented) isn't already there or if our specific pin is missing
    if ! grep -q -E "^(# NPY_COMMENTED )?numpy~=1\.21\.6" "$REQUIREMENTS_FILE"; then
        echo "numpy~=1.21.6" >> "$REQUIREMENTS_FILE" 
    fi

    # Change scipy version from 1.5.2 to 1.5.4
    sed -i.bak 's/^scipy==1\.5\.2/scipy==1.5.4/' "$REQUIREMENTS_FILE"
    # If scipy is not pinned as 1.5.2 or 1.5.4, add/ensure 1.5.4.
    if ! grep -q "^scipy==1\.5\.4" "$REQUIREMENTS_FILE" && ! grep -q "^scipy==1\.5\.2" "$REQUIREMENTS_FILE" && ! grep -q "^scipy[<=>~]" "$REQUIREMENTS_FILE"; then
        echo "scipy==1.5.4" >> "$REQUIREMENTS_FILE"
    elif ! grep -q "^scipy==1\.5\.4" "$REQUIREMENTS_FILE" && grep -q "^scipy==1\.5\.2" "$REQUIREMENTS_FILE"; then
        echo "Changed scipy from 1.5.2 to 1.5.4" # Already done by sed
    elif ! grep -q "^scipy==1\.5\.4" "$REQUIREMENTS_FILE"; then
         echo "Warning: scipy version in requirements.txt is not 1.5.2 or 1.5.4 after attempted modification. Manual check might be needed."
    fi
    # Ensure scikit-image==0.17.2 and h5py==2.10.0 are present if not already there
    # (This part is more complex with sed to check and add if missing without duplication)
    # For simplicity, we'll assume these are in the original requirements.txt or the user will ensure they are.
    # The uv pip install commands in the inner setup.sh will handle specific versions of build tools like Cython.
    echo "$REQUIREMENTS_FILE modifications attempted."
else
    echo "Error: $REQUIREMENTS_FILE not found in $(pwd). Cannot apply modifications."
    exit 1
fi

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
    uv pip install "Cython==0.29.37" "numpy~=1.21.6" pkgconfig || exit 1 

    echo "Installing PyTorch with CUDA 12.1 support..."
    uv pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121 --index-url https://download.pytorch.org/whl/cu121 || exit 1
    
    echo "Installing packages from requirements.txt..."
    # Ensure requirements.txt has compatible scipy, scikit-image, h5py versions for the numpy installed.
    uv pip install -r requirements.txt --no-build-isolation || exit 1
    
    echo "Pre-installing tokenizers==0.13.3 (known compatible version for mamba_ssm's older transformers)..."
    uv pip install "tokenizers==0.13.3" || exit 1

    echo "Ensuring clang is installed (as per rPPG-Toolbox README suggestion for mamba)..."
    if ! command -v clang &> /dev/null || ! command -v clang++ &> /dev/null; then
        echo "clang or clang++ not found, attempting to install clang..."
        # This script (inner) should not run sudo. Outer script should have installed it.
        # If running this part independently, user needs to ensure clang is present.
        # For now, we assume the outer script handled clang installation.
        if ! command -v gcc-11 &> /dev/null; then # Fallback check if clang is strictly needed and not found
             echo "Warning: clang/clang++ not found. Will rely on CC/CXX environment variables for gcc-11."
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