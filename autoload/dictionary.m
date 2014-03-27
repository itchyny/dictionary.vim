// ============================================================================
// Filename: plugin/dictionary.m
// Version: 0.0
// Author: itchyny
// License: MIT License
// Last Change: 2014/03/27 20:58:41.
// ============================================================================

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

#define eq3(x,y)\
  (*((x)+i)==y[0] && *((x)+i+1)==y[1] && *((x)+i+2)==y[2])
#define isnum(x)\
  (('0' <= x && x <= '9'))
#define isalpha(x)\
  (('a' <= x && x <= 'z'))

NSString* dictionary(char* searchword) {
  NSString* word = [NSString stringWithUTF8String:searchword];
  return (NSString*)DCSCopyTextDefinition(NULL, (CFStringRef)word,
                                          CFRangeMake(0, [word length]));
}

NSString* suggest(char* w) {
#define SORTEDSIZE 200
#define WORDLENGTH 50
#define HEADARG 25
  char format[] = "look %s|head -n %d", command[512],
       format_[] = "look %c%c|grep '%s'|head -n %d",
       output[WORDLENGTH], *ptr, all[HEADARG][WORDLENGTH], *sorted[SORTEDSIZE];
  int length[HEADARG], i, j = 0;
  FILE* fp;
  NSString* result;
  if (w[0] == '^') sprintf(command, format_, w[1], w[4], w, HEADARG);
  else             sprintf(command, format, w, HEADARG);
  if ((fp = popen(command, "r")) == NULL) return nil;
  for (i = 0; i < HEADARG; ++i) { all[i][0] = '\0'; length[i] = 0; }
  for (i = 0; i < SORTEDSIZE; ++i) sorted[i] = NULL;
  while (fgets(output, WORDLENGTH, fp) != NULL) {
    if (j >= HEADARG) break;
    if (isalpha(output[0])) {
      strcpy(all[j], output);
      length[j] = strlen(all[j]);
      if ((ptr = strchr(all[j++], '\n')) != NULL) *ptr = '\0';
      else length[j - 1] = 0;
    }
  }
  pclose(fp); ptr = NULL;
  for (i = 0; i < j; ++i) {
    j = length[i] * 6 - 6;
    if (0 < j && j < SORTEDSIZE) {
      while (sorted[j] != NULL) ++j;
      sorted[j] = all[i];
      if (ptr == NULL) ptr = sorted[j];
    }
  }
  for (i = 0 ; i < SORTEDSIZE; ++i)
    if (sorted[i] != NULL && sorted[i][0] != '\0' &&
       (result = dictionary(sorted[i])) != nil) return result;
  return nil;
}

int main(int argc, char *argv[]) {
  if (argc < 2 || strlen(argv[1]) == 0) return 0;
  NSString* result = dictionary(argv[1]);
  if (result == nil) {
    int i, l;
    if ((l = strlen(argv[1])) > 100) return 0;
    for (i = 0; i < l; ++i)
      if (!isalpha(argv[1][i])) return 0;
    if ((result = suggest(argv[1])) == nil) {
      if (l < 3) return 0;
      int j; char s[l * 3 + 2]; s[0] = '^';
      for (i = j = 0; i < l; ++i) {
        s[++j] = argv[1][i]; s[++j] = '.'; s[++j] = '*';
      }
      s[++j] = '\0';
      if ((result = suggest(s)) == nil) return 0;
    }
  }
  char* r = (char*)[result UTF8String];
  int len = strlen(r);
  if (len < 1) return 0;
  char s[len * 2];
  int i, j;
  char nr1[] = { -30, -106, -72 };
  char nr2[] = { -30, -106, -74 };
  char nr3[] = { -30, -128, -94 };
  int num = 0, newnum = 0;
  char al = 'a';
  for (i = j = 0; i < len; ++i, ++j) {
    if (i + 3 < len && (eq3(r, nr1) || eq3(r, nr3))) {
      s[j] = '\n';
      s[++j] = ' ';
      s[++j] = ' ';
      s[++j] = r[i];
      s[++j] = r[i + 1];
      s[++j] = r[i + 2];
      i += 2;
    } else if (i + 3 < len && eq3(r, nr2)) {
      s[j] = '\n';
      i += 2;
    } else if (i + 3 < len && (r[i] == -30 && r[i + 1] == -111 && -97 < r[i + 2] && r[i + 2] < -76)) {
      s[j] = '\n';
      s[++j] = r[i];
      s[++j] = r[i + 1];
      s[++j] = r[i + 2];
      i += 2;
    } else if (i + 3 < len && !isalpha(r[i]) && isalpha(r[i + 1]) && r[i + 2] == '.') {
      if (r[i + 1] == al + 1 || r[i + 1] == 'a') {
        s[j++] = r[i];
        s[j++] = '\n';
        s[j] = ' ';
        al = r[i + 1];
      } else {
        s[j] = r[i];
      }
    } else if (strncmp((r + i), "DERIVATIVES", 11) == 0 ||
               strncmp((r + i), "PHRASES", 7) == 0 ||
               strncmp((r + i), "ORIGIN", 6) == 0) {
      s[j++] = '\n';
      s[j] = r[i];
    } else if (i + 3 < len && isnum(r[i]) && isnum(r[i + 1]) && r[i + 2] == ' ') {
      newnum = (r[i] - '0') * 10 + (r[i + 1] - '0');
      if (0 < newnum && (num < newnum || newnum < 2) && newnum <= num + 2) {
        s[j++] = '\n';
        s[j++] = r[i++];
        s[j] = r[i];
        num = newnum;
      } else {
        s[j] = r[i];
      }
    } else if (i + 2 < len && isnum(r[i]) && r[i + 1] == ' ') {
      newnum = r[i] - '0';
      if (0 < newnum && (num < newnum || newnum < 2) && newnum <= num + 2) {
        s[j++] = '\n';
        s[j] = r[i];
        num = newnum;
      } else {
        s[j] = r[i];
      }
    } else {
      s[j] = r[i];
    }
  }
  s[j] = '\0';
  printf("%s", s);
  return 0;
}
