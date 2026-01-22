#include <cstdint>
#define WIN32_LEAN_AND_MEAN
#define WIN32_EXTRA_LEAN
#include <direct.h>
#include <stdint.h>
#include <stdlib.h>
#include <windows.h>
#define gnu_printf __printf__ // idk
#include <stdio.h>
#undef gnu_printf
#include <zlib.h>

#include <algorithm>
#include <vector>

#define string(...) #__VA_ARGS__
#define NORETURN __attribute__((noreturn))
#define NOINLINE __attribute__((noinline))
#define INLINE __attribute__((always_inline))
#define ALIGN(N) __attribute__((aligned(N)))
#define THREAD __thread

static void int3() { __asm__("int3"); }

#define assert(c, ...)                                                         \
  do {                                                                         \
    if (__builtin_expect(!(c), 0)) {                                           \
      printf("\n <CRASH> %s:%d:\n  ", __FILE__, __LINE__);                     \
      printf(__VA_ARGS__);                                                     \
      putchar('\n');                                                           \
      putchar('\n');                                                           \
      fflush(stdout);                                                          \
      int3();                                                                  \
    }                                                                          \
  } while (0)

static bool is_digit(char c) { return '0' <= c && c <= '9'; }
static bool is_upper(char c) { return 'A' <= c && c <= 'Z'; }
static bool is_lower(char c) { return 'a' <= c && c <= 'z'; }
static bool is_hex(char c) { return is_digit(c) || is_upper(c) || is_lower(c); }
static bool is_alpha(char c) {
  return c == '_' || c == '.' || is_digit(c) || is_lower(c) || is_upper(c);
}

static const char *split(const char *p) {
  while (*p)
    p++;
  return p;
}

static const char *split(bool (*f)(char), const char *p) {
  while (*p && f(*p))
    p++;
  return p;
}

static bool str_equal(const char *a, const char *b) {
  for (size_t i = 0; a[i] && b[i]; i++)
    if (a[i] != b[i])
      return false;
  return true;
}

static void printlr(const char *l, const char *r) {
  while (l < r)
    putchar(*l++);
}

static void ascii(uint8_t *txt, size_t n, size_t m) {
  for (size_t i = 0; i < n; i++) {
    uint8_t c = *txt++;
    if (31 < c && c < 127)
      putchar(c);
    else
      putchar('.');
    if ((i + 1) % m == 0 || (i + 1) == n)
      putchar('\n');
  }
}

static void iszero(uint8_t *txt, size_t n, size_t m) {
  for (size_t i = 0; i < n; i++) {
    uint8_t c = *txt++;
    if (c == 0)
      putchar(' ');
    else
      putchar('.');
    if ((i + 1) % m == 0 || (i + 1) == n)
      putchar('\n');
  }
}

static void parnt(uint8_t *txt, size_t n, size_t m) {
  for (size_t i = 0; i < n; i++) {
    if (*txt == 0)
      printf(" . ");
    else
      printf("%02x ", *txt);
    txt++;
    if ((i + 1) % m == 0 || (i + 1) == n)
      putchar('\n');
  }
}

static uint64_t murmur64(const void *key, size_t len, uint64_t seed = 0) {
  uint64_t m = 0xc6a4a7935bd1e995ULL;
  uint64_t h = seed ^ (len * m);
  uint64_t *ptr = (uint64_t *)key;
  uint64_t *end = ptr + (len / 8);
  while (ptr != end) {
    uint64_t k = *ptr++;
    k *= m;
    k ^= k >> 47;
    k *= m;
    h ^= k;
    h *= m;
  }
  uint8_t *tail = (uint8_t *)ptr;
  switch (len & 7) {
  case 7:
    h ^= (uint64_t)tail[6] << 48;
  case 6:
    h ^= (uint64_t)tail[5] << 40;
  case 5:
    h ^= (uint64_t)tail[4] << 32;
  case 4:
    h ^= (uint64_t)tail[3] << 24;
  case 3:
    h ^= (uint64_t)tail[2] << 16;
  case 2:
    h ^= (uint64_t)tail[1] << 8;
  case 1:
    h ^= (uint64_t)tail[0];
    h *= m;
  }
  h ^= h >> 47;
  h *= m;
  h ^= h >> 47;
  return h;
}

