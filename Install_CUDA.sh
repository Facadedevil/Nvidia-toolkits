#==========================================================================================================================
################################################### SETTING CUDA VERSION ##################################################

CUDA_VERSION="11.7.1"

CUDNN_VERSION="8.5.0"
CUDNN_USE_LINUX=false
CUDNN_INSTALL_SAMPLE=false

################################################### SETTING CUDA VERSION ##################################################

CUDA_INFO="|    11.8.0    |      O      |      O      |      O      |      520.61.05     |
|    11.7.1    |      O      |      O      |      O      |      515.65.01     |
|    11.7.0    |      O      |      O      |      O      |      515.43.04     |
|    11.6.2    |      X      |      O      |      O      |      510.47.03     |
|    11.6.1    |      X      |      O      |      O      |      510.47.03     |
|    11.6.0    |      X      |      O      |      O      |      510.39.01     |
|    11.5.2    |      X      |      O      |      O      |      495.29.05     |
|    11.5.1    |      X      |      O      |      O      |      495.29.05     |
|    11.5.0    |      X      |      O      |      O      |      495.29.05     |
|    11.4.4    |      X      |      O      |      O      |      470.82.01     |
|    11.4.3    |      X      |      O      |      O      |      470.82.01     |
|    11.4.2    |      X      |      O      |      O      |      470.57.02     |
|    11.4.1    |      X      |      O      |      O      |      470.57.02     |
|    11.4.0    |      X      |      O      |      O      |      470.42.01     |
|    11.3.1    |      X      |      O      |      O      |      465.19.01     |
|    11.3.0    |      X      |      O      |      O      |      465.19.01     |
|    11.2.2    |      X      |      O      |      O      |      460.32.03     |
|    11.2.1    |      X      |      O      |      O      |      460.32.03     |
|    11.2.0    |      X      |      O      |      O      |      460.27.04     |
|    11.1.1    |      X      |      O      |      O      |      455.32.00     |
|    11.1.0    |      X      |      O      |      O      |      455.23.05     |
|    11.0.3    |      X      |      O      |      O      |      450.51.06     |
|    11.0.2    |      X      |      O      |      O      |      450.51.05     |
|    11.0.1    |      X      |      X      |      O      |      450.36.06     |"

CUDNN_INFO="|     8.6.0     |     11.8     |      O      |      O      |      O      |      163      |
|     8.5.0     |     11.7     |      O      |      O      |      O      |       96      |
|     8.4.1     |     11.6     |      X      |      O      |      O      |       50      |
|     8.4.0     |     11.6     |      X      |      O      |      O      |       27      |
|     8.3.3     |     11.5     |      X      |      O      |      O      |       40      |
|     8.3.2     |     11.5     |      X      |      O      |      O      |       44      |
|     8.3.1     |     11.5     |      X      |      O      |      O      |       22      |"

INFOMATION="
################################# CUDA VERSION ################################
| CUDA VERSION | Ubuntu 2204 | Ubuntu 2004 | Ubuntu 1804 |   DRIVER VERSION   |
${CUDA_INFO}
################################# CUDA VERSION ################################

###################################### CUDNN VERSION #####################################
| CUDNN VERSION | CUDA VERSION | Ubuntu 2204 | Ubuntu 2004 | Ubuntu 1804 | VERSION LEVEL |
${CUDNN_INFO} 
###################################### CUDNN VERSION #####################################
"

######################################################## CHECK ############################################################

Ubuntu=$(cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -d = -f 2)
Ubuntu_VERSION=$(echo ${Ubuntu/./})

if [ ${Ubuntu_VERSION} != "2204" ] && [ ${Ubuntu_VERSION} != "2004" ] && [ ${Ubuntu_VERSION} != "1804" ]; then
  echo "Unsupport Ubuntu VERSION: ${Ubuntu_VERSION} Only support [ 2204 | 2004 | 1804 ]"
fi

