#!/bin/bash
set -e

# Install Isaac Sim related components

# Check required environment variables
if [ -z "$USERNAME" ]; then
    echo "Error: USERNAME environment variable is required but not set"
    exit 1
fi
if [ -z "$TARGETARCH" ]; then
    echo "Error: TARGETARCH environment variable is required but not set"
    exit 1
fi
if [ -z "$ISAAC_SIM_VERSION" ]; then
    echo "Skipping Isaac Sim installation as ISAAC_SIM_VERSION is not set"
    exit 0
fi
if [ -z "$ISAACSIM_PATH" ]; then
    echo "Error: ISAACSIM_PATH environment variable is required but not set"
    exit 1
fi

echo "Installing Isaac Sim components for architecture: $TARGETARCH"
echo "Isaac Sim version: $ISAAC_SIM_VERSION"

# Only install Isaac Sim components on amd64 architecture
if [ "$TARGETARCH" != "amd64" ]; then
    echo "Skipping Isaac Sim installation for architecture: $TARGETARCH (only supported on amd64)"
    exit 0
fi

echo "Installing 'libglu1-mesa' for Iray and 'libxrandr2' to support Isaac Sim WebRTC streaming..."
sudo apt-get update && sudo apt-get install -y \
    libglu1-mesa libxrandr2 \
    && sudo rm -rf /var/lib/apt/lists/* \
    || exit 1

echo "Checking available disk space..."
df -h /tmp
df -h "$ISAACSIM_PATH" || df -h /

if [ "$ISAAC_SIM_VERSION" = "4.5.0" ]; then
    echo "Installing Isaac Sim Compatibility Checker 4.5.0..."
    # Note: The Isaac Sim Compatibility Checker is installed since its usefulness outweighs the image size increase
    # Ref: https://docs.isaacsim.omniverse.nvidia.com/4.5.0/installation/requirements.html#isaac-sim-compatibility-checker
    python3 -V | grep "Python 3.10" \
        && cd /tmp \
        && wget -q https://download.isaacsim.omniverse.nvidia.com/isaac-sim-comp-check%404.5.0-rc.6%2Brelease.675.f1cca148.gl.linux-x86_64.release.zip \
        && unzip "isaac-sim-comp-check@4.5.0-rc.6+release.675.f1cca148.gl.linux-x86_64.release.zip" -d ~/isaac-sim-comp-check \
        && rm "isaac-sim-comp-check@4.5.0-rc.6+release.675.f1cca148.gl.linux-x86_64.release.zip" \
        || exit 1
    echo "Installing Isaac Sim 4.5.0 (requires Python 3.10)..."
    # Ref: https://docs.isaacsim.omniverse.nvidia.com/4.5.0/installation/install_workstation.html
    python3 -V | grep "Python 3.10" \
        && cd /tmp \
        && wget -q https://download.isaacsim.omniverse.nvidia.com/isaac-sim-standalone%404.5.0-rc.36%2Brelease.19112.f59b3005.gl.linux-x86_64.release.zip \
        && unzip "isaac-sim-standalone@4.5.0-rc.36+release.19112.f59b3005.gl.linux-x86_64.release.zip" -d "$ISAACSIM_PATH" \
        && rm "isaac-sim-standalone@4.5.0-rc.36+release.19112.f59b3005.gl.linux-x86_64.release.zip" \
        && cd "$ISAACSIM_PATH" \
        && ./post_install.sh \
        || exit 1

    # Note: Optional dependencies and the Isaac Sim ROS workspace are not installed to minimize image size
    # Ref: https://docs.isaacsim.omniverse.nvidia.com/4.5.0/installation/install_ros.html#running-native-ros
    # Ref: https://docs.isaacsim.omniverse.nvidia.com/4.5.0/installation/install_ros.html#setting-up-workspaces
elif [ "$ISAAC_SIM_VERSION" = "5.0.0" ]; then
    echo "Check installed Python version..."
    python3 -V
    # Install Python 3.11
    echo "Installing Python 3.11 for Isaac Sim 5.0.0..."
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y python3.11 python3.11-dev python3.11-distutils python3.11-venv

    # Update alternatives to make python3 point to python3.11
    echo "Updating alternatives to make python3 point to python3.11..."
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2
    sudo update-alternatives --set python3 /usr/bin/python3.11
    
    # Verify that python3 now points to python3.11
    echo "Verifying python3 version after update:"
    python3 -V

    echo "Installing Isaac Sim Compatibility Checker 5.0.0..."
    # Ref: https://docs.isaacsim.omniverse.nvidia.com/5.0.0/installation/requirements.html#isaac-sim-compatibility-checker
    # python3 -V | grep "Python 3.11"
    cd /tmp \
        && wget -q https://download.isaacsim.omniverse.nvidia.com/isaac-sim-comp-check-5.0.0-linux-x86_64.zip \
        && unzip "isaac-sim-comp-check-5.0.0-linux-x86_64.zip" -d ~/isaac-sim-comp-check \
        && rm "isaac-sim-comp-check-5.0.0-linux-x86_64.zip" \
        || { echo "Error: Failed to download or extract Isaac Sim Compatibility Checker"; exit 1; }
    echo "Installing Isaac Sim 5.0.0 (requires Python 3.11)..."
    # Ref: https://docs.isaacsim.omniverse.nvidia.com/5.0.0/installation/install_workstation.html
    python3 -V | grep "Python 3.11" \
        && cd /tmp \
        && wget -q https://download.isaacsim.omniverse.nvidia.com/isaac-sim-standalone-5.0.0-linux-x86_64.zip \
        && unzip "isaac-sim-standalone-5.0.0-linux-x86_64.zip" -d "$ISAACSIM_PATH" \
        && rm "isaac-sim-standalone-5.0.0-linux-x86_64.zip" \
        && cd "$ISAACSIM_PATH" \
        # Run post_install.sh and explicitly check its exit code
        if [ -f "./post_install.sh" ]; then
            chmod +x ./post_install.sh
            ./post_install.sh
            POST_INSTALL_EXIT_CODE=$?
            if [ $POST_INSTALL_EXIT_CODE -ne 0 ]; then
                echo "Error: post_install.sh failed with exit code: $POST_INSTALL_EXIT_CODE"
                echo "Stopping installation as requested"
                exit 1
            fi
        else
            echo "Error: post_install.sh not found in $(pwd)"
            exit 1
        fi
else
    echo "Error: Unsupported Isaac Sim version: $ISAAC_SIM_VERSION"
    exit 1
fi

echo "Fixing SciPy (in base image) incompatibility with NumPy version (in Isaac Sim) numpy==1.26.0..."
pip install scipy==1.14.1 numpy==1.26.0

echo "Creating Isaac Sim directories with correct ownership to avoid permission issues after volume mount..."
sudo mkdir -p /isaac-sim && sudo chown $USERNAME:$USERNAME /isaac-sim || exit 1

if [ "$ISAAC_SIM_VERSION" = "4.5.0" ]; then
    echo "Creating Isaac Sim 4.5.0 specific directories with correct ownership to avoid permission issues after volume mount..."
    mkdir -p /isaac-sim/kit/cache \
        && mkdir -p /home/$USERNAME/.cache/ov \
        && mkdir -p /home/$USERNAME/.local/lib/python3.10/site-packages/omni/cache \
        && mkdir -p /home/$USERNAME/.cache/pip \
        && mkdir -p /home/$USERNAME/.cache/nvidia/GLCache \
        && mkdir -p /home/$USERNAME/.nv/ComputeCache \
        && mkdir -p /home/$USERNAME/.nvidia-omniverse/logs \
        && mkdir -p /home/$USERNAME/.local/lib/python3.10/site-packages/omni/logs \
        && mkdir -p /home/$USERNAME/.local/share/ov/data \
        && mkdir -p /home/$USERNAME/.local/lib/python3.10/site-packages/omni/data \
        && mkdir -p /home/$USERNAME/Documents \
        || exit 1
elif [ "$ISAAC_SIM_VERSION" = "5.0.0" ]; then
    echo "Creating Isaac Sim 5.0.0 specific directories with correct ownership to avoid permission issues after volume mount..."
    mkdir -p /isaac-sim/kit/cache \
        && mkdir -p /home/$USERNAME/.cache/ov \
        && mkdir -p /home/$USERNAME/.local/lib/python3.11/site-packages/omni/cache \
        && mkdir -p /home/$USERNAME/.cache/pip \
        && mkdir -p /home/$USERNAME/.cache/nvidia/GLCache \
        && mkdir -p /home/$USERNAME/.nv/ComputeCache \
        && mkdir -p /home/$USERNAME/.nvidia-omniverse/logs \
        && mkdir -p /home/$USERNAME/.local/lib/python3.11/site-packages/omni/logs \
        && mkdir -p /home/$USERNAME/.local/share/ov/data \
        && mkdir -p /home/$USERNAME/.local/lib/python3.11/site-packages/omni/data \
        && mkdir -p /home/$USERNAME/Documents \
        || exit 1
fi

echo "Isaac Sim installation completed successfully!"