static const char *demurmur64(uint64_t type) {
  if (type == 0x00a3e6c59a2b9c6c)
    return "timpani_master";
  if (type == 0x0d972bab10b40fd3)
    return "strings";
  if (type == 0x169de9566953d264)
    return "navdata";
  if (type == 0x18dead01056b72e9)
    return "bones";
  if (type == 0x27862fe24795319c)
    return "render_config";
  if (type == 0x2a690fd348fe9ac5)
    return "level";
  if (type == 0x2bbcabe5074ade9e)
    return "input";
  if (type == 0x3b1fa9e8f6bac374)
    return "network_config";
  if (type == 0x786f65c00a816b19)
    return "wav";
  if (type == 0x7ffdb779b04e4ed1)
    return "baked_lighting";
  if (type == 0x82645835e6b73232)
    return "config";
  if (type == 0x84a01660022666eb)
    return "swf";
  if (type == 0x8fd0d44d20650b68)
    return "data";
  if (type == 0x92d3ee038eeb610d)
    return "flow";
  if (type == 0x931e336d7646cc26)
    return "animation";
  if (type == 0x99736be1fff739a4)
    return "timpani_bank";
  if (type == 0x9e5c3cc74575aeb5)
    return "shader_library_group";
  if (type == 0x9efe0a916aae7880)
    return "font";
  if (type == 0xa14e8dfa2cd117e2)
    return "lua";
  if (type == 0xa486d4045106165c)
    return "state_machine";
  if (type == 0xa8193123526fad64)
    return "particles";
  if (type == 0xad2d3fa30d9ab394)
    return "surface_properties";
  if (type == 0xad9c6d9ed1e5e77a)
    return "package";
  if (type == 0xb277b11fe4a61d37)
    return "mouse_cursor";
  if (type == 0xbf21403a3ab0bbb1)
    return "physics_properties";
  if (type == 0xcce8d5b5f5ae333f)
    return "shader";
  if (type == 0xcd4238c6a0c69e32)
    return "texture";
  if (type == 0xd8b27864a97ffdd7)
    return "sound_environmenta";
  if (type == 0xdcfb9e18fff13984)
    return "animation_curves";
  if (type == 0xe0a48d0be9a7453f)
    return "unit";
  if (type == 0xe3f0baa17d620321)
    return "static_pvs";
  if (type == 0xe5ee32a477239a93)
    return "shader_library";
  if (type == 0xeac0b497876adedf)
    return "material";
  if (type == 0xf7505933166d6755)
    return "vector_field";
  if (type == 0xf97af9983c05b950)
    return "spu_job";
  if (type == 0xfa4a8e091a91201e)
    return "ivf";
  if (type == 0xfe73c7dcff8a7ca5)
    return "shading_environment";
  if (type == 0x7a749f1c5f2f2222)
    return "cane_tilecache";
  return nullptr;
}

static bool in_dict(const char *a, size_t len) {
  uint64_t h = murmur64(a, len);
  const char *b = demurmur64(h);
  return str_equal(a, b);
}

static int ulog10(size_t i) {
  size_t r = 0;
  do {
    i /= 10;
    r++;
  } while (i);
  return r;
}

static uintmax_t read_uint(uint8_t **txt, size_t n) {
  uintmax_t r = 0;
  for (size_t i = 0; i < n; i++)
    r |= (uintmax_t)txt[0][i] << i * 8;
  txt[0] += n;
  return r;
}

static void write_uint(uint8_t **txt, size_t n, uintmax_t val) {
  for (size_t i = 0; i < n; i++)
    txt[0][i] = val >> i * 8;
  txt[0] += n;
}

static uint8_t *read_part(uint8_t **txt, size_t n) {
  uint8_t *r = *txt;
  *txt += n;
  return r;
}

static void write_part(uint8_t **txt, size_t n, uint8_t *val) {
  memcpy(*txt, val, n);
  *txt += n;
}

