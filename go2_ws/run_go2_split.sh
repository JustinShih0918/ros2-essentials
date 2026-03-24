#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="go2_stack"
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_FILE="$WORKSPACE_DIR/install/setup.bash"

if ! command -v tmux >/dev/null 2>&1; then
  echo "Error: tmux is not installed. Please install tmux first."
  exit 1
fi

if [[ ! -f "$SETUP_FILE" ]]; then
  echo "Error: ROS setup file not found at $SETUP_FILE"
  echo "Build the workspace first (e.g. colcon build), then retry."
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Session '$SESSION_NAME' already exists. Attaching..."
  exec tmux attach -t "$SESSION_NAME"
fi

tmux new-session -d -s "$SESSION_NAME" -c "$WORKSPACE_DIR"

# Pane 0: go2_bringup
CMD_1="source '$SETUP_FILE' && ros2 launch go2_bringup go2_bringup.launch.py"
# Pane 1: champ_bringup
CMD_2="source '$SETUP_FILE' && ros2 launch champ_bringup go2.launch.py"
# Pane 2: keyboard teleop
CMD_3="source '$SETUP_FILE' && ros2 run teleop_twist_keyboard teleop_twist_keyboard"

PANE_MAIN="$(tmux display-message -p -t "$SESSION_NAME":0.0 '#{pane_id}')"
tmux send-keys -t "$PANE_MAIN" "$CMD_1" C-m

PANE_CHAMP="$(tmux split-window -h -t "$PANE_MAIN" -c "$WORKSPACE_DIR" -P -F '#{pane_id}')"
tmux send-keys -t "$PANE_CHAMP" "$CMD_2"

PANE_TELEOP="$(tmux split-window -v -t "$PANE_MAIN" -c "$WORKSPACE_DIR" -P -F '#{pane_id}')"
tmux send-keys -t "$PANE_TELEOP" "$CMD_3" C-m

# Pane 3: empty pane for manual commands
PANE_USER="$(tmux split-window -v -t "$PANE_CHAMP" -c "$WORKSPACE_DIR" -P -F '#{pane_id}')"

tmux select-layout -t "$SESSION_NAME":0 tiled

# Focus empty pane so you can type commands right away after attach.
tmux select-pane -t "$PANE_USER"

exec tmux attach -t "$SESSION_NAME"
