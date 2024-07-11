#!/bin/bash

################################################### CONFIGURATION #####################################################

CUDA_VERSION="12.5"         # Default CUDA version
CUDNN_VERSION="8.9.7"       # Default cuDNN version
CUDNN_USE_LINUX=false       # Install cuDNN from Linux .tar.xz file
CUDNN_INSTALL_SAMPLE=false  # Install cuDNN samples
REMOVE_MSG="reinstall (remove)"
DRIVER_REMOVE=false
CUDA_REMOVE=false
CUDNN_REMOVE=false

################################################### CUDA INFORMATION ##################################################
CUDA_INFO="|      12.5      |      O      |      O      |      -      |       535.86.05       |
|      12.4.1    |      O      |      O      |      O      |       535.54.03       |
|      12.3.2    |      O      |      O      |      O      |       530.41.03       |
|      12.2.2    |      O      |      O      |      O      |       535.54.03       |
|      12.1.1    |      O      |      O      |      O      |       525.85.12       |
|      12.0.1    |      O      |      O      |      O      |       515.105.01      |
|      11.8      |      O      |      O      |      O      |       520.61.05       |
|      11.7.1    |      O      |      O      |      O      |       515.65.01       |
|      11.6.2    |      -      |      O      |      O      |       510.47.03       |
|      11.5.2    |      -      |      O      |      O      |       495.29.05       |
|      11.4.4    |      -      |      O      |      O      |       470.82.01       |"

###################################### CUDNN INFORMATION #####################################
CUDNN_INFO="|       8.9.7       |       12.x      |       O      |       O      |       O      |       246       |
|       8.9.6       |       12.x      |       O      |       O      |       -      |       218       |
|       8.6.0       |       11.x      |       O      |       O      |       O      |       163       |
|       8.5.0       |       11.x      |       O      |       O      |       O      |       96        |
|       8.4.1       |       11.x      |       -      |       O      |       O      |       50        |
|       8.3.3       |       11.x      |       -      |       O      |       O      |       40        |
|       8.3.2       |       11.x      |       -      |       O      |       O      |       44        |
|       8.3.1       |       11.x      |       -      |       O      |       O      |       22        |"

################################################### FUNCTIONS #####################################################

function print_information() {
    echo -e "\n################################# CUDA VERSION ################################"
    echo -e "| CUDA VERSION | Ubuntu 22.04 | Ubuntu 20.04 | Ubuntu 18.04 |   DRIVER VERSION  |"
    echo -e "${CUDA_INFO}"
    echo -e "################################# CUDA VERSION ################################\n"
    echo -e "###################################### CUDNN VERSION #####################################"
    echo -e "| CUDNN VERSION | CUDA VERSION | Ubuntu 22.04 | Ubuntu 20.04 | Ubuntu 18.04 | VERSION LEVEL |"
    echo -e "${CUDNN_INFO}"
    echo -e "###################################### CUDNN VERSION #####################################\n"
}

function get_supported_cuda_versions() {
    local supported_versions=()
    local out=$(echo "${CUDA_INFO}" | tr "|" "\n")
    while read -r cuda_version support_2204 support_2004 support_1804 driver_version; do
        if [[ $support_2204 == "O" || $support_2004 == "O" ]]; then  # Only Ubuntu 22.04 and 20.04 are officially supported 
            supported_versions+=("$cuda_version")
        fi
    done <<< "$out"
    echo "${supported_versions[@]}"
}

function get_supported_cudnn_versions() {
    local supported_versions=()
    local out=$(echo "${CUDNN_INFO}" | tr "|" "\n")
    while read -r cudnn_version cuda_version support_2204 support_2004 support_1804 cudnn_level; do
        if [[ $support_2204 == "O" || $support_2004 == "O" ]]; then  
            supported_versions+=("$cudnn_version")
        fi
    done <<< "$out"
    echo "${supported_versions[@]}"
}

