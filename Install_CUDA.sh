#!/bin/bash
set -e  # Exit immediately on error

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
    wget -O $cuda_filename "https://developer.download.nvidia.com/compute/cuda/$cuda_version/local_installers/$cuda_filename" > wget.log 2>&1
    check_command_success

    echo "Downloading CUDA pin file: $cuda_pin_filename"
    wget -O $cuda_pin_filename "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${Ubuntu}/x86_64/$cuda_pin_filename" > wget.log 2>&1
    check_command_success

    echo "Installing CUDA from package..."
    sudo dpkg -i $cuda_filename > dpkg.log 2>&1
    check_command_success

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

        echo "Installing cuDNN $cudnn_version..."
        echo "Downloading cuDNN installation file: $cudnn_filename"
        wget -O $cudnn_filename "https://developer.download.nvidia.com/compute/machine-learning/cudnn/${cudnn_level}/${cudnn_filename}" > wget.log 2>&1
        check_command_success

        tar -xf $cudnn_filename > tar.log 2>&1
        check_command_success

        sudo cp -P $cudnn_filename_no_ext/include/cudnn*.h /usr/local/cuda/include > cp.log 2>&1
        check_command_success

        sudo cp -P $cudnn_filename_no_ext/lib64/libcudnn* /usr/local/cuda/lib64 > cp.log 2>&1
        check_command_success

        sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn* > chmod.log 2>&1
        check_command_success

    else
        cudnn_filename="libcudnn${cudnn_level}_${cudnn_version}-1+cuda${cudnn_cuda_version}_amd64.deb"
        cudnn_filename_no_ext="libcudnn${cudnn_level}_${cudnn_version}-1+cuda${cudnn_cuda_version}"

        echo "Installing cuDNN $cudnn_version..."
        echo "Downloading cuDNN installation file: $cudnn_filename"
        wget -O $cudnn_filename "https://developer.download.nvidia.com/compute/machine-learning/cudnn/${cudnn_level}/${cudnn_filename}" > wget.log 2>&1
        check_command_success

        sudo dpkg -i $cudnn_filename > dpkg.log 2>&1
        check_command_success

    fi

    if [ ${CUDNN_INSTALL_SAMPLE} = true ]; then
        echo "Installing cuDNN samples..."
        sudo apt-get install -y libcudnn${cudnn_level}-samples > apt.log 2>&1
        check_command_success
    fi
}

function check_command_success() {
    if [ $? -ne 0 ]; then
        echo "Error: Command failed. Check logs for details."
        exit 1
    fi
}

function uninstall_cuda() {
    echo "Uninstalling existing CUDA installation..."
    sudo apt-get --purge remove "*cublas*" "*cufft*" "*curand*" "*cusolver*" "*cusparse*" "*npp*" "*nvjpeg*" "cuda*" "nsight*" -y > apt.log 2>&1
    check_command_success

    if [[ $DRIVER_REMOVE == true ]]; then
        sudo apt-get --purge remove "*nvidia*" -y > apt.log 2>&1
        check_command_success
    fi

    sudo apt-get autoremove -y > apt.log 2>&1
    check_command_success

    sudo apt-get clean > apt.log 2>&1
    check_command_success

    sudo rm -rf /usr/local/cuda* > apt.log 2>&1
    check_command_success
}

################################################### MAIN SCRIPT #####################################################

function main() {
    print_information

    # Check if CUDA is already installed
    if [[ -n "$(which nvcc)" ]]; then
        echo "CUDA is already installed. Do you want to reinstall?"
        read -rp "If so, existing installation will be removed. (y/N): " reinstall
        if [[ "$reinstall" =~ ^[Yy]$ ]]; then
            uninstall_cuda
        fi
    fi

    # Install CUDA and cuDNN
    install_cuda $CUDA_VERSION
    install_cudnn $CUDNN_VERSION $CUDA_VERSION

    echo "Installation completed successfully!"
}

main
