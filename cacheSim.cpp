#include <cstdlib>
#include <iostream>
#include <fstream>
#include <sstream>



#include <iostream>
#include <unordered_map>
#include <list>
#include <vector>
#include <cstdint>

class Cache {
private:
    struct Block {
        uint64_t tag;
        bool valid;
        bool dirty;
    };

    // Parameters
    size_t cacheSize;       // bytes
    size_t blockSize;       // bytes
    size_t associativity;   // ways
    size_t cyclesPerAccess; // cycles
    bool writeAllocate;     // true = write allocate, false = no write allocate

    // Derived
    size_t numSets;
    size_t blocksPerSet;

    // Data structure: each set is a list (LRU)
    std::vector<std::list<Block>> sets;

    // Stats
    size_t totalAccesses;
    size_t misses;

    // Helpers
    size_t getSetIndex(uint64_t addr) const {
        return (addr / blockSize) % numSets;
    }

    uint64_t getTag(uint64_t addr) const {
        return (addr / blockSize) / numSets;
    }

public:
    Cache(size_t cacheSizeBytes,
          size_t blockSizeBytes,
          size_t assoc,
          size_t cycles,
          bool wrAlloc)
        : cacheSize(cacheSizeBytes),
          blockSize(blockSizeBytes),
          associativity(assoc),
          cyclesPerAccess(cycles),
          writeAllocate(wrAlloc),
          totalAccesses(0),
          misses(0)
    {
        numSets = (cacheSize / blockSize) / associativity;
        blocksPerSet = associativity;
        sets.resize(numSets);
    }

    void access(uint64_t addr, bool isWrite) {
        totalAccesses++;
        size_t setIdx = getSetIndex(addr);
        uint64_t tag = getTag(addr);

        auto &set = sets[setIdx];
        for (auto it = set.begin(); it != set.end(); ++it) {
            if (it->valid && it->tag == tag) {
                // Hit: move to front (LRU)
                Block blk = *it;
                set.erase(it);
                set.push_front(blk);
                return;
            }
        }

        // Miss
        misses++;

        if (isWrite && !writeAllocate) {
            // No write allocate: don't bring block into cache
            return;
        }

        // Write allocate OR read miss: bring block into cache
        if (set.size() >= blocksPerSet) {
            set.pop_back(); // evict LRU
        }
        set.push_front({tag, true, isWrite});
    }

    size_t getTotalAccesses() const {
        return totalAccesses;
    }

    size_t getMisses() const {
        return misses;
    }
};



using std::FILE;
using std::string;
using std::cout;
using std::endl;
using std::cerr;
using std::ifstream;
using std::stringstream;

int main(int argc, char **argv) {

	if (argc < 19) {
		cerr << "Not enough arguments" << endl;
		return 0;
	}

	// Get input arguments

	// File
	// Assuming it is the first argument
	char* fileString = argv[1];
	ifstream file(fileString); //input file stream
	string line;
	if (!file || !file.good()) {
		// File doesn't exist or some other error
		cerr << "File not found" << endl;
		return 0;
	}

	unsigned MemCyc = 0, BSize = 0, L1Size = 0, L2Size = 0, L1Assoc = 0,
			L2Assoc = 0, L1Cyc = 0, L2Cyc = 0, WrAlloc = 0;

	for (int i = 2; i < 19; i += 2) {
		string s(argv[i]);
		if (s == "--mem-cyc") {
			MemCyc = atoi(argv[i + 1]);
		} else if (s == "--bsize") {
			BSize = atoi(argv[i + 1]);
		} else if (s == "--l1-size") {
			L1Size = atoi(argv[i + 1]);
		} else if (s == "--l2-size") {
			L2Size = atoi(argv[i + 1]);
		} else if (s == "--l1-cyc") {
			L1Cyc = atoi(argv[i + 1]);
		} else if (s == "--l2-cyc") {
			L2Cyc = atoi(argv[i + 1]);
		} else if (s == "--l1-assoc") {
			L1Assoc = atoi(argv[i + 1]);
		} else if (s == "--l2-assoc") {
			L2Assoc = atoi(argv[i + 1]);
		} else if (s == "--wr-alloc") {
			WrAlloc = atoi(argv[i + 1]);
		} else {
			cerr << "Error in arguments" << endl;
			return 0;
		}
	}

	while (getline(file, line)) {

		stringstream ss(line);
		string address;
		char operation = 0; // read (R) or write (W)
		if (!(ss >> operation >> address)) {
			// Operation appears in an Invalid format
			cout << "Command Format error" << endl;
			return 0;
		}

		// DEBUG - remove this line
		cout << "operation: " << operation;

		string cutAddress = address.substr(2); // Removing the "0x" part of the address

		// DEBUG - remove this line
		cout << ", address (hex)" << cutAddress;

		unsigned long int num = 0;
		num = strtoul(cutAddress.c_str(), NULL, 16);

		// DEBUG - remove this line
		cout << " (dec) " << num << endl;

	}

	double L1MissRate;
	double L2MissRate;
	double avgAccTime;

	printf("L1miss=%.03f ", L1MissRate);
	printf("L2miss=%.03f ", L2MissRate);
	printf("AccTimeAvg=%.03f\n", avgAccTime);

	return 0;
}
