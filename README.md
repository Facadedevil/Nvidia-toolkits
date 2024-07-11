Certainly! Here's a single `README.md` file that combines all the elements discussed:

```markdown
# CUDA and cuDNN Installation Script

Welcome to the CUDA and cuDNN Installation Script repository! This script automates the setup of CUDA (Compute Unified Device Architecture) and cuDNN (CUDA Deep Neural Network Library) on Ubuntu systems, making GPU acceleration for deep learning and computational tasks easier.

## Features

- **Interactive Setup:** Customize CUDA and cuDNN versions directly from the script to match your project requirements.
- **Error Handling:** Robust error handling ensures smooth installation and provides detailed logs for troubleshooting.
- **Environment Configuration:** Automatically updates `~/.bashrc` with CUDA and cuDNN paths for seamless integration.
- **Compatibility:** Verified compatibility with Ubuntu 20.04 and 22.04 LTS, ensuring reliable performance.

## Getting Started

### Prerequisites

- Ubuntu 20.04 or 22.04 LTS (other versions may work but are not fully tested)
- Administrative privileges (`sudo` access) to install packages and modify system settings
- Internet connection for downloading necessary files

### Installation Steps

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/Facadedevil/Nvidia-toolkits.git
   cd Nvidia-toolkit
   ```

2. **Customize Installation (Optional):**

   Edit `install_cuda_cudnn.sh` to specify CUDA and cuDNN versions:

   ```bash
   CUDA_VERSION="12.5"         # Set your desired CUDA version
   CUDNN_VERSION="8.9.7"       # Set your desired cuDNN version compatible with CUDA
   ```

3. **Run the Installation Script:**

   Execute the script and follow the prompts:

   ```bash
   ./install_cuda_cudnn.sh
   ```

   The script will handle the rest, downloading necessary files and guiding you through installation.

4. **Verify Installation:**

   After installation, verify CUDA and cuDNN setup:

   ```bash
   nvcc --version   # Check CUDA compiler version
   cat /usr/local/cuda/version.txt   # Check CUDA version details
   ```

## Troubleshooting

- **Log Files:** Check `wget.log`, `dpkg.log`, and `apt.log` for detailed installation logs in case of errors.
- **Compatibility:** Ensure your GPU model supports the selected CUDA version. Refer to NVIDIA's official documentation for compatibility details.

## Contributing

Contributions are welcome! Fork the repository, make your changes, and submit a pull request. Please follow our [Contribution Guidelines](CONTRIBUTING.md) for best practices.

## License

This project is licensed under the MIT License.

## Acknowledgements

Thank you to NVIDIA for providing CUDA and cuDNN, enabling accelerated AI and scientific research computing.

## 🚀 Happy computing with CUDA and cuDNN! If you encounter any issues or have suggestions, please [open an issue](https://github.com/Facadedevil/Nvidia-toolkits/issues).