function install_cuda() {
    local cuda_version="$1"
    local driver_version=$(echo "${CUDA_INFO}" | grep "|${cuda_version}|" | awk -F '|' '{print $6}' | xargs)
    local cuda_major_version=$(echo "$cuda_version" | cut -d . -f 1)
    local cuda_minor_version=$(echo "$cuda_version" | cut -d . -f 2)
    local cuda_filename="cuda-repo-ubuntu${Ubuntu}-${cuda_major_version}-${cuda_minor_version}-local_${cuda_version}-${driver_version}-1_amd64.deb"
    local cuda_pin_filename="cuda-ubuntu${Ubuntu}.pin"

    echo "Installing CUDA $cuda_version..."
    echo "Downloading CUDA installation file: $cuda_filename"
    wget -O $cuda_filename "https://developer.download.nvidia.com/compute/cuda/$cuda_version/local_installers/$cuda_filename" || { echo "Failed to download CUDA installer."; exit 1; }

    echo "Downloading CUDA pin file: $cuda_pin_filename"
    wget -O $cuda_pin_filename "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${Ubuntu}/x86_64/$cuda_pin_filename" || { echo "Failed to download CUDA pin file."; exit 1; }

    echo "Installing CUDA from package..."
    sudo mv $cuda_pin_filename /etc/apt/preferences.d/cuda-repository-pin-600 || { echo "Failed to move CUDA pin file."; exit 1; }
    sudo dpkg -i $cuda_filename || { echo "Failed to install CUDA package."; exit 1; }

    if [[ $cuda_major_version -le 11 ]] && [[ $cuda_minor_version -le 6 ]]; then
        sudo apt-key add /var/cuda-repo-ubuntu${Ubuntu}-${cuda_major_version}-${cuda_minor_version}-local/*.pub || { echo "Failed to add CUDA apt-key."; exit 1; }
    else
        sudo cp /var/cuda-repo-ubuntu${Ubuntu}-${cuda_major_version}-${cuda_minor_version}-local/cuda-*-keyring.gpg /usr/share/keyrings/ || { echo "Failed to copy CUDA keyring."; exit 1; }
    fi

    sudo apt-get update || { echo "Failed to update apt repositories."; exit 1; }
    sudo apt-get install -y cuda || { echo "Failed to install CUDA."; exit 1; }

    # Set environment variables
    CUDA_ENV_PATH="export PATH=/usr/local/cuda-${cuda_major_version}.${cuda_minor_version}/bin:\$PATH"
    CUDA_ENV_LIB_PATH="export LD_LIBRARY_PATH=/usr/local/cuda-${cuda_major_version}.${cuda_minor_version}/lib64:\$LD_LIBRARY_PATH"

    BASHRC_FILE=~/.bashrc
    if ! grep -q "$CUDA_ENV_PATH" $BASHRC_FILE; then
        echo "$CUDA_ENV_PATH" >> $BASHRC_FILE
    fi
    if ! grep -q "$CUDA_ENV_LIB_PATH" $BASHRC_FILE; then
        echo "$CUDA_ENV_LIB_PATH" >> $BASHRC_FILE
    fi

    source $BASHRC_FILE
}

function install_cudnn() {
    local cudnn_version="$1"
    local cudnn_cuda_version="$2"
    local cudnn_level="3"
    local cudnn_lib_name="${cudnn_version}.${cudnn_level}-1+cuda${cudnn_cuda_version}"
    local cudnn_filename=""
    local cudnn_filename_no_ext=""

    if [ ${CUDNN_USE_LINUX} = true ]; then
        cudnn_filename="cudnn-linux-x64-${cudnn_version}.tar.xz"
        cudnn_filename_no_ext="cudnn-linux-x64-${cudnn_version}"
    else
        cudnn_filename="libcudnn${cudnn_level}_${cudnn_version}-1+cuda${cudnn_cuda_version}_amd64.deb"
        cudnn_filename_no_ext="libcudnn${cudnn_level}_${cudnn_version}-1+cuda${cudnn_cuda_version}"
    fi

    echo "Installing cuDNN $cudnn_version..."
    echo "Downloading cuDNN installation file: $cudnn_filename"
    wget -O $cudnn_filename "https://developer.download.nvidia.com/compute/cudnn/secure/$cudnn_version/Production/${cudnn_filename}" || { echo "Failed to download cuDNN installer."; exit 1; }

    if [ ${CUDNN_USE_LINUX} = true ]; then
        echo "Installing cuDNN from tar file..."
        tar -xf $cudnn_filename || { echo "Failed to extract cuDNN tar file."; exit 1; }
        sudo cp -P $cudnn_filename_no_ext/include/cudnn*.h /usr/local/cuda/include || { echo "Failed to copy cuDNN header files."; exit 1; }
        sudo cp -P $cudnn_filename_no_ext/lib/libcudnn* /usr/local/cuda/lib64 || { echo "Failed to copy cuDNN library files."; exit 1; }
        sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn* || { echo "Failed to set permissions for cuDNN files."; exit 1; }
    else
        echo "Installing cuDNN from Debian package..."
        sudo dpkg -i $cudnn_filename || { echo "Failed to install cuDNN package."; exit 1; }
    fi
}

function uninstall_cuda() {
    echo "Uninstalling existing CUDA installation..."
    sudo apt-get --purge remove "*cublas*" "*cufft*" "*curand*" "*cusolver*" "*cusparse*" "*npp*" "*nvjpeg*" "cuda*" "nsight*" -y || { echo "Failed to remove CUDA packages."; exit 1; }
    sudo apt-get --purge remove "*nvidia*" -y || { echo "Failed to remove NVIDIA packages."; exit 1; }
    sudo apt-get autoremove -y || { echo "Failed to autoremove packages."; exit 1; }
    sudo apt-get clean || { echo "Failed to clean up packages."; exit 1; }
    sudo rm -rf /usr/local/cuda* || { echo "Failed to remove CUDA directories."; exit 1; }
}

function uninstall_cudnn() {
    echo "Uninstalling existing cuDNN installation..."
    sudo dpkg -r libcudnn8 libcudnn8-dev libcudnn8-samples || { echo "Failed to remove cuDNN packages."; exit 1; }
    sudo dpkg -P libcudnn8 libcudnn8-dev libcudnn8-samples || { echo "Failed to purge cuDNN packages."; exit 1; }
    sudo apt-get autoremove -y || { echo "Failed to autoremove packages."; exit 1; }
    sudo apt-get clean || { echo "Failed to clean up packages."; exit 1; }
    sudo rm -rf /usr/local/cuda*/lib64/libcudnn* || { echo "Failed to remove cuDNN libraries."; exit 1; }
    sudo rm -rf /usr/local/cuda*/include/cudnn*.h || { echo "Failed to remove cuDNN header files."; exit 1; }
}

