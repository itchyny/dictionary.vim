#import <Foundation/Foundation.h>
#include <CoreServices/CoreServices.h>

#define substitute(s,x,y)\
  [s stringByReplacingOccurrencesOfString:x withString:y]

int main(int argc, char *argv[]) {
  NSString *word = [NSString stringWithUTF8String:argv[1]];
  NSString *result =
    (NSString *)DCSCopyTextDefinition(NULL, (CFStringRef)word,
                                           CFRangeMake(0, [word length]));
  result = substitute(result, @"\n(\n", @"(");
  result = substitute(result, @"\n) \n", @") ");
  result = substitute(result, @"\n;\n", @";");
  result = substitute(result, @"\n; \n", @"; ");
  result = substitute(result, @"\n.\n", @".\n");
  result = substitute(result, @"\n. \n", @".\n");
  result = substitute(result, @"\n,\n", @",");
  result = substitute(result, @"\n, \n", @",");
  result = substitute(result, @"\n, ", @", ");
  result = substitute(result, @"\n• ", @"");
  result = substitute(result, @"\n/", @"/");
  result = substitute(result, @"\n｟\n", @"｟");
  result = substitute(result, @"\n｠", @"｠");
  result = substitute(result, @"\n（\n", @"（");
  result = substitute(result, @"\n）", @"）");
  result = substitute(result, @"…\n", @"…");
  if (result != nil) puts([result UTF8String]);
  return 0;
}