static void write_zero(uint8_t **txt, size_t n) {
  for (size_t i = 0; i < n; i++)
    txt[0][i] = 0;
  txt[0] += n;
}

static size_t scan(uint8_t *txt, size_t len, uintmax_t pat, int n) {
  for (size_t i = 0; i < len - n + 1; i++) {
    uint8_t *ptr = txt + i;
    uintmax_t x = read_uint(&ptr, n);
    if (x == pat)
      return i;
  }
  assert(0, "no nono n");
  return len;
}

static void read_file(const char *path, uint8_t **O) {
  FILE *f = fopen(path, "rb");
  assert(f, "file '%s' not found", path);
  fseek(f, 0, SEEK_END);
  int len = ftell(f);
  rewind(f);
  uint8_t *buf = (uint8_t *)malloc(len);
  fread(buf, 1, len, f);
  fclose(f);

  O[0] = buf;
  O[1] = buf + len;
}

static void try_read_file(const char *path, uint8_t **O) {
  FILE *f = fopen(path, "rb");
  if (f == nullptr)
    return;
  fseek(f, 0, SEEK_END);
  int len = ftell(f);
  rewind(f);
  uint8_t *buf = (uint8_t *)malloc(len);
  fread(buf, 1, len, f);
  fclose(f);

  O[0] = buf;
  O[1] = buf + len;
}

static void write_file(const char *path, uint8_t **I) {
  FILE *f = fopen(path, "wb");
  assert(f, "write to '%s' failed", path);
  fwrite(I[0], 1, I[1] - I[0], f);
  fclose(f);
}

static void garble(uint8_t *buf, size_t len) {
  for (size_t i = 0; i < len; i++)
    buf[i] = i;
}

static void inflate_bundle(uint8_t **I, uint8_t **O) {

  uint8_t *buf = I[0];
  uint8_t *end = I[1];

  uint32_t head = read_uint(&buf, 4);
  uint64_t size = read_uint(&buf, 4) - 1 | (1 << 16) - 1;
  size++;
  uint32_t zero = read_uint(&buf, 4);

  if (head != 0xf0000004) {
    printf("weird\n");
    exit(0);
  }
  assert(head == 0xf0000004, "head = 0x%x", head);
  assert(zero == 0, "zero = 0x%x", zero);

  uint8_t *txt = (uint8_t *)malloc(size);
  uint8_t *ptr = txt;
  size_t avail = size;
  garble(txt, size);

  z_stream zs[1] = {};
  while (buf != end) {
    uint32_t len = read_uint(&buf, 4);

    if (len < (1 << 16)) {

      // retry:

      zs->next_in = buf;
      zs->avail_in = len;
      inflateInit(zs);

      zs->next_out = ptr;
      zs->avail_out = avail;
      int code = inflate(zs, Z_FINISH);

      // if(code == -5) {
      // 	size *= 2;
      // 	size_t off = ptr - txt;
      // 	txt = realloc(txt, size);
      // 	assert(txt, "realloc(2) -> 0");
      // 	avail = size - off;
      // 	ptr = txt + off;
      // 	garble(ptr, avail);
      // 	printf("doubling size to %llu\n", size);

      // 	goto retry;
      // }

      assert(code == 1, "inflate(2) -> %d", code);

      avail -= zs->total_out;
      ptr += zs->total_out;

    } else {

      assert(len == (1 << 16), "block length = %d", len);
      memcpy(ptr, buf, len);

      avail -= 1 << 16;
      ptr += 1 << 16;
    }

    buf += len;
  }

  O[0] = txt;
  O[1] = ptr;
}

