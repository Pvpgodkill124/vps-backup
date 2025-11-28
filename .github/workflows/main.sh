#!/bin/bash

# --- Configuration ---
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/JishnuTheGamer/Vps/refs/heads/main/playit-ins"
LOG_FILE="/tmp/playit_claim_output.log"
AGENT_PATH="/usr/local/bin/playit" # Assuming the script installs the agent here or to /usr/bin

# --- Functions ---

# Function to execute a command with detailed logging
execute_command() {
    local cmd="$1"
    local desc="$2"
    echo -e "\n--- Running: $desc ---"
    if eval "$cmd"; then
        echo "SUCCESS: $desc completed."
        return 0
    else
        echo "ERROR: $desc failed." >&2
        return 1
    fi
}

# Function to run playit agent and find the claim URL
find_claim_code() {
    echo -e "\n--- Attempting to run playit agent and find the claim code/URL ---"
    echo "Running playit agent in the background for a few seconds to capture output..."

    # Run the agent in the background, redirecting stdout and stderr to the log file
    # We use a short timeout (5 seconds) because the claim code is generated immediately.
    # The 'stdbuf -oL' prevents buffering issues when running the program non-interactively.
    # The 'timeout' command ensures the script doesn't hang.
    timeout 5s stdbuf -oL playit 2>&1 | tee "$LOG_FILE" &
    
    # Capture the PID of the background process
    PLAYIT_PID=$!
    
    # Wait for the program to run and output the claim code
    sleep 3
    
    # Attempt to kill the agent process gracefully after capturing the output
    if ps -p $PLAYIT_PID > /dev/null; then
        kill $PLAYIT_PID
        wait $PLAYIT_PID 2>/dev/null
        echo "Agent stopped. Analyzing output in $LOG_FILE..."
    else
        echo "Agent process already exited. Analyzing output..."
    fi

    # Search the log file for the claim URL pattern: "https://playit.gg/claim?claim_token=..."
    CLAIM_URL=$(grep -oE "https://playit.gg/claim\?claim_token=[a-zA-Z0-9_\-]+" "$LOG_FILE" | head -n 1)

    if [ -n "$CLAIM_URL" ]; then
        echo -e "\n========================================================"
        echo "✅ CLAIM URL FOUND:"
        echo "Please visit this URL in your browser to claim the agent:"
        echo "$CLAIM_URL"
        echo "========================================================"
    else
        echo -e "\n========================================================"
        echo "⚠️ WARNING: Claim URL not found in the output."
        echo "You may need to run the 'playit' command manually and copy the link."
        echo "========================================================"
        # Display the last part of the log for manual inspection
        echo "Last 10 lines of playit output:"
        tail -n 10 "$LOG_FILE"
    fi
}

# --- Main Execution ---

# 1. Execute the installation script via curl and bash
execute_command "curl -s \"$INSTALL_SCRIPT_URL\" | bash" "Installation using provided bash script"

# Check if the playit binary is accessible after installation
if ! command -v playit &> /dev/null; then
    echo -e "\nFATAL ERROR: The 'playit' command was not found after installation. Cannot proceed with claim code retrieval." >&2
    exit 1
fi

# 2. Find and display the claim code
find_claim_code

# 3. Cleanup (optional)
# rm -f "$LOG_FILE"

echo -e "\nInstallation and claim attempt finished."
