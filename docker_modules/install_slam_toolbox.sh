#!/bin/bash
set -e

if [ -z "$SLAM_TOOLBOX" ]; then
    echo "Skipping SLAM Toolbox installation as SLAM_TOOLBOX is not set"
    exit 0
fi

# Install SLAM Toolbox, TurtleBot3, and Navigation2 packages
# This script is intended to be run inside the Dockerfile during build.
if [ "$SLAM_TOOLBOX" = "YES" ]; then
    echo "Installing SLAM Toolbox packages for ROS distro: ${ROS_DISTRO:-humble}"

    sudo apt-get update && sudo apt-get install -y \
        ros-${ROS_DISTRO}-slam-toolbox \
        ros-${ROS_DISTRO}-turtlebot3* \
        ros-${ROS_DISTRO}-navigation2 \
        ros-${ROS_DISTRO}-nav2-bringup \
        && sudo rm -rf /var/lib/apt/lists/*
fi

echo "SLAM Toolbox installation completed successfully!"