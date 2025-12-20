#!/bin/bash

# Configuration
EXECUTABLE="./cacheSim"
TEMP_OUTPUT="temp_output_run_tests.txt"

# Colors for output formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Global Counters
FAILED_TESTS=0
TOTAL_TESTS=0

# ==============================================
# Step 1: Compile the project
# ==============================================
echo "--- Starting Build Process ---"
make clean > /dev/null 2>&1
echo "Running 'make'..."
make
COMPILE_STATUS=$?

if [ $COMPILE_STATUS -ne 0 ]; then
    echo -e "\n${RED}Error: Compilation failed!${NC}"
    exit 1
fi

if [ ! -f "$EXECUTABLE" ]; then
    echo -e "\n${RED}Error: Executable '$EXECUTABLE' not found after make.${NC}"
    exit 1
fi

echo -e "${GREEN}Compilation successful.${NC}\n"

# ==============================================
# Helper Function to Run a Suite of Tests
# ==============================================
run_test_suite() {
    local DIR_NAME=$1
    
    echo "========================================"
    echo "Running tests in: $DIR_NAME"
    echo "========================================"

    if [ ! -d "$DIR_NAME" ]; then
        echo -e "${RED}Directory '$DIR_NAME' not found. Skipping.${NC}\n"
        return
    fi

    # Find all command files
    shopt -s nullglob
    local COMMAND_FILES=("$DIR_NAME"/*_command)
    shopt -u nullglob

    if [ ${#COMMAND_FILES[@]} -eq 0 ]; then
         echo -e "No test *_command files found in '$DIR_NAME'.\n"
         return
    fi

    for COMMAND_FILE in "${COMMAND_FILES[@]}"; do
        ((TOTAL_TESTS++))

        # Extract test name (e.g., "tests/long_command" -> "long")
        local TEST_NAME=$(basename "$COMMAND_FILE" _command)
        
        # Define expected paths
        local TRACE_FILE_PATH="${DIR_NAME}/${TEST_NAME}_trace"
        local OUTPUT_FILE_PATH="${DIR_NAME}/${TEST_NAME}_output"

        echo "Test: $TEST_NAME"

        # Validation
        if [ ! -f "$TRACE_FILE_PATH" ]; then
             echo -e "  ${RED}[SKIP] Missing trace file: $TRACE_FILE_PATH${NC}"
             continue
        fi
        if [ ! -f "$OUTPUT_FILE_PATH" ]; then
             echo -e "  ${RED}[SKIP] Missing output file: $OUTPUT_FILE_PATH${NC}"
             continue
        fi

        # --- Parse Arguments ---
        # 1. Read file content (e.g., "./cacheSim trace.txt --arg 1")
        local CMD_CONTENT=$(cat "$COMMAND_FILE")
        
        # 2. Strip the executable name (first word)
        local ARGS_ONLY=$(echo "$CMD_CONTENT" | cut -d' ' -f2-)
        
        # 3. Strip the trace file name (now the first word) to get just the flags
        local FLAGS_ONLY=$(echo "$ARGS_ONLY" | cut -d' ' -f2-)

        # 4. Construct new command using the correct path to the trace file
        local FULL_COMMAND="$EXECUTABLE $TRACE_FILE_PATH $FLAGS_ONLY"

        # --- Execute ---
        eval "$FULL_COMMAND" > "$TEMP_OUTPUT" 2>&1
        local EXEC_STATUS=$?

        # --- Compare ---
        if [ $EXEC_STATUS -ne 0 ]; then
             echo -e "  ${RED}[FAIL] Crash/Non-zero exit code.${NC}"
             ((FAILED_TESTS++))
        else
            diff -bB "$TEMP_OUTPUT" "$OUTPUT_FILE_PATH" > /dev/null
            local DIFF_STATUS=$?

            if [ $DIFF_STATUS -eq 0 ]; then
                echo -e "  ${GREEN}[PASS]${NC}"
            else
                echo -e "  ${RED}[FAIL] Output mismatch.${NC}"
                echo "  Expected: $(cat "$OUTPUT_FILE_PATH")"
                echo "  Got:      $(cat "$TEMP_OUTPUT")"
                ((FAILED_TESTS++))
            fi
        fi
        echo "-----------------------------------"
    done
    echo ""
}

# ==============================================
# Step 2: Run Suites
# ==============================================

# Run 'examples' if present
run_test_suite "examples"

# Run 'tests'
run_test_suite "tests"

# ==============================================
# Step 3: Summary
# ==============================================
rm "$TEMP_OUTPUT" 2>/dev/null

if [ $TOTAL_TESTS -eq 0 ]; then
    echo -e "${RED}No tests were found in 'examples' or 'tests' folders.${NC}"
    exit 1
elif [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}SUMMARY: All $TOTAL_TESTS tests passed!${NC}"
    exit 0
else
    echo -e "${RED}SUMMARY: $FAILED_TESTS out of $TOTAL_TESTS tests failed.${NC}"
    exit 1
fi