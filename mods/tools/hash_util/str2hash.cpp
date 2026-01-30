#include <cstdint>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

unsigned int murmur_hash (const void *key, int len, unsigned int seed)
{
    // 'm' and 'r' are mixing constants generated offline.
    // They're not really 'magic', they just happen to work well.

    const unsigned int m = 0x5bd1e995;
    const int r = 24;

    // Initialize the hash to a 'random' value

    unsigned int h = seed ^ len;

    // Mix 4 bytes at a time into the hash

    const unsigned char *data = (const unsigned char *)key;

    while(len >= 4) {
        #ifdef PLATFORM_BIG_ENDIAN
        	unsigned int k = (data[0]) + (data[1] << 8) + (data[2] << 16) + (data[3] << 24);
        #else
        	unsigned int k = *(unsigned int *)data;
        #endif

        k *= m;
        k ^= k >> r;
        k *= m;

        h *= m;
        h ^= k;

        data += 4;
        len -= 4;
    }

    // Handle the last few bytes of the input array

    switch(len) {
        case 3: h ^= data[2] << 16;
        case 2: h ^= data[1] << 8;
        case 1: h ^= data[0];
            h *= m;
    };

    // Do a few final mixes of the hash to ensure the last few
    // bytes are well-incorporated.

    h ^= h >> 13;
    h *= m;
    h ^= h >> 15;

    return h;
}


uint64_t murmur_hash_64(const void *key, int len, uint64_t seed) {
    const uint64_t m = 0xc6a4a7935bd1e995ULL;
    const int r = 47;

    uint64_t h = seed ^ (len * m);

    const uint64_t * data = (const uint64_t *)key;
    const uint64_t * end = data + (len/8);

    while(data != end) {
        #ifdef PLATFORM_BIG_ENDIAN
            uint64_t k = *data++;
            char *p = (char *)&k;
            char c;
            c = p[0]; p[0] = p[7]; p[7] = c;
            c = p[1]; p[1] = p[6]; p[6] = c;
            c = p[2]; p[2] = p[5]; p[5] = c;
            c = p[3]; p[3] = p[4]; p[4] = c;
        #else
        	uint64_t k = *data++;
        #endif

        k *= m;
        k ^= k >> r;
        k *= m;

        h ^= k;
        h *= m;
    }

    const unsigned char * data2 = (const unsigned char*)data;

    switch(len & 7) {
        case 7: h ^= ((uint64_t)data2[6]) << 48;
        case 6: h ^= ((uint64_t)data2[5]) << 40;
        case 5: h ^= ((uint64_t)data2[4]) << 32;
        case 4: h ^= ((uint64_t)data2[3]) << 24;
        case 3: h ^= ((uint64_t)data2[2]) << 16;
        case 2: h ^= ((uint64_t)data2[1]) << 8;
        case 1: h ^= ((uint64_t)data2[0]);
            h *= m;
    };

    h ^= h >> r;
    h *= m;
    h ^= h >> r;

    return h;
}

void print_endian_32(uint32_t val) {
    unsigned char *bytes = (unsigned char *)&val;

    printf("little endian ::                ");
    for (int i = 0; i < 4; i++) {
        printf("\\x%02x", (unsigned int)((val >> (i * 8)) & 0xFF));
    }
    printf("\n");

    printf("big endian ::                   ");
    for (int i = 3; i >= 0; i--) {
        printf("\\x%02x", (unsigned int)((val >> (i * 8)) & 0xFF));
    }
    printf("\n");
}

void print_endian_64(uint64_t val) {
    unsigned char *bytes = (unsigned char *)&val;

    printf("little endian ::                ");
    for (int i = 0; i < 8; i++) {
        printf("\\x%02x", (unsigned int)((val >> (i * 8)) & 0xFF));
    }
    printf("\n");

    printf("big endian ::                   ");
    for (int i = 7; i >= 0; i--) {
        printf("\\x%02x", (unsigned int)((val >> (i * 8)) & 0xFF));
    }
    printf("\n");
}


int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("string was not given as an argument\n");
        return 1;
    }

    size_t len = strlen(argv[1]);

    printf("computing hashes for :: %s\n\n", argv[1]);

    uint32_t hash32 = murmur_hash(argv[1], len, 0 );
    printf("32 bit hash ::               %08x\n", hash32);
    print_endian_32(hash32);

    uint64_t hash64 = murmur_hash_64(argv[1], len, 0 );
    printf("64 bit hash ::               %016llx\n", hash64);
    print_endian_64(hash64);

    uint32_t hash32_m2 = hash64 >> 32;
    printf("32 bit hash for Magicka 2 :: %08x\n", hash32_m2);
    print_endian_32(hash32_m2);

    return 0;
}
