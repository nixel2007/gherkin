#import "GHScenarioDefinition.h"

@class GHExamples;

@interface GHScenarioOutline : GHScenarioDefinition

@property (nonatomic, readonly) NSArray<GHExamples *> * examples;

- (id)initWithTags:(NSArray<GHTag *> *)theTags location:(GHLocation *)theLocation keyword:(NSString *)theKeyword name:(NSString *)theName description:(NSString *)theDescription steps:(NSArray<GHStep *> *)theSteps examples:(NSArray<GHExamples *> *)theExamples;

@end