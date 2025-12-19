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
        size_t tag;
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
    size_t getSetIndex(unsigned long addr) const {
        return (addr / blockSize) % numSets;
    }

    size_t getTag(unsigned long addr) const {
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

    bool access(unsigned long addr, bool isWrite) {
        totalAccesses++;
        size_t setIdx = getSetIndex(addr);
        size_t tag = getTag(addr);
		cout << setIdx << " " << tag << " " << endl;
        auto &set = sets[setIdx];
        for (auto it = set.begin(); it != set.end(); ++it) {
            if (it->valid && it->tag == tag) {
                // Hit: move to front (LRU)
                Block blk = *it;
                set.erase(it);
                set.push_front(blk);
                return true;
            }
        }

        // If we are here, it's a miss
        misses++;

        if (isWrite && !writeAllocate) {
            // No write allocate: don't bring block into cache
            return false;
        }

        // Write allocate OR read miss: bring block into cache
        if (set.size() >= blocksPerSet) {
            set.pop_back(); // evict LRU
        }
        set.push_front({tag, true, isWrite});
        return false;
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

	Cache l1((1<<L1Size), (1<<BSize), (1<<L1Assoc), L1Cyc, WrAlloc); 
	Cache l2((1<<L2Size), (1<<BSize), (1<<L2Assoc), L2Cyc, WrAlloc); 
	
	unsigned total_time = 0, accesses = 0;


	while (getline(file, line)) {
		accesses++;

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
        

        // Here our code starts
		bool write = operation == 'W';
		bool is_l1_hit = l1.access(num, write);
		// we accessed l1 from CPU
		total_time += L1Cyc;

		cout << (is_l1_hit?"hit":"miss") << endl; // FIXME: remove debug line


		// if we are writing and no write allocate, we are always done at this stage
		// if its a hit, we are done, if its a miss, everything will happen in background
		if(write && !WrAlloc) continue;

        // if l1 missed
        if (!is_l1_hit) {
            // either we are reading or we are in write mode with write alloc 
			bool is_l2_hit = l2.access(num,write);
			// L1 accessed l2, add to total_time
			total_time += L2Cyc;
			// if l2 missed, l2 will access memory, and memory will return data. 
			if(!is_l2_hit){
				cout << "we accessed memory " << MemCyc << endl;
				total_time += 	MemCyc;
			}
			// L2 returns block to L1
			//total_time += L2Cyc;
			// L1 returns block to cpu if we are read
			//if(!write) total_time += L1Cyc;
        }
	}

	cout << l1.getMisses()  << " " <<  (double)l1.getTotalAccesses() << endl;
	double L1MissRate = l1.getMisses() / (double)l1.getTotalAccesses();
	double L2MissRate = l2.getMisses() / (double)l2.getTotalAccesses();
	double avgAccTime = total_time / (double)accesses;
	

	printf("L1miss=%.03f ", L1MissRate);
	printf("L2miss=%.03f ", L2MissRate);
	printf("AccTimeAvg=%.03f\n", avgAccTime);

	return 0;
}