static void deflate_bundle(uint8_t **I, uint8_t **O) {

  uint8_t *start = I[0];
  uint8_t *end = I[1];
  size_t size = end - start;
  assert((uint16_t)size == 0, "size must be multiple of 2^16");

  uint8_t seg[1 << 16];
  uint8_t *buf = (uint8_t *)malloc(size);
  uint8_t *ptr = buf;

  write_uint(&ptr, 4, 0xf0000004);
  write_uint(&ptr, 4, size);
  write_uint(&ptr, 4, 0);

  z_stream zs[1] = {};
  for (uint8_t *i = start; i < end; i += 1 << 16) {

    zs->next_in = i;
    zs->avail_in = 1 << 16;

    zs->next_out = seg;
    zs->avail_out = 1 << 16;

    int eh = deflateInit(zs, Z_DEFAULT_COMPRESSION);
    int code = deflate(zs, Z_FINISH);

    if (code == Z_STREAM_END) {
      write_uint(&ptr, 4, zs->total_out);
      write_part(&ptr, zs->total_out, seg);
    } else {
      write_uint(&ptr, 4, 1 << 16);
      write_part(&ptr, 1 << 16, i);
    }
  }

  O[0] = buf;
  O[1] = ptr;
}

static const char *path_segment(const char *path, size_t n) {
  const char *prev = path;
  while (n && *path) {
    if (*path == '/' || *path == '\\') {
      prev = path + 1;
      n--;
    }
    path++;
  }
  return prev;
}

static size_t build_path(char *buf, int len, const char *dir, uint64_t path,
                         uint64_t type, uint32_t pad1, uint32_t flag,
                         uint32_t pad2, uint64_t index, uint64_t count) {

  size_t i = 0;
  const char *eh = demurmur64(type);

  i += snprintf(buf + i, len - i, "%s/%016llx", dir, path);
  assert(i < len, "path too long");

  if (pad1 || flag || pad2) {
    i += snprintf(buf + i, len - i, "_%08x%08x%08x", pad1, flag, pad2);
    assert(i < len, "path too long");
  }

  if (count != 1) {
    i += snprintf(buf + i, len - i, "-%llu", index);
    assert(i < len, "path too long");
  }

  if (eh)
    i += snprintf(buf + i, len - i, ".%s", eh);
  else
    i += snprintf(buf + i, len - i, ".%016llx", type);
  assert(i < len, "path too long");

  return i;
}

static uint64_t hex_field(const char *str, size_t len) {
  uint64_t r = 0;
  for (size_t i = 0; i < len; i++) {
    char c = str[i];
    if ('0' <= c && c <= '9')
      r = r << 4 | c - '0' + 0x0;
    if ('A' <= c && c <= 'F')
      r = r << 4 | c - 'A' + 0xA;
    if ('a' <= c && c <= 'f')
      r = r << 4 | c - 'a' + 0xa;
  }
  return r;
}

static uint64_t dec_field(const char *str, size_t len) {
  uint64_t r = 0;
  for (size_t i = 0; i < len; i++) {
    char c = str[i];
    if ('0' <= c && c <= '9')
      r = r * 10 + c - '0';
  }
  return r;
}

struct Name {
  uint64_t type, path;
};

static void unbundle(uint8_t **inflated, const char *outdir) {
  uint8_t *txt = inflated[0];
  uint32_t count = read_uint(&txt, 4);
  uint8_t *stuff = read_part(&txt, 256);
  auto names = (Name *)read_part(&txt, 16 * count);

  printf("%d file%s\n", count, (count != 1) ? "s" : "");
  for (uint32_t i = 0; i < count; i++) {

    uint64_t type = read_uint(&txt, 8);
    uint64_t path = read_uint(&txt, 8);
    uint32_t segs = read_uint(&txt, 4);
    uint32_t pad1 = read_uint(&txt, 4);
    uint8_t *head = read_part(&txt, segs * 12);

    assert(path == names[i].path && type == names[i].type,
           "%016llx == %016llx && %016llx == %016llx, %d", path, names[i].path,
           type, names[i].type, i);

    for (uint64_t j = 0; j < segs; j++) {
      uint32_t flag = read_uint(&head, 4);
      uint32_t size = read_uint(&head, 4);
      uint32_t pad2 = read_uint(&head, 4);
      uint8_t *file = read_part(&txt, size);

      char pathbuf[1000];
      build_path(pathbuf, sizeof(pathbuf), outdir, path, type, pad1, flag, pad2,
                 j, segs);

      int n = printf("%*u %s", ulog10(count) + 2, i, pathbuf);
      printf(" %*u bytes\n", 100 - n, size);
      uint8_t *fbuf[2] = {file, file + size};
      write_file(pathbuf, fbuf);
    }
  }
}

