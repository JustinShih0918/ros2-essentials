import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node

def generate_launch_description():
    use_sim_time = LaunchConfiguration('use_sim_time', default='true')

    # launch turtlebot3 world example
    turtlebot3 = Node(
        package='turtlebot3_gazebo',
        executable='turtlebot3_world.launch.py',
        output='screen',
        parameters=[{'use_sim_time': use_sim_time}]
    )
    
    # launch nav2 bringup example
    nav2 = Node(
        package='nav2_bringup',
        executable='navigation_launch.py',
        output='screen',
        parameters=[{'use_sim_time': use_sim_time}]
    )
    
    # launch slam_toolbox online_async example
    slam_toolbox = Node(
        package='slam_toolbox',
        executable='online_async_launch.py',
        output='screen',
        parameters=[{'use_sim_time': use_sim_time}]
    )
    
    # launch rviz with rviz config file
    rviz = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        output='screen',
        arguments=['-d', os.path.join(
            get_package_share_directory('slam_toolbox_examples'),
            'rviz',
            'slam_toolbox_default.rviz'
        )],
        parameters=[{'use_sim_time': use_sim_time}]
    )
    
    return LaunchDescription([
        DeclareLaunchArgument(
            'use_sim_time',
            default_value='true',       
        ),
        turtlebot3,
        nav2,
        slam_toolbox,
        rviz
    ])