REMOVE_CMD="--uninstall"
if [ "$1" != ${REMOVE_CMD} ]; then

  # CUDA
  out=$(echo "${CUDA_INFO}" | tr "|" "\n")
  c=0
  idx=0
  CUDA_SUPPORT_VERSION=""
  for m in $out
  do
    c=$(($c + 1))
    if [ $((${c} % 5)) -eq 1 ]; then
      arr_cuda_version[${idx}]=${m}
      if [ "${m}" = "${CUDA_VERSION}" ]; then
        CUDA_VERSION_INDEX=${idx}
      fi
    elif [ $((${c} % 5)) -eq 2 ]; then
      arr_2204[${idx}]=${m}
    elif [ $((${c} % 5)) -eq 3 ]; then
      arr_2004[${idx}]=${m}
    elif [ $((${c} % 5)) -eq 4 ]; then
      arr_1804[${idx}]=${m}
    elif [ $((${c} % 5)) -eq 0 ]; then
      if ([ ${Ubuntu_VERSION} = "2204" ] && [ ${arr_2204[$idx]} = "O" ]) || ([ ${Ubuntu_VERSION} = "2004" ] && [ ${arr_2004[$idx]} = "O" ]) || ([ ${Ubuntu_VERSION} = "1804" ] && [ ${arr_1804[$idx]} = "O" ]); then
        if [ "${CUDA_SUPPORT_VERSION}" != "" ]; then
          CUDA_SUPPORT_VERSION="${CUDA_SUPPORT_VERSION} | ${arr_cuda_version[$idx]}"
        else
          CUDA_SUPPORT_VERSION="${arr_cuda_version[$idx]}"
        fi
      fi
      arr_driver[${idx}]=${m}
      idx=$(($idx + 1))
    fi
  done

  len=${#arr_cuda_version[@]}
  echo -e "${INFOMATION}"

  CUDA_MSG="Choice CUDA VERSION [ Default ${CUDA_VERSION} ]: "
  read -p "${CUDA_MSG}" VAR
  CHECK_PASS=false
  Ubuntu_NO_MATCH=false
  while true
  do
    for ((i=0; i < len; ++i))
    do
      if [ "${VAR}" = "${arr_cuda_version[$i]}" ]; then
        if ([ ${Ubuntu_VERSION} = "2204" ] && [ ${arr_2204[$i]} = "X" ]) || ([ ${Ubuntu_VERSION} = "2004" ] && [ ${arr_2004[$i]} = "X" ]) || ([ ${Ubuntu_VERSION} = "1804" ] && [ ${arr_1804[$i]} = "X" ]); then
          Ubuntu_NO_MATCH=true
          break
        fi
        CHECK_PASS=true
        CUDA_VERSION_INDEX=${i}
        break
      fi
    done
    if [ "${VAR}" = "" ] || [ ${CHECK_PASS} = true ]; then
      break
    else
      if [ ${Ubuntu_NO_MATCH} = true ]; then
        echo "Ubuntu${Ubuntu_VERSION} not support this CUDA VERSION ${VAR}"
        Ubuntu_NO_MATCH=false
      else
        echo -e "CUDA VERSION: ${VAR} Not Found.\nSupport Version: [ ${CUDA_SUPPORT_VERSION} ]"
      fi
      read -p "${CUDA_MSG}" VAR
    fi
  done

  if [ "${VAR}" != "" ]; then
    CUDA_VERSION=${VAR}
  fi

  # CUDNN
  out=$(echo "${CUDNN_INFO}" | tr "|" "\n")
  c=0
  idx=0
  CUDNN_SUPPORT_VERSION=""
  for m in $out
  do
    c=$(($c + 1))
    if [ $((${c} % 6)) -eq 1 ]; then
      arr_cudnn_version[${idx}]=${m}
      if [ "${m}" = "${CUDNN_VERSION}" ]; then
        CUDNN_VERSION_INDEX=${idx}
      fi
    elif [ $((${c} % 6)) -eq 2 ]; then
      arr_cudnn_cuda_version[${idx}]=${m}
    elif [ $((${c} % 6)) -eq 3 ]; then
      arr_2204_cudnn[${idx}]=${m}
    elif [ $((${c} % 6)) -eq 4 ]; then
      arr_2004_cudnn[${idx}]=${m}
    elif [ $((${c} % 6)) -eq 5 ]; then
      arr_1804_cudnn[${idx}]=${m}
    elif [ $((${c} % 6)) -eq 0 ]; then
      arr_cudnn_level[${idx}]=${m}
      if ([ ${Ubuntu_VERSION} = "2204" ] && [ ${arr_2204_cudnn[$idx]} = "O" ]) || ([ ${Ubuntu_VERSION} = "2004" ] && [ ${arr_2004_cudnn[$idx]} = "O" ]) || ([ ${Ubuntu_VERSION} = "1804" ] && [ ${arr_1804_cudnn[$idx]} = "O" ]); then
        if [ "${CUDNN_SUPPORT_VERSION}" != "" ]; then
          CUDNN_SUPPORT_VERSION="${CUDNN_SUPPORT_VERSION} | ${arr_cudnn_version[$idx]}"
        else
          CUDNN_SUPPORT_VERSION="${arr_cudnn_version[$idx]}"
        fi
      fi
      idx=$(($idx + 1))
    fi
  done

  len=${#arr_cudnn_version[@]}

  CUDNN_MSG="Choice CUDNN VERSION [ Default ${CUDNN_VERSION} ]: "
  read -p "${CUDNN_MSG}" VAR
  CHECK_PASS=false
  Ubuntu_NO_MATCH=false
  while true;
  do
    for ((i=0; i < len; ++i))
    do
      if [ "${VAR}" = "${arr_cudnn_version[$i]}" ]; then
        if ([ ${Ubuntu_VERSION} = "2204" ] && [ ${arr_2204_cudnn[$i]} = "X" ]) || ([ ${Ubuntu_VERSION} = "2004" ] && [ ${arr_2004_cudnn[$i]} = "X" ]) || ([ ${Ubuntu_VERSION} = "1804" ] && [ ${arr_1804_cudnn[$i]} = "X" ]); then
          Ubuntu_NO_MATCH=true
          break
        fi
        CHECK_PASS=true
        CUDNN_VERSION_INDEX=${i}
        break
      fi
    done
    if [ "${VAR}" = "" ] || [ ${CHECK_PASS} = true ]; then
      break
    else
      if [ ${Ubuntu_NO_MATCH} = true ]; then
        echo "Ubuntu${Ubuntu_VERSION} not support this CUDNN VERSION ${VAR}"
        Ubuntu_NO_MATCH=false
      else
        echo -e "CUDNN VERSION: ${VAR} Not Found.\nSupport Version: [ ${CUDNN_SUPPORT_VERSION} ]"
      fi
      read -p "${CUDNN_MSG}" VAR
    fi
  done
  if [ "${VAR}" != "" ]; then
    CUDNN_VERSION=${VAR}
  fi
  CUDNN_PAGE_VERSION=${arr_cudnn_cuda_version[${CUDNN_VERSION_INDEX}]}
  CUDNN_VERSION_LEVEL=${arr_cudnn_level[${CUDNN_VERSION_INDEX}]}

  if [ ${CUDNN_USE_LINUX} = true ]; then
    MSG_CUDNN_USE_LINUX="Yes"
  else
    MSG_CUDNN_USE_LINUX="No"
  fi


  CUDNN_USE_LINUX_MSG="[ Default ${MSG_CUDNN_USE_LINUX} ] (y/n): "
  echo -e "Install CUDNN LINUX .tar FILE?\n( If no will install .deb FILE )"
  read -p "${CUDNN_USE_LINUX_MSG}" VAR
  while [ "${VAR}" != "" ] && [ "${VAR}" != "y" ] && [ "${VAR}" != "n" ];
  do
    echo -e "Please Input y or n"
    read -p "${CUDNN_USE_LINUX_MSG}" VAR
  done
  if [ "${VAR}" != "" ] && [ "${VAR}" = "y" ]; then
    CUDNN_USE_LINUX=true
    MSG_CUDNN_USE_LINUX="Yes"
  else
    CUDNN_USE_LINUX=false
    MSG_CUDNN_USE_LINUX="No"
  fi
  
  

  if [ ${CUDNN_USE_LINUX} = false ]; then
    if [ ${CUDNN_INSTALL_SAMPLE} = true ]; then
      MSG_CUDNN_INSTALL_SAMPLE="Yes"
    else
      MSG_CUDNN_INSTALL_SAMPLE="No"
    fi

    CUDNN_INSTALL_SAMPLE_MSG="Install CUDNN SAMPLE? [ Default ${MSG_CUDNN_INSTALL_SAMPLE} ] (y/n): "
    read -p "${CUDNN_INSTALL_SAMPLE_MSG}" VAR
    while [ "${VAR}" != "" ] && [ "${VAR}" != "y" ] && [ "${VAR}" != "n" ];
    do
      echo -e "Please Input y or n"
      read -p "${CUDNN_INSTALL_SAMPLE_MSG}" VAR
    done
    if [ "${VAR}" != "" ] && [ "${VAR}" = "y" ]; then
      CUDNN_INSTALL_SAMPLE=true
      MSG_CUDNN_INSTALL_SAMPLE="Yes"
    else
      CUDNN_INSTALL_SAMPLE=false
      MSG_CUDNN_INSTALL_SAMPLE="No"
    fi
  fi
  
  echo "============================="
  echo "CUDA_VERSION         = ${CUDA_VERSION}"
  echo "CUDNN_VERSION        = ${CUDNN_VERSION}"
  echo "CUDNN_USE_LINUX      = ${MSG_CUDNN_USE_LINUX}"
  if [ ${CUDNN_USE_LINUX} = false ]; then
    echo "CUDNN_INSTALL_SAMPLE = ${MSG_CUDNN_INSTALL_SAMPLE}"
  fi
  echo "============================="
fi

######################################################## REMOVE ###########################################################

DRIVER_REMOVE=false
CUDA_REMOVE=false
CUDNN_REMOVE=false

CUDA_INSTALL=true
CUDNN_INSTALL=true

REMOVE_MSG="reinstall"
if [ "$1" = ${REMOVE_CMD} ]; then
  REMOVE_MSG="remove"
fi

if [ ${DRIVER_REMOVE} = true ] && [ "$1" = ${REMOVE_CMD} ]; then
  MSG_REMOVE_DRIVER="Remove"
elif [ ${DRIVER_REMOVE} = true ]; then
  MSG_REMOVE_DRIVER="Reinstall"
else
  MSG_REMOVE_DRIVER="Keep"
fi

if [ $(dpkg -l | grep -c nvidia-driver) -ne 0 ]; then
  echo "======================"
  echo "Nvidia-Driver Exists! You want to keep or ${REMOVE_MSG}?"
  read -p "[ Default ${MSG_REMOVE_DRIVER} ] (k/r):" KEEP_VAR
  if [ "${KEEP_VAR}" != "" ] && [ "${KEEP_VAR}" = "r" ]; then
    DRIVER_REMOVE=true
  elif [ "${KEEP_VAR}" = "" ] || [ "${KEEP_VAR}" = "k" ]; then
    DRIVER_REMOVE=false
  fi
fi

CUDA_EXISTS=false
if [ -d "/usr/local/cuda" ] || [ $(dpkg -l | grep -c cuda) -ne 0 ] || [ $(ls /usr/share/keyrings | grep -c cuda) -ne 0 ] || [ $(ls /etc/apt/sources.list.d | grep -c cuda) -ne 0 ]; then
  echo "======================"
  echo "CUDA Exists! You want to keep or ${REMOVE_MSG}?"
  echo "If reinstall will remove CUDA and CUDNN"
  read -p "[ Default keep ] (k/r):" KEEP_VAR
  if [ "${KEEP_VAR}" != "" ] && [ "${KEEP_VAR}" = "r" ]; then
    CUDA_REMOVE=true
    CUDNN_REMOVE=true
  elif [ "${KEEP_VAR}" = "" ] || [ "${KEEP_VAR}" = "k" ]; then
    CUDA_REMOVE=false
    CUDA_INSTALL=false
  fi
  CUDA_EXISTS=true
fi

if [ ${CUDA_EXISTS} = true ] && [ ${CUDA_REMOVE} = false ] && ([ -f "/usr/local/cuda/include/cudnn_version.h" ] || [ $(dpkg -l | grep -c cudnn) -ne 0 ] || [ $(ls /usr/share/keyrings | grep -c cudnn) -ne 0 ] || [ $(ls /etc/apt/sources.list.d | grep -c cudnn) -ne 0 ] || [ $(ls /usr/src | grep -c cudnn) -ne 0 ] || [ $(sudo apt-key list | grep -c "7FA2 AF80") -ne 0 ]); then
  echo "======================"
  echo "CUDNN Exists! You want to keep or ${REMOVE_MSG}?"
  read -p "[ Default keep ] (k/r):" KEEP_VAR
  if [ "${KEEP_VAR}" != "" ] && [ "${KEEP_VAR}" = "r" ]; then
    CUDNN_REMOVE=true
  elif [ "${KEEP_VAR}" = "" ] || [ "${KEEP_VAR}" = "k" ]; then
    CUDNN_REMOVE=false
    CUDNN_INSTALL=false
  fi
fi

if [ ${CUDA_INSTALL} = false ] && [ ${CUDNN_INSTALL} = false ]; then
  exit 0
fi

TEMP_BUILD_DIR="__build__temp__"
rm -rf ${TEMP_BUILD_DIR}
mkdir ${TEMP_BUILD_DIR}
cd ${TEMP_BUILD_DIR}

# Remove Nvidia-Driver
if [ ${DRIVER_REMOVE} = true ]; then
  sudo apt remove --autoremove --purge -y *nvidia*
fi

# Remove CUDA
if [ ${CUDA_REMOVE} = true ]; then
  if [ $(dpkg -l | grep -c cuda) -ne 0 ]; then
    sudo apt remove --autoremove --purge -y cuda*
  fi
  sudo rm -rf /usr/local/cuda*
  sudo rm -f /usr/share/keyrings/cuda*
  sudo rm -f /etc/apt/sources.list.d/cuda*
fi

# Remove CUDNN
if [ ${CUDNN_REMOVE} = true ]; then
  if [ $(dpkg -l | grep -c libcudnn) -ne 0 ]; then
    sudo apt remove --autoremove --purge -y libcudnn*
  fi
  if [ $(dpkg -l | grep -c cudnn) -ne 0 ]; then
    sudo apt remove --autoremove --purge -y cudnn*
  fi
  if [ $(sudo apt-key list | grep -c "7FA2 AF80") ]; then
    sudo apt-key del "7FA2 AF80"
  fi
  sudo rm -rf /usr/src/cudnn*
  sudo rm -f /usr/local/cuda/include/cudnn*.h
  sudo rm -rf /usr/local/cuda/lib64/libcudnn*
  sudo rm -f /usr/share/keyrings/cudnn*
  sudo rm -f /etc/apt/sources.list.d/cudnn*
fi

cd ..
rm -r ${TEMP_BUILD_DIR}

sudo apt update

if [ "$1" = ${REMOVE_CMD} ]; then
  echo "Uninstall Complete."
  exit 0
fi

CUDA_VERSION_MAJOR=$(echo ${CUDA_VERSION} | cut -d . -f 1)
CUDA_VERSION_MINOR=$(echo ${CUDA_VERSION} | cut -d . -f 2)
CUDA_VERSION_PATCHLEVEL=$(echo ${CUDA_VERSION} | cut -d . -f 3)

########################################################## CUDA ###########################################################

if [ ${CUDA_INSTALL} = true ]; then
  DRIVER_VERSION=${arr_driver[${CUDA_VERSION_INDEX}]}
  echo "install driver: ${DRIVER_VERSION}"
  
  # Install CUDA
  CUDA_PIN_FILENAME="cuda-ubuntu${Ubuntu_VERSION}.pin"
  
  if [ -f ${CUDA_PIN_FILENAME} ]; then
    echo "======================"
    echo "CUDA PIN Installation File Exists: ${CUDA_PIN_FILENAME}"
    echo "======================"
  else
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${Ubuntu_VERSION}/x86_64/${CUDA_PIN_FILENAME}
  fi

  sudo mv ${CUDA_PIN_FILENAME} /etc/apt/preferences.d/cuda-repository-pin-600

  CUDA_FILENAME="cuda-repo-ubuntu${Ubuntu_VERSION}-${CUDA_VERSION_MAJOR}-${CUDA_VERSION_MINOR}-local_${CUDA_VERSION}-${DRIVER_VERSION}-1_amd64.deb"
  if [ -f ${CUDA_FILENAME} ]; then
    echo "======================"
    echo "CUDA Installation File Exists: ${CUDA_FILENAME}"
    echo "======================"
  else
    wget https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/${CUDA_FILENAME}
  fi

  sudo dpkg -i ${CUDA_FILENAME}
  if [ ${CUDA_VERSION_MAJOR} -le 11 ] && [ ${CUDA_VERSION_MINOR} -le 6 ]; then
    sudo apt-key add /var/cuda-repo-ubuntu${Ubuntu_VERSION}-${CUDA_VERSION_MAJOR}-${CUDA_VERSION_MINOR}-local/*.pub
  else
    sudo cp /var/cuda-repo-ubuntu${Ubuntu_VERSION}-${CUDA_VERSION_MAJOR}-${CUDA_VERSION_MINOR}-local/cuda-*-keyring.gpg /usr/share/keyrings/
  fi
  
  sudo apt-get update
  sudo apt-get -y install cuda

  # Add CUDA env path
  CUDA_ENV_PATH="export PATH=/usr/local/cuda-${CUDA_VERSION_MAJOR}.${CUDA_VERSION_MINOR}/bin:\$PATH"
  CUDA_ENV_LIB_PATH="export LD_LIBRARY_PATH=/usr/local/cuda-${CUDA_VERSION_MAJOR}.${CUDA_VERSION_MINOR}/lib64:\$LD_LIBRARY_PATH"

  BASHRC_FILE=~/.bashrc
  CHECK_CUDA_ENV_PATH=$(grep -c "${CUDA_ENV_PATH}" ${BASHRC_FILE})
  CHECK_CUDA_ENV_LIB_PATH=$(grep -c "${CUDA_ENV_LIB_PATH}" ${BASHRC_FILE})
  
  if [ ${CHECK_CUDA_ENV_PATH} -eq 0 ] && [ ${CHECK_CUDA_ENV_LIB_PATH} -eq 0 ]; then
    echo "# SETTING CUDA ENVIRONMENT" >> ${BASHRC_FILE}
    echo ${CUDA_ENV_PATH} >> ${BASHRC_FILE}
    echo ${CUDA_ENV_LIB_PATH} >> ${BASHRC_FILE}
  elif [ ${CHECK_CUDA_ENV_PATH} -eq 0 ]; then
    echo "# SETTING CUDA ENVIRONMENT" >> ${BASHRC_FILE}
    echo ${CUDA_ENV_PATH} >> ${BASHRC_FILE}
  elif [ ${CHECK_CUDA_ENV_LIB_PATH} -eq 0 ]; then
    echo "# SETTING CUDA ENVIRONMENT" >> ${BASHRC_FILE}
    echo ${CUDA_ENV_LIB_PATH} >> ${BASHRC_FILE}
  fi
  
  source ${BASHRC_FILE}
fi

########################################################## CUDNN ##########################################################

if [ ${CUDNN_INSTALL} = true ]; then

  CUDNN_VERSION_MAJOR=$(echo ${CUDNN_VERSION} | cut -d . -f 1)
  CUDNN_VERSION_MINOR=$(echo ${CUDNN_VERSION} | cut -d . -f 2)
  CUDNN_VERSION_PATCHLEVEL=$(echo ${CUDNN_VERSION} | cut -d . -f 3)

  if [ ${CUDNN_USE_LINUX} = true ]; then
    if [ ${CUDNN_VERSION_MAJOR} -le 8 ] && [ ${CUDNN_VERSION_MINOR} -le 4 ]; then
      CUDNN_FILENAME_NO_EXT="cudnn-linux-x86_64-${CUDNN_VERSION}.${CUDNN_VERSION_LEVEL}_cuda${CUDNN_PAGE_VERSION}-archive"
      CUDNN_FILENAME="${CUDNN_FILENAME_NO_EXT}.tar.xz"
    else
      CUDNN_FILENAME_NO_EXT="cudnn-linux-x86_64-${CUDNN_VERSION}.${CUDNN_VERSION_LEVEL}_cuda11-archive"
      CUDNN_FILENAME="${CUDNN_FILENAME_NO_EXT}.tar.xz"
    fi
  else
    CUDNN_FILENAME="cudnn-local-repo-ubuntu${Ubuntu_VERSION}-${CUDNN_VERSION}.${CUDNN_VERSION_LEVEL}_1.0-1_amd64.deb"
  fi

  CUDNN_LIB_NAME="${CUDNN_VERSION}.${CUDNN_VERSION_LEVEL}-1+cuda${CUDNN_PAGE_VERSION}"

  # Install CUDNN
  if [ -f ${CUDNN_FILENAME} ]; then
    echo "======================"
    echo "CUDNN Installation File Exists: ${CUDNN_FILENAME}"
    echo "======================"
  else
    wget https://developer.download.nvidia.com/compute/redist/cudnn/v${CUDNN_VERSION}/local_installers/${CUDNN_PAGE_VERSION}/${CUDNN_FILENAME}
  fi

  if [ ${CUDNN_USE_LINUX} = true ]; then
    tar -xvf ${CUDNN_FILENAME}
    sudo cp ${CUDNN_FILENAME_NO_EXT}/include/cudnn*.h /usr/local/cuda/include 
    sudo cp -P ${CUDNN_FILENAME_NO_EXT}/lib/libcudnn* /usr/local/cuda/lib64 
    sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*
    sudo rm -rf ${CUDNN_FILENAME_NO_EXT}
  else
    sudo dpkg -i ${CUDNN_FILENAME}
    if [ ${CUDNN_VERSION} = "8.4.0" ]; then
      sudo apt-key add /var/cudnn-local-repo-ubuntu${Ubuntu_VERSION}-${CUDNN_VERSION}.${CUDNN_VERSION_LEVEL}/*.pub
    else
      sudo cp /var/cudnn-local-repo-*/cudnn-local-*-keyring.gpg /usr/share/keyrings/
    fi
    sudo apt-get update
    sudo apt-get -y install libcudnn8=${CUDNN_LIB_NAME}
    sudo apt-get -y install libcudnn8-dev=${CUDNN_LIB_NAME}
    if [ ${CUDNN_INSTALL_SAMPLE} = true ]; then
      sudo apt-get -y install libfreeimage3 libfreeimage-dev
      sudo apt-get -y install libcudnn8-samples=${CUDNN_LIB_NAME}
      cd /usr/src/cudnn*/mnistCUDNN
      sudo make clean && sudo make -j$(nproc)
      ./mnistCUDNN
    fi
  fi
fi

echo "======================"
nvidia-smi

echo "======================"
nvcc -V

echo "======================"
if [ -f "/usr/local/cuda/include/cudnn_version.h" ]; then
  cat /usr/local/cuda/include/cudnn_version.h | grep MAJOR -A 2
else
  dpkg -l | grep cudnn
fi
echo "Done."