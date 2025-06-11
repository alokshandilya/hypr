#!/bin/bash

# Configuration
SCRATCH_CLASS="KittyScratch"     # We will now use this for the --class argument
SCRATCH_TERM_CMD="kitty --class=$SCRATCH_CLASS" # Command to launch Kitty with the specific class

# --- DO NOT EDIT BELOW THIS LINE ---

CURRENT_WORKSPACE_ID=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .activeWorkspace.id')

# Get info about the scratchpad window
# -99 is the ID for special:scratch workspace
# IMPORTANT: We are now searching by 'class' instead of 'initialClass' for reliability
SCRATCH_INFO=$(hyprctl clients -j | jq -r --arg class "$SCRATCH_CLASS" '.[] | select(.class == $class) | .address + " " + (.workspace.id | tostring)')

if [ -z "$SCRATCH_INFO" ]; then
    # Window not running, launch it.
    hyprctl dispatch exec -- "$SCRATCH_TERM_CMD"

    sleep 0.1 # Small delay

    # Re-fetch info to get the address of the newly launched window, searching by 'class'
    SCRATCH_INFO=$(hyprctl clients -j | jq -r --arg class "$SCRATCH_CLASS" '.[] | select(.class == $class) | .address + " " + (.workspace.id | tostring)')

    if [ -n "$SCRATCH_INFO" ]; then
        SCRATCH_ADDR=$(echo "$SCRATCH_INFO" | awk '{print $1}')
        hyprctl dispatch movetoworkspace "$CURRENT_WORKSPACE_ID,address:$SCRATCH_ADDR"
        hyprctl dispatch focuswindow "address:$SCRATCH_ADDR"
    fi
else
    SCRATCH_ADDR=$(echo "$SCRATCH_INFO" | awk '{print $1}')
    SCRATCH_WS_ID=$(echo "$SCRATCH_INFO" | awk '{print $2}')

    if [ "$SCRATCH_WS_ID" == "-99" ]; then
        # Window is currently on special:scratch (hidden), bring it to current workspace and focus
        hyprctl dispatch movetoworkspace "$CURRENT_WORKSPACE_ID,address:$SCRATCH_ADDR"
        hyprctl dispatch focuswindow "address:$SCRATCH_ADDR"
    elif [ "$SCRATCH_WS_ID" == "$CURRENT_WORKSPACE_ID" ]; then
        # Window is currently on the current workspace (visible), hide it by sending to special:scratch
        hyprctl dispatch movetoworkspacesilent "special:scratch,address:$SCRATCH_ADDR"
    else
        # Window is on a different regular workspace, bring it to current and focus
        hyprctl dispatch movetoworkspace "$CURRENT_WORKSPACE_ID,address:$SCRATCH_ADDR"
        hyprctl dispatch focuswindow "address:$SCRATCH_ADDR"
    fi
fi
