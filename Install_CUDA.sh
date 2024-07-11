#!/bin/bash

################################################### CONFIGURATION #####################################################

CUDA_VERSION="12.5"         # Default CUDA version
CUDNN_VERSION="8.9.7"       # Default cuDNN version
CUDNN_USE_LINUX=false       # Install cuDNN from Linux .tar.xz file
CUDNN_INSTALL_SAMPLE=false  # Install cuDNN samples

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
    wget -O $cuda_filename "https://developer.download.nvidia.com/compute/cuda/$cuda_version/local_installers/$cuda_filename" || exit 1

    echo "Downloading CUDA pin file: $cuda_pin_filename"
    wget -O $cuda_pin_filename "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${Ubuntu}/x86_64/$cuda_pin_filename" || exit 1

    echo "Installing CUDA from package..."
    sudo mv $cuda_pin_filename /etc/apt/preferences.d/cuda-repository-pin-600
    sudo dpkg -i $cuda_filename || exit 1

    if [[ $cuda_major_version -le 11 ]] && [[ $cuda_minor_version -le 6 ]]; then
        sudo apt-key add /var/cuda-repo-ubuntu${Ubuntu}-${cuda_major_version}-${cuda_minor_version}-local/*.pub
    else
        sudo cp /var/cuda-repo-ubuntu${Ubuntu}-${cuda_major_version}-${cuda_minor_version}-local/cuda-*-keyring.gpg /usr/share/keyrings/
    fi

    sudo apt-get update
    sudo apt-get install -y cuda || exit 1

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
    wget -O $cudnn_filename "https://developer.download.nvidia.com/compute/machine-learning/cudnn/secure/v${cudnn_version}/prod/${cudnn_filename}" || exit 1

    if [ ${CUDNN_USE_LINUX} = true ]; then
        tar -xvf $cudnn_filename || exit 1
        sudo cp -P $cudnn_filename_no_ext/include/cudnn*.h /usr/local/cuda/include || exit 1
        sudo cp -P $cudnn_filename_no_ext/lib64/libcudnn* /usr/local/cuda/lib64/ || exit 1
        sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn* || exit 1
    else
        sudo dpkg -i $cudnn_filename || exit 1
        sudo apt-get update
        sudo apt-get install -y $cudnn_filename_no_ext || exit 1
    fi

    if [ ${CUDNN_INSTALL_SAMPLE} = true ]; then
        echo "Downloading cuDNN sample file: cudnn_samples_v8.tar.xz"
        wget -O cudnn_samples_v8.tar.xz "https://developer.download.nvidia.com/compute/machine-learning/cudnn/secure/v${cudnn_version}/prod/cudnn_samples_v8.tar.xz" || exit 1

        tar -xvf cudnn_samples_v8.tar.xz || exit 1
        cd cudnn_samples_v8/mnistCUDNN
        make clean && make || exit 1

        # Set environment variable
        SAMPLE_ENV_PATH="export CUDNN_PATH=\$(pwd)"
        if ! grep -q "$SAMPLE_ENV_PATH" $BASHRC_FILE; then
            echo "$SAMPLE_ENV_PATH" >> $BASHRC_FILE
        fi
        source $BASHRC_FILE
    fi
}

function uninstall_cuda() {
    echo "Uninstalling CUDA..."
    sudo apt-get purge -y cuda* || exit 1
    sudo apt-get autoremove -y || exit 1
    sudo apt-get autoclean || exit 1
    sudo rm -rf /usr/local/cuda* || exit 1
}

function uninstall_cudnn() {
    echo "Uninstalling cuDNN..."
    sudo apt-get purge -y libcudnn* || exit 1
    sudo apt-get autoremove -y || exit 1
    sudo apt-get autoclean || exit 1
    sudo rm -rf /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn* || exit 1
}

function validate_cuda_installation() {
    echo "Validating CUDA installation..."
    nvcc --version || (echo "CUDA installation validation failed." && exit 1)
}

function validate_cudnn_installation() {
    echo "Validating cuDNN installation..."
    cat /usr/local/cuda/include/cudnn_version.h | grep CUDNN_MAJOR -A 2 || (echo "cuDNN installation validation failed." && exit 1)
}

################################################### MAIN SCRIPT #####################################################

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Read arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --cuda-version)
            CUDA_VERSION="$2"
            shift
            shift
            ;;
        --cudnn-version)
            CUDNN_VERSION="$2"
            shift
            shift
            ;;
        --install-cuda)
            INSTALL_CUDA=true
            shift
            ;;
        --uninstall-cuda)
            UNINSTALL_CUDA=true
            shift
            ;;
        --install-cudnn)
            INSTALL_CUDNN=true
            shift
            ;;
        --uninstall-cudnn)
            UNINSTALL_CUDNN=true
            shift
            ;;
        --cudnn-linux)
            CUDNN_USE_LINUX=true
            shift
            ;;
        --cudnn-sample)
            CUDNN_INSTALL_SAMPLE=true
            shift
            ;;
        --help)
            print_information
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ ${UNINSTALL_CUDA} = true ]]; then
    uninstall_cuda
fi

if [[ ${INSTALL_CUDA} = true ]]; then
    install_cuda "$CUDA_VERSION"
fi

if [[ ${UNINSTALL_CUDNN} = true ]]; then
    uninstall_cudnn
fi

if [[ ${INSTALL_CUDNN} = true ]]; then
    install_cudnn "$CUDNN_VERSION" "$CUDA_VERSION"
fi

validate_cuda_installation
validate_cudnn_installation

echo "CUDA and cuDNN installation script completed successfully."
