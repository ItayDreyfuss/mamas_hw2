#!/bin/bash

# Enhanced Cache Simulator Test Suite with Detailed Failure Analysis
# Usage: ./debug_test.sh [test_suite] [test_name]
# Example: ./debug_test.sh official example1
#          ./debug_test.sh student 42
#          ./debug_test.sh all

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CACHE_SIM="$PROJECT_ROOT/submission/cacheSim"
TESTS_DIR="$PROJECT_ROOT/tests"
DEBUG_DIR="$PROJECT_ROOT/debug_output"

# Create debug directory
mkdir -p "$DEBUG_DIR"

# Function to show detailed test failure
show_test_failure() {
    local test_name="$1"
    local trace_file="$2"
    local command="$3"
    local expected_output="$4"
    local actual_output="$5"
    local test_type="$6"
    
    echo -e "\n${RED}❌ DETAILED FAILURE ANALYSIS${NC}"
    echo "=============================================="
    echo -e "${YELLOW}Test Name:${NC} $test_name"
    echo -e "${YELLOW}Test Type:${NC} $test_type"
    echo -e "${YELLOW}Timestamp:${NC} $(date)"
    
    echo -e "\n${CYAN}📋 Test Configuration:${NC}"
    echo "$command"
    
    echo -e "\n${CYAN}📄 Input Trace File:${NC}"
    echo "----------------------------------------"
    if [ -f "$trace_file" ]; then
        cat "$trace_file" | head -20
        if [ $(wc -l < "$trace_file") -gt 20 ]; then
            echo "... (showing first 20 lines of $(wc -l < "$trace_file") total)"
        fi
    else
        echo "Trace file not found: $trace_file"
    fi
    
    echo -e "\n${CYAN}✅ Expected Output:${NC}"
    echo "----------------------------------------"
    echo "$expected_output"
    
    echo -e "\n${CYAN}❌ Your Output:${NC}"
    echo "----------------------------------------"
    echo "$actual_output"
    
    echo -e "\n${CYAN}🔍 Difference Analysis:${NC}"
    echo "----------------------------------------"
    
    # Save outputs to temp files for diff
    echo "$expected_output" > "$DEBUG_DIR/expected.tmp"
    echo "$actual_output" > "$DEBUG_DIR/actual.tmp"
    
    if command -v diff >/dev/null 2>&1; then
        diff -u "$DEBUG_DIR/expected.tmp" "$DEBUG_DIR/actual.tmp" || true
    else
        echo "diff command not available"
    fi
    
    # Parse and compare metrics
    echo -e "\n${CYAN}📊 Metrics Comparison:${NC}"
    echo "----------------------------------------"
    
    local exp_l1miss=$(echo "$expected_output" | grep -o "L1miss=[0-9.]*" | cut -d= -f2)
    local exp_l2miss=$(echo "$expected_output" | grep -o "L2miss=[0-9.]*" | cut -d= -f2)
    local exp_avgtime=$(echo "$expected_output" | grep -o "AccTimeAvg=[0-9.]*" | cut -d= -f2)
    
    local act_l1miss=$(echo "$actual_output" | grep -o "L1miss=[0-9.]*" | cut -d= -f2)
    local act_l2miss=$(echo "$actual_output" | grep -o "L2miss=[0-9.]*" | cut -d= -f2)
    local act_avgtime=$(echo "$actual_output" | grep -o "AccTimeAvg=[0-9.]*" | cut -d= -f2)
    
    printf "%-15s %-15s %-15s %-10s\n" "Metric" "Expected" "Actual" "Status"
    printf "%-15s %-15s %-15s %-10s\n" "------" "--------" "------" "------"
    
    if [ -n "$exp_l1miss" ] && [ -n "$act_l1miss" ]; then
        local l1_status="❌"
        if [ "$exp_l1miss" = "$act_l1miss" ]; then l1_status="✅"; fi
        printf "%-15s %-15s %-15s %-10s\n" "L1 Miss Rate" "$exp_l1miss" "$act_l1miss" "$l1_status"
    fi
    
    if [ -n "$exp_l2miss" ] && [ -n "$act_l2miss" ]; then
        local l2_status="❌"
        if [ "$exp_l2miss" = "$act_l2miss" ]; then l2_status="✅"; fi
        printf "%-15s %-15s %-15s %-10s\n" "L2 Miss Rate" "$exp_l2miss" "$act_l2miss" "$l2_status"
    fi
    
    if [ -n "$exp_avgtime" ] && [ -n "$act_avgtime" ]; then
        local time_status="❌"
        if [ "$exp_avgtime" = "$act_avgtime" ]; then time_status="✅"; fi
        printf "%-15s %-15s %-15s %-10s\n" "Avg Access Time" "$exp_avgtime" "$act_avgtime" "$time_status"
    fi
    
    echo -e "\n${CYAN}🛠️  Debugging Suggestions:${NC}"
    echo "----------------------------------------"
    
    if [ "$exp_l1miss" != "$act_l1miss" ]; then
        echo "• L1 Miss Rate differs - Check L1 cache hit/miss logic"
        echo "• Verify L1 cache size, associativity, and replacement policy"
    fi
    
    if [ "$exp_l2miss" != "$act_l2miss" ]; then
        echo "• L2 Miss Rate differs - Check L2 cache logic and inclusion policy"
        echo "• Verify L1→L2 writeback handling"
    fi
    
    if [ "$exp_avgtime" != "$act_avgtime" ]; then
        echo "• Average Access Time differs - Check cycle counting logic"
        echo "• Verify memory hierarchy timing (L1/L2/Memory cycles)"
    fi
    
    # Save detailed report
    local report_file="$DEBUG_DIR/failure_report_${test_name}_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "CACHE SIMULATOR TEST FAILURE REPORT"
        echo "==================================="
        echo "Test: $test_name ($test_type)"
        echo "Date: $(date)"
        echo ""
        echo "COMMAND:"
        echo "$command"
        echo ""
        echo "INPUT TRACE:"
        cat "$trace_file" 2>/dev/null || echo "Trace file not found"
        echo ""
        echo "EXPECTED OUTPUT:"
        echo "$expected_output"
        echo ""
        echo "ACTUAL OUTPUT:"
        echo "$actual_output"
        echo ""
        echo "METRICS COMPARISON:"
        echo "L1 Miss Rate: Expected=$exp_l1miss, Actual=$act_l1miss"
        echo "L2 Miss Rate: Expected=$exp_l2miss, Actual=$act_l2miss"
        echo "Avg Access Time: Expected=$exp_avgtime, Actual=$act_avgtime"
    } > "$report_file"
    
    echo -e "\n${PURPLE}📁 Detailed report saved to:${NC} $report_file"
    echo -e "${PURPLE}🔄 To reproduce manually:${NC}"
    echo "   cd $PROJECT_ROOT"
    echo "   $command"
}

