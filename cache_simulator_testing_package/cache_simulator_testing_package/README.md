# 🎓 Cache Simulator Testing Package

## 🚀 Quick Setup

1. **Put your code in submission/ folder:**
   ```
   submission/
   ├── cacheSim.cpp    # Your implementation
   └── makefile        # Your build file (or use provided one)
   ```

2. **Build your code:**
   ```bash
   cd submission/
   make
   ```

3. **Setup and test:**
   ```bash
   cd ../tools/
   chmod +x *.sh
   ./setup_testing_environment.sh
   ./test_all.sh
   ```

## 🔧 Tools Explained

- **`test_all.sh`** - Run all tests, get pass/fail summary
- **`debug_test.sh`** - Detailed failure analysis when tests fail  
- **`setup_testing_environment.sh`** - One-time environment setup

### Detailed Debugging
```bash
./debug_test.sh                    # Debug all failing tests
./debug_test.sh official          # Debug only official tests  
./debug_test.sh extra             # Debug only extra tests
./debug_test.sh student           # Debug only student tests
```

## 🐛 Debug Tool Features

When tests fail, `debug_test.sh` provides:

- **📋 Test Configuration** - Exact command and parameters used
- **📄 Input Trace** - Shows the memory access pattern that failed
- **✅ Expected vs ❌ Actual** - Side-by-side output comparison
- **🔍 Diff Analysis** - Highlights exact differences
- **📊 Metrics Breakdown** - L1 miss rate, L2 miss rate, access time analysis
- **🛠️ Targeted Suggestions** - Specific debugging hints based on failure type
- **🔄 Reproduction Command** - Copy-paste command to test manually
- **📁 Detailed Reports** - Saved failure reports with timestamps

**Example Debug Output:**
```
❌ DETAILED FAILURE ANALYSIS
Test Name: example1
Expected: L1miss=0.857 L2miss=0.917 AccTimeAvg=83.857
Your Output: L1miss=0.900 L2miss=0.917 AccTimeAvg=85.000

🛠️ Debugging Suggestions:
• L1 Miss Rate differs - Check L1 cache hit/miss logic
• Verify L1 cache size, associativity, and replacement policy
```

## 📊 What You Get

| Test Type | Count | Purpose |
|-----------|-------|---------|
| Official | 12 | Course requirements |
| Extra | 19 | Additional scenarios |
| Student | 3988 | Comprehensive validation |
| **Total** | **4019** | **Complete coverage** |

## 💡 Usage Tips

- Always run `make` first to build your executable
- Run `test_all.sh` to see overall status
- Use `debug_test.sh` when you have failures - it shows exactly what's wrong
- Perfect implementation should show: **4019/4019 (100%)**
- Check `temp/` folder for detailed test logs

## 🎯 Expected Output
```
🎉 ALL TESTS PASSED! 🎉
✅ Perfect Score: 4019/4019 (100%)
```

---
*Good luck with your cache simulator! 🍀*
