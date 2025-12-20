#include <cstdlib>
#include <iostream>
#include <fstream>
#include <sstream>
#include <list>
#include <vector>
#include <cstdint>

using std::FILE;
using std::string;
using std::cout;
using std::endl;
using std::cerr;
using std::ifstream;
using std::stringstream;


struct Block {
    size_t tag;
    bool valid;
    bool dirty;
};
struct EvictionInfo {
    unsigned long addr;       
    bool valid;             
    bool dirty; 
};

class Cache {
private:
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

    // inserts a block into the cache, and returning the evicted block if exists, otherwise {0, false, false}
    EvictionInfo insertBlock(unsigned long addr, bool isWrite) {
        size_t setIdx = getSetIndex(addr);
        size_t tag = getTag(addr);
        auto &set = sets[setIdx];

        if (set.size() < blocksPerSet) {
            // There's space in the set
            set.push_front({tag, true, isWrite});
            return {0, false, false}; // No eviction
        }
        // No space in the set, check for invalid blocks first
        for (auto it = set.begin(); it != set.end(); ++it) {
            if (!it->valid) {
                // Found an invalid block, use it
                it->tag = tag;
                it->valid = true;
                it->dirty = isWrite;
                // Move to front (MRU)
                Block blk = *it;
                set.erase(it);
                set.push_front(blk);
                return {0, false, false}; // No eviction
            }
        }
        // No invalid block found, need to evict LRU
        Block evictedBlock = set.back();
        set.pop_back(); // evict LRU
        set.push_front({tag, true, isWrite});

        // Calculate evicted block address
        unsigned long blockIndex = evictedBlock.tag * numSets + setIdx;
        unsigned long evictedAddr = blockIndex * blockSize;
        return {evictedAddr, true, evictedBlock.dirty};
    }

    // snoops a specific block from the cache (will be used only in L1)
    void snoop(unsigned long addr) {
        size_t setIdx = getSetIndex(addr);
        size_t tag = getTag(addr);
        auto &set = sets[setIdx];
        for (auto it = set.begin(); it != set.end(); ++it) {
            if (it->tag == tag) {
                // Found the block to evict
                it->valid = false;
                return;
            }
        }
        return;
    }

    // a function to update a block's dirty status and move it to MRU position(will be used only in L2)
    bool updateDirtyBlock(unsigned long addr) {
        size_t setIdx = getSetIndex(addr);
        size_t tag = getTag(addr);
        auto &set = sets[setIdx];
        for (auto it = set.begin(); it != set.end(); ++it) {
            if (it->tag == tag ) {
                // Found the block to update
                it->dirty = true;
                // Move to front (MRU)
                Block blk = *it;
                set.erase(it);
                set.push_front(blk);
                return true;
            }
        }
        return false;
    }

    // Access the cache, returns true if hit, false if miss
    bool access(unsigned long addr, bool isWrite) {
        totalAccesses++;
        size_t setIdx = getSetIndex(addr);
        size_t tag = getTag(addr);
        auto &set = sets[setIdx];
        for (auto it = set.begin(); it != set.end(); ++it) {
            if (it->valid && it->tag == tag) {
                // Hit: move to front (LRU)
                Block blk = *it;
                blk.dirty = blk.dirty || isWrite; // update dirty bit if it's a write
                set.erase(it);
                set.push_front(blk);
                return true;
            }
        }

        // If we are here, it's a miss
        misses++;
        return false;
    }

    size_t getTotalAccesses() const {
        return totalAccesses;
    }

    size_t getMisses() const {
        return misses;
    }
};



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

	Cache l1(1ULL << L1Size, 1ULL << BSize, 1ULL << L1Assoc, L1Cyc, WrAlloc); 
    Cache l2(1ULL << L2Size, 1ULL << BSize, 1ULL << L2Assoc, L2Cyc, WrAlloc); 
	
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

		// // DEBUG - remove this line 
		// cout << "operation: " << operation;

		string cutAddress = address.substr(2); // Removing the "0x" part of the address

		// // DEBUG - remove this line 
		// cout << ", address (hex)" << cutAddress;

		unsigned long int num = 0;
		num = strtoul(cutAddress.c_str(), NULL, 16);

		// // DEBUG - remove this line 
		// cout << " (dec) " << num << endl;
        



        // Here our code starts
        EvictionInfo evictedFromL1, evictedFromL2;

		bool isWrite = operation == 'W' || operation == 'w';
		bool is_l1_hit = l1.access(num, isWrite), is_l2_hit;

		total_time += L1Cyc; // we accessed l1 from CPU

        if(is_l1_hit) continue; // if L1 hit, we are done
		if(isWrite && !WrAlloc){
            is_l2_hit = l2.updateDirtyBlock(num); // if we are writing and no write allocate, we need to update dirty bit in L2 if the block is there
            total_time += L2Cyc;

            if (!is_l2_hit)
                total_time += MemCyc;
            continue; // if we are writing and no write allocate, we are always done at this stage: if its a hit, we are done, if its a miss, everything will happen in background
        } 
        
        // if l1 missed, we access l2   , either we are reading or we are in write mode with write alloc 
        is_l2_hit = l2.access(num, false); // l2 is always accessed in read mode
        total_time += L2Cyc; // L1 accessed l2, add to total_time

        // if L2 hit, we need to bring block into L1 appropriately
        if(is_l2_hit){
            evictedFromL1 = l1.insertBlock(num,isWrite); // bring block into L1

            // if some block was evicted from L1, we need to check if we need to update it's dirty bit in L2
            if(evictedFromL1.valid && evictedFromL1.dirty){
                l2.updateDirtyBlock(evictedFromL1.addr);    
            }
            continue; // we are done
        }

        // if l2 missed, l2 will access memory, and memory will return data. 
        total_time += MemCyc;
        
        // now we need to bring the block into L2
        evictedFromL2 = l2.insertBlock(num, false); // l2 always accessed in read mode
        // if a valid block was evicted from L2, we need to evict it from L1 as well
        if(evictedFromL2.valid){
            l1.snoop(evictedFromL2.addr); // we don't write to memory so if the snooped block was dirty, we just discard it(it's not in L1 nor L2 anymore)
        }

        // now we need to bring the block into L1 from L2
        evictedFromL1 = l1.insertBlock(num,isWrite);
        // if some block was evicted from L1, we need to check if we need to update it's dirty bit in L2
        if(evictedFromL1.valid && evictedFromL1.dirty){
            l2.updateDirtyBlock(evictedFromL1.addr);    
        }
        // we are done
	}
    // Calculating stats
	double L1MissRate = l1.getMisses() / (double)l1.getTotalAccesses();
	double L2MissRate = l2.getMisses() / (double)l2.getTotalAccesses();
	double avgAccTime = total_time / (double)accesses;
	
	printf("L1miss=%.03f ", L1MissRate);
	printf("L2miss=%.03f ", L2MissRate);
	printf("AccTimeAvg=%.03f\n", avgAccTime);

	return 0;
}
