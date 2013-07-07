// ============================================================================
// Filename: plugin/dictionary.m
// Version: 0.0
// Author: itchyny
// License: MIT License
// Last Change: 2013/07/07 10:37:33.
// ============================================================================

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

#define eq3(x,y)\
  (*((x)+i+1)==y[0] && *((x)+i+2)==y[1] && *((x)+i+3)==y[2])
#define eq3neg(x,y)\
  (*((x)+j-1)==y[2] && *((x)+j-2)==y[1] && *((x)+j-3)==y[0])

NSString* dictionary(char* searchword) {
  NSString* word = [NSString stringWithUTF8String:searchword];
  NSString* result =
    (NSString*)DCSCopyTextDefinition(NULL, (CFStringRef)word,
                                           CFRangeMake(0, [word length]));
  return result;
}

NSString* suggest(char* w) {
#define SORTEDSIZE 200
#define WORDLENGTH 50
#define HEADARG 25
  char format[512] = "look %s|head -n %d", command[512],
       format_[512] = "look %c%c|grep '%s'|head -n %d",
       output[WORDLENGTH], *ptr, all[HEADARG][WORDLENGTH], *sorted[SORTEDSIZE];
  int length[HEADARG], i = 0, j = 0;
  FILE* fp;
  NSString* result;
  if (w[0] == '^') sprintf(command, format_, w[1], w[4], w, HEADARG);
  else             sprintf(command, format, w, HEADARG);
  if ((fp = popen(command, "r")) == NULL) return nil;
  for (i = 0; i < HEADARG; ++i) { all[i][0] = '\0'; length[i] = 0; }
  for (i = 0; i < SORTEDSIZE; ++i) sorted[i] = NULL;
  while (fgets(output, WORDLENGTH, fp) != NULL) {
    if (j >= 30) break;
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
  char s[len + 3];
  int i, j;
  char lparen1[] = { -17, -67, -97 }; /* "｟";  */
  char rparen1[] = { -17, -67, -96 }; /* "｠";  */
  char dquot[] = { -30, -128, -99 }; /* "”"; */
  char dots[] = { -30, -128, -90 }; /* "…"; */
  char lparen2[] = { -17, -68, -120 }; /* "（"; */
  char rparen2[] = { -17, -68, -119 }; /* "）"; */
  char lparen3[] = { -29, -128, -104 }; /* "〘"; */
  char rparen3[] = { -29, -128, -103 }; /* "〙"; */
  char lkakko[] = { -29, -128, -116 }; /* "「"; */
  char rkakko[] = { -29, -128, -115 }; /* "」"; */
  char dot[] =  { -30, -128, -94 }; /* "•"; */
  char huku[] =  { -24, -92, -121 }; /* "複"; */
  char nami[] =  { -17, -67, -98 }; /* "〜"; */
  for (i = j = 0; i < len; ++i, ++j) {
    /* s[j] = r[i]; continue; */
    if (r[i] == '\n') {
      if (i + 3 < len) {
        if (r[i + 2] == '\n' && (r[i + 1] > 'Z' || r[i + 1] < 'A')) {
          s[j] = r[++i];
          if (r[i] == '/') ++i;
        } else if (r[i + 1] == '/') {
          s[j] = ' ';
          s[++j] = r[++i];
        } else if (r[i + 3] == '\n' && r[i + 2] == ' ') {
          if (r[i + 1] == ';' || r[i + 1] == ',' || r[i + 1] == ')') {
            s[j] = r[++i];
            s[++j] = r[++i];
          } else if (r[i + 1] == '.') {
            s[j] = r[++i];
            s[++j] = r[++i];
            s[++j] = r[++i];
          } else {
            s[j] = r[i];
          }
        } else if (eq3(r, lparen1) && r[i + 4] == '\n' &&
            !(j > 2 && s[j - 1] == ' ' && '0' < s[j - 2] && s[j - 2] <= '9')) {
          s[j] = r[++i]; s[++j] = r[++i]; s[++j] = r[++i]; ++i;
        } else if (eq3(r, dquot)) {
          s[j] = r[++i]; s[++j] = r[++i]; s[++j] = r[++i];
        } else if (eq3(r, lparen2) || eq3(r, rparen2) || eq3(r, rparen1)) {
          s[j] = r[++i]; s[++j] = r[++i]; s[++j] = r[++i];
          if (r[i + 1] == '\n') ++i;
        } else if ((eq3(r, lparen3) || eq3(r, rparen3)) && j > 2 &&
                  !(s[j - 1] >= 'A' && s[j - 1] <= 'Z' && s[j - 2] == '\n') &&
                  !(s[j - 1] == ' ' && s[j - 2] >= '0' && s[j - 2] <= '9')) {
          s[j] = r[++i]; s[++j] = r[++i]; s[++j] = r[++i];
          if (r[i + 1] == '\n') ++i;
        } else if (eq3(r, lkakko) && eq3(r + 3, rkakko)) {
          i += 6; --j;
        } else if (j > 2 && s[j - 1] == ' ' && 
            (s[j - 2] == ',' || (s[j - 2] == ';' && s[j - 3] != '/')) &&
            !(r[i + 1] >= 'A' && r[i + 1] <= 'Z' && r[i + 2] == '\n')) {
          --j;
        } else if (j > 3 && (eq3neg(s, dots) || eq3neg(s, rparen2))) {
          --j;
        } else if (r[i + 1] == ',' && r[i + 2] == ' ') {
          s[j] = r[++i]; s[++j] = r[++i];
        } else if (eq3(r, dot)) {
          if (r[i + 4] == ' ' && r[i + 5] == '\n') ++i;
          i += 3; --j;
        } else if (eq3(r, huku) && r[i + 4] == '\n' &&
                  (eq3(r + 4, nami) || r[i + 5] == '-')) {
          s[j] = r[i]; s[++j] = r[++i]; s[++j] = r[++i]; s[++j] = r[++i];
          s[++j] = ' '; ++i;
        } else if ((r[i + 1] == 'U' || r[i + 1] == 'C') && r[i + 2] == '\n'
                && (r[i + 3] == 'U' || r[i + 3] == 'C') && r[i + 4] == '\n') {
          s[j] = r[i]; s[++j] = r[++i]; s[++j] = ' '; ++i; s[++j] = r[++i];
        } else if (s[j - 1] == '(') {
          --j;
        } else if (r[i + 1] == ')') {
          s[j] = r[++i];
        } else {
          s[j] = r[i];
        }
      } else if (i + 3 >= len) {
        s[j] = r[++i];
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

