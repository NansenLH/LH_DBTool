#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "LH_DBCore.h"
#import "LH_DBObjectProtocol.h"
#import "LH_DBTool.h"

FOUNDATION_EXPORT double LH_DBToolVersionNumber;
FOUNDATION_EXPORT const unsigned char LH_DBToolVersionString[];