struct Seg {
  uint64_t type, path;
  uint32_t pad1, flag, pad2;
  size_t index;
  uint8_t *buf;
  size_t size;
  bool overwrite;

  bool operator<(Seg rhs) {
    if (type == rhs.type && path == rhs.path)
      return index < rhs.index;
    if (type == rhs.type)
      return path < rhs.path;
    return type < rhs.type;
  }
};

static void build_bundle(size_t content_size, std::vector<Seg> &seg, uint8_t **O) {
  /* collect files */

  std::sort(seg.begin(), seg.end());
  std::vector<size_t> files = {0};

  for (uint32_t i = 0; i < seg.size();) {
    uint64_t type = seg[i].type;
    uint64_t path = seg[i].path;

    while (i < seg.size() && seg[i].type == type && seg[i].path == path)
      i++;

    files.push_back(i);
  }

  assert(files.size() <= (1ull << 31), "%zu < 2^30", files.size());
  uint32_t count = files.size() - 1;
  printf("%u file%s\n", count, (count != 1) ? "s" : "");

  /* estimate size */

  const size_t header_size = 4 + 256;
  const size_t file_name_size = 8 + 8;
  const size_t file_header_size = 8 + 8 + 4 + 4;
  const size_t segment_header_size = 4 + 4 + 4;
  size_t size =
      header_size +
      count * (file_name_size + file_header_size + segment_header_size) +
      content_size;
  size += (uint16_t)-size;

  /* build bundle */

  uint8_t *txt = (uint8_t *)malloc(size);
  uint8_t *ptr = txt;

  write_uint(&ptr, 4, count);
  ptr += 256;

  for (size_t i = 0; i < count; i++) {
    write_uint(&ptr, 8, seg[files[i]].type);
    write_uint(&ptr, 8, seg[files[i]].path);
  }

  for (uint32_t i = 0; i < count; i++) {
    size_t start = files[i];
    size_t end = files[i + 1];
    size_t segs = end - start;
    uint64_t type = seg[start].type;
    uint64_t path = seg[start].path;
    uint32_t pad1 = seg[start].pad1;

    write_uint(&ptr, 8, type);
    write_uint(&ptr, 8, path);
    write_uint(&ptr, 4, segs);
    write_uint(&ptr, 4, pad1);

    for (size_t j = start; j < end; j++) {
      assert(seg[j].pad1 == pad1, "%u == %u", seg[j].pad1, pad1);
      write_uint(&ptr, 4, seg[j].flag);
      write_uint(&ptr, 4, seg[j].size);
      write_uint(&ptr, 4, seg[j].pad2);
    }

    for (size_t j = start; j < end; j++) {
      size_t f_size = seg[j].size;
      char pathbuf[1000];
      int n;

      build_path(pathbuf, sizeof(pathbuf), "", path, type, pad1, seg[j].flag,
                 seg[j].pad2, j, segs);
      n = printf("%*u %s %s", ulog10(count) + 2, i, pathbuf + 1,
                 seg[j].overwrite ? "[overwrite]" : "");
      printf(" %*zu bytes\n", 100 - n, f_size);

      write_part(&ptr, f_size, seg[j].buf);
    }
  }

  write_zero(&ptr, (uint16_t)(txt - ptr));

  size_t total = ptr - txt;
  O[0] = (uint8_t *)realloc(txt, total);
  O[1] = O[0] + size;
}

