from launch import LaunchDescription
from launch_ros.substitutions import FindPackageShare
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.substitutions import PathJoinSubstitution, LaunchConfiguration

ARGUMENTS = [
    DeclareLaunchArgument(
        name="use_sim_time",
        default_value="False",
        description="Enable use_sim_time",
    )
]

def generate_launch_description():
    # The path of nav2_params file.
    nav2_params_file = PathJoinSubstitution(
        [FindPackageShare("kobuki_navigation"), "config", "nav2_params_real.yaml"]
    )

    # Launch nav2_bringup. ( Use the launch file in "nav2_bringup" )
    launch_nav2_bringup = IncludeLaunchDescription(
        PathJoinSubstitution(
            [
                FindPackageShare("nav2_bringup").find("nav2_bringup"),
                "launch",
                "navigation_launch.py",
            ]
        ),
        launch_arguments={"params_file": nav2_params_file}.items(),
    )

    # The path of .rviz file.
    rviz_config_path = PathJoinSubstitution(
        [FindPackageShare("kobuki_rviz"), "rviz", "slam.rviz"]
    )

    # Launch rviz2. ( Use the launch file in "kobuki_rviz" )
    launch_kobuki_rviz = IncludeLaunchDescription(
        PathJoinSubstitution(
            [
                FindPackageShare("kobuki_rviz"),
                "launch",
                "open_rviz_launch.py",
            ]
        ),
        launch_arguments={
            "use_sim_time": LaunchConfiguration("use_sim_time"),
            "rviz_config_path": rviz_config_path,
        }.items(),
    )

    ld = LaunchDescription(ARGUMENTS)
    ld.add_action(launch_nav2_bringup)
    ld.add_action(launch_kobuki_rviz)

    return ld
