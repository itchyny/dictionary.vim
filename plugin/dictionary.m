/* ============================================================================
 * Filename: plugin/dictionary.m
 * Version: 0.0
 * Author: itchyny
 * License: MIT License
 * Last Change: 2013/06/25 13:25:31.
 * ========================================================================= */

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

#define substitute(s,x,y)\
  [s stringByReplacingOccurrencesOfString:x withString:y]

#define eq3(x,y)\
  (*((x)+i+1)==y[0] && *((x)+i+2)==y[1] && *((x)+i+3)==y[2])
#define eq3neg(x,y)\
  (*((x)+j-1)==y[2] && *((x)+j-2)==y[1] && *((x)+j-3)==y[0])

int main(int argc, char *argv[]) {
  NSString *word = [NSString stringWithUTF8String:argv[1]];
  NSString *result =
    (NSString *)DCSCopyTextDefinition(NULL, (CFStringRef)word,
                                           CFRangeMake(0, [word length]));
  if (result == nil) return 1;
  char *r = (char*)[result UTF8String];
  int len = strlen(r);
  char s[len + 3];
  int i, j;
  char lparen1[] = { -17, -67, -97 }; /* "｟";  */
  char rparen1[] = { -17, -67, -96 }; /* "｠";  */
  char dquot[] = { -30, -128, -99 }; /* "”"; */
  char dots[] = { -30, -128, -90 }; /* "…"; */
  char lparen2[] = { -17, -68, -120 }; /* "（"; */
  char rparen2[] = { -17, -68, -119 }; /* "）"; */
  char lkakko[] = { -29, -128, -116 }; /* "「"; */
  char rkakko[] = { -29, -128, -115 }; /* "」"; */
  char dot[] =  { -30, -128, -94 }; /* "•"; */
  for (i = j = 0; i < len; ++i, ++j) {
    /* s[j] = r[i]; continue; */
    if (r[i] == '\n') {
      if (i + 3 < len) {
        if (r[i + 2] == '\n' && (r[i + 1] > 'Z' || r[i + 1] < 'A')) {
          s[j] = r[++i];
          if (r[i] == '/') ++i;
        } else if (r[i + 3] == '\n' && r[i + 2] == ' ') {
          if (r[i + 1] == ';' || r[i + 1] == ',') {
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
        } else if (eq3(r, rparen1)) {
          s[j] = r[++i]; s[++j] = r[++i]; s[++j] = r[++i];
          if (r[i + 1] == '\n') ++i;
        } else if (eq3(r, dquot)) {
          s[j] = r[++i]; s[++j] = r[++i]; s[++j] = r[++i];
        } else if (eq3(r, lparen2) || eq3(r, rparen2)) {
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