static void create_bundle(const char **names, const int namec, uint8_t **O) {
  /* read segments */

  size_t content_size = 0;
  std::vector<Seg> seg;

  for (int i = 0; i < namec; i++) {
    const char *path0 = path_segment(names[i], -1);
    const char *path1 = split(is_hex, path0);

    const char *pads0 = path1;
    const char *pads1 = path1;
    if (*pads0 == '_')
      pads1 = split(is_hex, ++pads0);

    const char *index0 = pads1;
    const char *index1 = pads1;
    if (*index0 == '-')
      index1 = split(is_digit, ++index0);

    if (*index1 != '.') {
      printf("skipping '%s'\n", names[i]);
      continue;
    }

    const char *type0 = index1 + 1;
    const char *type1 = split(is_hex, type0);
    const char *type2 = split(type0);

    if (path1 - path0 != 16) {
      printf("skipping '%s'\n", names[i]);
      continue;
    }
    if (pads1 != pads0 && pads1 - pads0 != 24) {
      printf("skipping '%s'\n", names[i]);
      continue;
    }

    uint64_t path = hex_field(path0, path1 - path0);
    uint32_t pad1 = pads0 == pads1 ? 0 : hex_field(pads0, 8);
    uint32_t flag = pads0 == pads1 ? 0 : hex_field(pads0 + 8, 8);
    uint32_t pad2 = pads0 == pads1 ? 0 : hex_field(pads0 + 16, 8);
    size_t index = index0 == index1 ? 0 : dec_field(index0, index1 - index0);

    uint64_t type = (type1 != type2 || type1 - type0 != 16 || in_dict(type0, type1 - type0)) ?
      murmur64(type0, type2 - type0) :
      hex_field(type0, type1 - type0);

    uint8_t *buf[2];
    read_file(names[i], buf);
    size_t size = buf[1] - buf[0];
    content_size += size;

    seg.push_back({type, path, pad1, flag, pad2, index, buf[0], size});

    if (0) {
      printlr(path0, path1);
      putchar(' ');
      printlr(pads0, pads1);
      putchar(' ');
      printlr(index0, index1);
      putchar(' ');
      printlr(type0, type2);
      putchar('\n');
      printf("%016llx %08x%08x%08x %zu %s\n", path, pad1, flag, pad2, index, demurmur64(type));
    }
  }

  build_bundle(content_size, seg, O);
}