# Function to run official tests with detailed failure analysis
debug_official_tests() {
    echo -e "${BLUE}🔬 Debugging Official Tests${NC}"
    echo "----------------------------"
    
    local test_dir="$TESTS_DIR/official_tests"
    local failed_count=0
    local total_count=0
    
    for command_file in "$test_dir"/*_command; do
        if [ ! -f "$command_file" ]; then continue; fi
        
        local test_name=$(basename "$command_file" _command)
        local trace_file="$test_dir/${test_name}_trace"
        local output_file="$test_dir/${test_name}_output"
        
        if [ ! -f "$trace_file" ] || [ ! -f "$output_file" ]; then
            echo -e "${YELLOW}⚠️  Skipping $test_name - missing files${NC}"
            continue
        fi
        
        ((total_count++))
        
        # Parse command
        local cmd_content=$(cat "$command_file")
        local flags_only=$(echo "$cmd_content" | cut -d' ' -f3-)
        
        # Run test
        local actual_output
        actual_output=$("$CACHE_SIM" "$trace_file" $flags_only 2>&1)
        local exit_code=$?
        
        local expected_output=$(cat "$output_file")
        
        if [ $exit_code -ne 0 ] || [ "$actual_output" != "$expected_output" ]; then
            ((failed_count++))
            echo -e "${RED}❌ $test_name${NC}"
            show_test_failure "$test_name" "$trace_file" "$full_command" "$expected_output" "$actual_output" "Official"
        else
            echo -e "${GREEN}✅ $test_name${NC}"
        fi
    done
    
    echo -e "\nOfficial Tests: $((total_count - failed_count))/$total_count passed"
    return $failed_count
}

# Function to debug specific student test
debug_student_test() {
    local test_number="$1"
    
    echo -e "${BLUE}🎓 Debugging Student Test #$test_number${NC}"
    echo "----------------------------------------"
    
    local test_dir="$TESTS_DIR/student_tests"
    
    if [ ! -f "$test_dir/gena2.py" ]; then
        echo -e "${RED}Student test generator not found${NC}"
        return 1
    fi
    
    cd "$test_dir"
    
    # Generate specific test
    python3 -c "
import sys
sys.path.append('.')
from gena2 import gen_test, tests
if $test_number < len(tests):
    params_str, data = gen_test($test_number, tests[$test_number])
    print('PARAMS:', params_str)
    print('TRACE:')
    print(data)
else:
    print('Test number out of range. Max:', len(tests)-1)
" > "$DEBUG_DIR/student_test_$test_number.txt"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Generated test data saved to: $DEBUG_DIR/student_test_$test_number.txt${NC}"
        cat "$DEBUG_DIR/student_test_$test_number.txt"
    else
        echo -e "${RED}Failed to generate test $test_number${NC}"
    fi
}

# Main execution
case "${1:-all}" in
    "official")
        debug_official_tests
        ;;
    "student")
        if [ -n "$2" ]; then
            debug_student_test "$2"
        else
            echo "Usage: $0 student <test_number>"
            echo "Example: $0 student 42"
        fi
        ;;
    "all")
        debug_official_tests
        ;;
    *)
        echo "Usage: $0 [official|student|all] [test_name/number]"
        echo ""
        echo "Examples:"
        echo "  $0 official              # Debug all official tests"
        echo "  $0 student 42            # Debug student test #42"
        echo "  $0 all                   # Debug all test suites"
        ;;
esac
