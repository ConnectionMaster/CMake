#include <OutDir.h>
#include <stdio.h>

int main(void)
{
  char const* files[] = { TESTC1_LIB, TESTC2_LIB, CONLY_EXE, 0 };
  int result = 0;
  char const** fname = files;
  for (; *fname; ++fname) {
    FILE* f = fopen(*fname, "rb");
    if (f) {
      printf("found: [%s]\n", *fname);
      fclose(f);
    } else {
      printf("error: [%s]\n", *fname);
      result = 1;
    }
  }
  return result;
}