static void rebundle(const char **file_paths, int namec, uint8_t **I, uint8_t **O) {
  /* read segments */

  size_t content_size = 0;
  std::vector<Seg> seg;

  for (int i = 0; i < namec; i++) {
    const char *path_hex_part = path_segment(file_paths[i], -1);
    const char *path_non_hex_part = split(is_hex, path_hex_part);

    const char *pads0 = path_non_hex_part;
    const char *pads1 = path_non_hex_part;
    if (*pads0 == '_')
      pads1 = split(is_hex, ++pads0);

    const char *index0 = pads1;
    const char *f_ext_str = pads1;
    if (*index0 == '-')
      f_ext_str = split(is_digit, ++index0);

    if (*f_ext_str != '.') {
      printf("file does not have a valid extension, skipping '%s'\n",
             file_paths[i]);
      continue;
    }

    const char *f_type = f_ext_str + 1;
    const char *type1 = split(is_hex, f_type);
    const char *type2 = split(f_type);

#define F_NAME_HASH_LEN 16
#define OLD_BUBBLE_HASH_LEN 18
    size_t hash_len = path_non_hex_part - path_hex_part;

    // compatibility with old bubble
    if (hash_len > 2 && hash_len == OLD_BUBBLE_HASH_LEN && path_hex_part[0] == '0' && path_hex_part[1] == '0')
      path_hex_part += 2;
    else if (hash_len != F_NAME_HASH_LEN) {
      printf("wrong hash size (%d expected, got %zu), skipping '%s'\n", F_NAME_HASH_LEN, hash_len, file_paths[i]);
      continue;
    }
#undef OLD_BUBBLE_HASH_LEN
#undef F_NAME_HASH_LEN

    if (pads1 != pads0 && pads1 - pads0 != 24) {
      printf("skipping '%s'\n", file_paths[i]);
      continue;
    }

    uint64_t path = hex_field(path_hex_part, path_non_hex_part - path_hex_part);
    uint32_t pad1 = pads0 == pads1 ? 0 : hex_field(pads0, 8);
    uint32_t flag = pads0 == pads1 ? 0 : hex_field(pads0 + 8, 8);
    uint32_t pad2 = pads0 == pads1 ? 0 : hex_field(pads0 + 16, 8);
    size_t index =
        index0 == f_ext_str ? 0 : dec_field(index0, f_ext_str - index0);

    uint64_t type = type1 != type2 || type1 - f_type != 16 ||
                            in_dict(f_type, type1 - f_type)
                        ? murmur64(f_type, type2 - f_type)
                        : hex_field(f_type, type1 - f_type);

    uint8_t *buf[2];
    read_file(file_paths[i], buf);
    size_t size = buf[1] - buf[0];
    content_size += size;

    seg.push_back({type, path, pad1, flag, pad2, index, buf[0], size, true});
  }

  /* collect old files */

  uint8_t *orig_txt = I[0];
  uint32_t orig_count = read_uint(&orig_txt, 4);
  uint8_t *stuff = read_part(&orig_txt, 256);
  auto names = (Name *)read_part(&orig_txt, 16 * orig_count);

  for (uint32_t i = 0; i < orig_count; i++) {
    uint64_t type = read_uint(&orig_txt, 8);
    uint64_t path = read_uint(&orig_txt, 8);
    uint32_t segs = read_uint(&orig_txt, 4);
    uint32_t pad1 = read_uint(&orig_txt, 4);
    uint8_t *head = read_part(&orig_txt, segs * 12);

    assert(path == names[i].path && type == names[i].type,
           "%016llx == %016llx && %016llx == %016llx, %d", path, names[i].path,
           type, names[i].type, i);

    for (uint64_t j = 0; j < segs; j++) {
      uint32_t flag = read_uint(&head, 4);
      uint32_t size = read_uint(&head, 4);
      uint32_t pad2 = read_uint(&head, 4);
      uint8_t *file = read_part(&orig_txt, size);
      uint8_t *fbuf[2] = {file, file + size};
      size_t index = j;

      bool file_present = false;

      for (const auto &segment : seg) {
        if (path == segment.path && pad1 == segment.pad1 && pad2 == segment.pad2 && type == segment.type) {
          file_present = true;
          break;
        }
      }

      if (file_present)
        continue;

      content_size += size;
      seg.push_back(
          {type, path, pad1, flag, pad2, index, fbuf[0], size, false});
    }
  }

  build_bundle(content_size, seg, O);
}

void print_usage() {
  printf("\n");
  printf("USAGE:\n");

  printf("  %-40s unbundle bundle into folder\n",
         "bubble U[options] bundle folder");

  printf("  %-40s rebundle files into bundle\n",
         "bubble R[options] reference_bundle output_bundle_path files...");
  printf("\n");

  printf("OPTIONS:\n");
  printf("  none :)\n");
  printf("\n");
}

int main(const int argc, const char *args[]) {
  uint8_t *deflated[2], *inflated[2], *rebundle_inflated[2], *temp[2];
  setbuf(stdout, nullptr);

  if (argc < 4) {
    print_usage();

    return 1;
  }

  const char *options = args[1];
  const char *bundle = args[2];

  if (*options == 'U') {
    const char *output = args[3];

    _mkdir(output);
    read_file(bundle, deflated);
    printf("\nunbundling '%s' ... ", bundle);
    inflate_bundle(deflated, inflated);
    unbundle(inflated, output);
    printf("done\n");
  }

  if (*options == 'R') {
    const char *output = args[3];

    if (argc < 5) {
      print_usage();

      return 1;
    }

    read_file(bundle, deflated);
    printf("\nreading '%s' ... ", bundle);
    inflate_bundle(deflated, inflated);
    printf("done");
    printf("\nrebundling %s to %s ...", bundle, output);
    rebundle(args + 4, argc - 4, inflated, rebundle_inflated);
    deflate_bundle(rebundle_inflated, deflated);
    write_file(output, deflated);
    printf("done\n");
  }

  if (*options == 'C') {
    printf("\ncreating %s ...", bundle);
    create_bundle(args + 3, argc - 3, inflated);
    deflate_bundle(inflated, deflated);
    write_file(bundle, deflated);
    printf("done\n");
  }

  return 0;
}
