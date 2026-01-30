#include <cassert>
#include <cstdint>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/// Inverts a (h ^= h >> s) operation with 8 <= s <= 16
unsigned int invert_shift_xor(unsigned int hs, unsigned int s) {
   assert(s >= 8 && s <= 16);

   unsigned hs0 = hs >> 24;
   unsigned hs1 = (hs >> 16) & 0xff;
   unsigned hs2 = (hs >> 8) & 0xff;
   unsigned hs3 = hs & 0xff;

   unsigned h0 = hs0;
   unsigned h1 = hs1 ^ (h0 >> (s - 8));
   unsigned h2 = (hs2 ^ (h0 << (16 - s)) ^ (h1 >> (s - 8))) & 0xff;
   unsigned h3 = (hs3 ^ (h1 << (16 - s)) ^ (h2 >> (s - 8))) & 0xff;

   return (h0 << 24) + (h1 << 16) + (h2 << 8) + h3;
}

unsigned int murmur_hash_inverse(unsigned int h, unsigned int seed) {
   const unsigned int m = 0x5bd1e995;
   const unsigned int minv = 0xe59b19bd; // Multiplicative inverse of m under % 2^32
   const int r = 24;

   h = invert_shift_xor(h, 15);
   h *= minv;
   h = invert_shift_xor(h, 13);

   unsigned int hforward = seed ^ 4;
   hforward *= m;
   unsigned int k = hforward ^ h;
   k *= minv;
   k ^= k >> r;
   k *= minv;

#ifdef PLATFORM_BIG_ENDIAN
   char *data = (char *)&k;
   k = (data[0]) + (data[1] << 8) + (data[2] << 16) + (data[3] << 24);
#endif

   return k;
}

// And for reference, here is the full code, with both the regular murmur hash
// and the inverses for 32- and 64-bit hashes:
unsigned int murmur_hash(const void *key, int len, unsigned int seed) {
   // 'm' and 'r' are mixing constants generated offline.
   // They're not really 'magic', they just happen to work well.

   const unsigned int m = 0x5bd1e995;
   const int r = 24;

   // Initialize the hash to a 'random' value

   unsigned int h = seed ^ len;

   // Mix 4 bytes at a time into the hash

   const unsigned char *data = (const unsigned char *)key;

   while (len >= 4) {
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

   switch (len) {
      case 3:
         h ^= data[2] << 16;
      case 2:
         h ^= data[1] << 8;
      case 1:
         h ^= data[0];
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

   const uint64_t *data = (const uint64_t *)key;
   const uint64_t *end = data + (len / 8);

   while (data != end) {
#ifdef PLATFORM_BIG_ENDIAN
      uint64_t k = *data++;
      char *p = (char *)&k;
      char c;
      c = p[0];
      p[0] = p[7];
      p[7] = c;
      c = p[1];
      p[1] = p[6];
      p[6] = c;
      c = p[2];
      p[2] = p[5];
      p[5] = c;
      c = p[3];
      p[3] = p[4];
      p[4] = c;
#else
      uint64_t k = *data++;
#endif

      k *= m;
      k ^= k >> r;
      k *= m;

      h ^= k;
      h *= m;
   }

   const unsigned char *data2 = (const unsigned char *)data;

   switch (len & 7) {
      case 7:
         h ^= uint64_t(data2[6]) << 48;
      case 6:
         h ^= uint64_t(data2[5]) << 40;
      case 5:
         h ^= uint64_t(data2[4]) << 32;
      case 4:
         h ^= uint64_t(data2[3]) << 24;
      case 3:
         h ^= uint64_t(data2[2]) << 16;
      case 2:
         h ^= uint64_t(data2[1]) << 8;
      case 1:
         h ^= uint64_t(data2[0]);
         h *= m;
   };

   h ^= h >> r;
   h *= m;
   h ^= h >> r;

   return h;
}

uint64_t murmur_hash_64_inverse(uint64_t h, uint64_t seed) {
   const uint64_t m = 0xc6a4a7935bd1e995ULL;
   const uint64_t minv = 0x5f7a0ea7e59b19bdULL; // Multiplicative inverse of m under % 2^64
   const int r = 47;

   h ^= h >> r;
   h *= minv;
   h ^= h >> r;
   h *= minv;

   uint64_t hforward = seed ^ (8 * m);
   uint64_t k = h ^ hforward;

   k *= minv;
   k ^= k >> r;
   k *= minv;

#ifdef PLATFORM_BIG_ENDIAN
   char *p = (char *)&k;
   char c;
   c = p[0];
   p[0] = p[7];
   p[7] = c;
   c = p[1];
   p[1] = p[6];
   p[6] = c;
   c = p[2];
   p[2] = p[5];
   p[5] = c;
   c = p[3];
   p[3] = p[4];
   p[4] = c;
#endif

   return k;
}

int main(int argc, char *argv[]) {
   if (argc < 2) {
      printf("hex number was not given as an argument\n");
      return 1;
   }

   char *number_str = argv[1];
   int radix = 16;
   size_t arg_len = strlen(number_str);
   bool hex_input = (arg_len > 2 && number_str[0] == '0' && (number_str[1] == 'x' || number_str[1] == 'X'));

   if (!hex_input) {
      printf("assuming decimal input instead of hexadecimal ...\n");
      radix = 10;
   }

   if (radix == 16 && hex_input)
      number_str += 2;

   uint64_t val64 = (uint64_t)strtoull(number_str, NULL, radix);
   uint32_t val32 = val64;
   uint64_t val32_m2 = val32;

   val32_m2 <<= 32;

   printf("32-bit hash input ::           0x%08x\n", val32);
   printf("64-bit hash input ::   0x%016llx\n", val64);

   uint32_t inv_val32 = murmur_hash_inverse(val32, 0);
   uint64_t inv_val64 = murmur_hash_64_inverse(val64, 0);
   uint64_t inv_val32_m2 = murmur_hash_64_inverse(val32_m2, 0);

   printf("\n32-bit inverse               ::           0x%08x\n    lua string id :: \"", inv_val32);
   for (int i = 0; i < 4; i++)
      printf("\\x%02x", ((char *)&inv_val32)[i] & 0xff);
   printf("\"\n\n64-bit inverse               ::   0x%016llx\n    lua string id :: \"", inv_val64);
   for (int i = 0; i < 8; i++)
      printf("\\x%02x", ((char *)&inv_val64)[i] & 0xff);
   printf("\"\n\n32-bit inverse for Magicka 2 ::   0x%016llx\n    lua string id :: \"", inv_val32_m2);
   for (int i = 0; i < 8; i++)
      printf("\\x%02x", ((char *)&inv_val32_m2)[i] & 0xff);

   printf("\"\n\n32-bit validation               ::   %s\n", murmur_hash(&inv_val32, 4, 0) == val32 ? "valid" : "NOT VALID");
   printf("64-bit validation               ::   %s\n", murmur_hash_64(&inv_val64, 8, 0) == val64 ? "valid" : "NOT VALID");
   printf("32-bit validation for Magicka 2 ::   %s\n", (murmur_hash_64(&inv_val32_m2, 8, 0) >> 32) == val32 ? "valid" : "NOT VALID");

   return 0;
}
