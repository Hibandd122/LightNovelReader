#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

NS_ASSUME_NONNULL_BEGIN

@interface GDTMiniPlayerView : UIVisualEffectView
@property(nonatomic, copy) NSString *title;
@property(nonatomic) float progress;
@property(nonatomic) BOOL playing;
@property(nonatomic, copy, nullable) dispatch_block_t playPauseAction;
@property(nonatomic, copy, nullable) dispatch_block_t stopAction;
@property(nonatomic, copy, nullable) dispatch_block_t bookmarkAction;
- (instancetype)initWithFrame:(CGRect)frame;
@end

NS_ASSUME_NONNULL_END