function select_cuda_version() {
    supported_cuda_versions=($(get_supported_cuda_versions))
    if [ ${#supported_cuda_versions[@]} -eq 0 ]; then
        echo "No supported CUDA versions found."
        exit 1
    fi

    echo "Available CUDA versions: ${supported_cuda_versions[*]}"
    read -rp "Enter CUDA version (default: ${CUDA_VERSION}): " input
    if [ -n "$input" ]; then
        CUDA_VERSION="$input"
    fi
}

function select_cudnn_version() {
    supported_cudnn_versions=($(get_supported_cudnn_versions))
    if [ ${#supported_cudnn_versions[@]} -eq 0 ]; then
        echo "No supported cuDNN versions found."
        exit 1
    fi

    echo "Available cuDNN versions: ${supported_cudnn_versions[*]}"
    read -rp "Enter cuDNN version (default: ${CUDNN_VERSION}): " input
    if [ -n "$input" ]; then
        CUDNN_VERSION="$input"
    fi
}

function ask_to_remove_existing_installations() {
    read -rp "Do you want to remove existing CUDA installation? (y/N): " cuda_remove
    if [[ "$cuda_remove" =~ ^[Yy]$ ]]; then
        CUDA_REMOVE=true
    fi

    read -rp "Do you want to remove existing cuDNN installation? (y/N): " cudnn_remove
    if [[ "$cudnn_remove" =~ ^[Yy]$ ]]; then
        CUDNN_REMOVE=true
    fi
}

################################################### MAIN PROGRAM #####################################################

print_information

ask_to_remove_existing_installations

if [ ${CUDA_REMOVE} = true ]; then
    uninstall_cuda
fi

if [ ${CUDNN_REMOVE} = true ]; then
    uninstall_cudnn
fi

select_cuda_version
install_cuda "$CUDA_VERSION"

select_cudnn_version
install_cudnn "$CUDNN_VERSION" "$CUDA_VERSION"

echo "CUDA and cuDNN installation completed successfully."
