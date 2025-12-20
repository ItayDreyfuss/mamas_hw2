#!/bin/bash

# Cache Simulator Testing Environment Setup
# For Computer Structure Course - HW2
# 
# This script sets up a comprehensive testing environment for cache simulator validation
# Usage: ./setup_testing_environment.sh

echo "🚀 Cache Simulator Testing Environment Setup"
echo "============================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "\n${BLUE}📋 Testing Environment Features:${NC}"
echo "• Comprehensive test suite (4000+ tests)"
echo "• Detailed failure analysis with debugging info"
echo "• Official course tests (13 tests)"
echo "• Extra validation tests (19 tests)" 
echo "• Student-generated stress tests (3988 tests)"
echo "• Automatic build and validation"
echo "• Shareable test reports"

echo -e "\n${BLUE}📁 Directory Structure:${NC}"
echo "HW2/"
echo "├── submission/          # Your cache simulator code"
echo "│   ├── cacheSim.cpp    # Main implementation"
echo "│   ├── makefile        # Build configuration"
echo "│   └── cacheSim        # Compiled executable"
echo "├── tests/              # All test suites"
echo "│   ├── official_tests/ # Course-provided tests"
echo "│   ├── extra_tests/    # Additional validation"
echo "│   └── student_tests/  # Comprehensive generator"
echo "├── tools/              # Testing utilities"
echo "│   ├── test_all.sh     # Main test runner"
echo "│   ├── debug_test.sh   # Detailed failure analysis"
echo "│   └── setup_testing_environment.sh"
echo "└── debug_output/       # Failure reports and logs"

echo -e "\n${BLUE}🛠️  Available Commands:${NC}"
echo ""
echo -e "${YELLOW}Basic Testing:${NC}"
echo "  ./tools/test_all.sh                    # Run all tests (quick overview)"
echo ""
echo -e "${YELLOW}Detailed Debugging:${NC}"
echo "  ./tools/debug_test.sh official         # Debug official tests with details"
echo "  ./tools/debug_test.sh student 42       # Debug specific student test #42"
echo "  ./tools/debug_test.sh all              # Debug all test suites"
echo ""
echo -e "${YELLOW}Manual Testing:${NC}"
echo "  cd submission && make                   # Build your simulator"
echo "  ./cacheSim trace.txt --mem-cyc 100 ... # Run specific test manually"

echo -e "\n${BLUE}🔍 What You Get When Tests Fail:${NC}"
echo "• Exact command that failed"
echo "• Input trace file contents"
echo "• Expected vs actual output comparison"
echo "• Metric-by-metric analysis (L1miss, L2miss, AccTimeAvg)"
echo "• Debugging suggestions"
echo "• Detailed failure reports saved to debug_output/"
echo "• Manual reproduction commands"

echo -e "\n${BLUE}📊 Example Failure Output:${NC}"
cat << 'EOF'
❌ DETAILED FAILURE ANALYSIS
==============================================
Test Name: example1
Test Type: Official
Timestamp: 2025-12-16 22:20:00

📋 Test Configuration:
./cacheSim example1_trace --mem-cyc 100 --bsize 3 --wr-alloc 1 --l1-size 4 --l1-assoc 1 --l1-cyc 1 --l2-size 6 --l2-assoc 0 --l2-cyc 5

📄 Input Trace File:
----------------------------------------
r 0x00000000
w 0x00000004
r 0x00100000
w 0x00000000

✅ Expected Output:
----------------------------------------
L1miss=0.857 L2miss=0.917 AccTimeAvg=83.857

❌ Your Output:
----------------------------------------
L1miss=0.900 L2miss=0.917 AccTimeAvg=85.000

📊 Metrics Comparison:
----------------------------------------
Metric          Expected        Actual          Status    
------          --------        ------          ------    
L1 Miss Rate    0.857          0.900           ❌        
L2 Miss Rate    0.917          0.917           ✅        
Avg Access Time 83.857         85.000          ❌        

🛠️  Debugging Suggestions:
----------------------------------------
• L1 Miss Rate differs - Check L1 cache hit/miss logic
• Verify L1 cache size, associativity, and replacement policy
• Average Access Time differs - Check cycle counting logic
• Verify memory hierarchy timing (L1/L2/Memory cycles)
EOF

echo -e "\n${BLUE}🎯 Quick Start Guide:${NC}"
echo "1. Place your cacheSim.cpp in submission/ directory"
echo "2. Run: ./tools/test_all.sh"
echo "3. If tests fail, run: ./tools/debug_test.sh official"
echo "4. Fix issues and repeat"

echo -e "\n${BLUE}📤 Sharing with Colleagues:${NC}"
echo "To share this testing environment:"
echo "1. Copy the entire HW2/ directory"
echo "2. Remove submission/cacheSim.cpp (keep your code private)"
echo "3. Share the directory - colleagues can add their code"
echo "4. They run: ./tools/setup_testing_environment.sh"

echo -e "\n${BLUE}⚙️  Requirements:${NC}"
echo "• g++ compiler"
echo "• Python 3 (for student test generator)"
echo "• bash shell"
echo "• make utility"

# Check requirements
echo -e "\n${BLUE}🔧 Checking Requirements:${NC}"

if command -v g++ >/dev/null 2>&1; then
    echo -e "✅ g++ compiler: $(g++ --version | head -1)"
else
    echo -e "❌ g++ compiler not found"
fi

if command -v python3 >/dev/null 2>&1; then
    echo -e "✅ Python 3: $(python3 --version)"
else
    echo -e "❌ Python 3 not found"
fi

if command -v make >/dev/null 2>&1; then
    echo -e "✅ make utility: $(make --version | head -1)"
else
    echo -e "❌ make utility not found"
fi

# Create necessary directories
mkdir -p "$PROJECT_ROOT/debug_output"
mkdir -p "$PROJECT_ROOT/temp"

# Make scripts executable
chmod +x "$PROJECT_ROOT/tools"/*.sh
if [ -f "$PROJECT_ROOT/tests/official_tests/run_tests.sh" ]; then
    chmod +x "$PROJECT_ROOT/tests/official_tests/run_tests.sh"
fi
if [ -f "$PROJECT_ROOT/tests/extra_tests/run_tests.sh" ]; then
    chmod +x "$PROJECT_ROOT/tests/extra_tests/run_tests.sh"
fi

echo -e "\n${GREEN}✅ Testing Environment Ready!${NC}"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Ensure your cacheSim.cpp is in submission/"
echo "2. Run: ./tools/test_all.sh"
echo "3. If failures occur, run: ./tools/debug_test.sh official"

echo -e "\n${BLUE}📚 Documentation:${NC}"
echo "• README.md contains project overview"
echo "• Each test suite has its own documentation"
echo "• Failure reports are saved with timestamps"

echo -e "\n🎉 Happy Testing! Good luck with your cache simulator!"
