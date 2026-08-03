#import "GDTMiniPlayer.h"

@interface GDTMiniPlayerView ()
@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) UIProgressView *progressView;
@property(nonatomic) UIButton *playPauseButton;
@end

@implementation GDTMiniPlayerView
- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];
    if (self) {
        self.frame=frame; self.layer.cornerRadius=16; self.clipsToBounds=YES; self.accessibilityLabel=@"Text to speech mini player";
        _titleLabel=[UILabel new]; _titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]; _titleLabel.textColor=UIColor.labelColor; _titleLabel.numberOfLines=1; _titleLabel.accessibilityTraits=UIAccessibilityTraitStaticText;
        _progressView=[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault]; _progressView.progressTintColor=UIColor.systemBlueColor;
        _playPauseButton=[UIButton buttonWithType:UIButtonTypeSystem]; _playPauseButton.titleLabel.font=[UIFont systemFontOfSize:18 weight:UIFontWeightSemibold]; [_playPauseButton addTarget:self action:@selector(playPauseTapped) forControlEvents:UIControlEventTouchUpInside]; _playPauseButton.accessibilityLabel=@"Pause reading";
        UIButton *stop=[UIButton buttonWithType:UIButtonTypeSystem]; [stop setTitle:@"■" forState:UIControlStateNormal]; stop.titleLabel.font=[UIFont systemFontOfSize:16]; stop.accessibilityLabel=@"Stop reading"; [stop addTarget:self action:@selector(stopTapped) forControlEvents:UIControlEventTouchUpInside];
        UIButton *bookmark=[UIButton buttonWithType:UIButtonTypeSystem]; [bookmark setTitle:@"☆" forState:UIControlStateNormal]; bookmark.titleLabel.font=[UIFont systemFontOfSize:22]; bookmark.accessibilityLabel=@"Bookmark current position"; [bookmark addTarget:self action:@selector(bookmarkTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_titleLabel]; [self.contentView addSubview:_progressView]; [self.contentView addSubview:_playPauseButton]; [self.contentView addSubview:stop]; [self.contentView addSubview:bookmark];
        _titleLabel.translatesAutoresizingMaskIntoConstraints=NO; _progressView.translatesAutoresizingMaskIntoConstraints=NO; _playPauseButton.translatesAutoresizingMaskIntoConstraints=NO; stop.translatesAutoresizingMaskIntoConstraints=NO; bookmark.translatesAutoresizingMaskIntoConstraints=NO;
        [NSLayoutConstraint activateConstraints:@[[_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14],[_titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:7],[_titleLabel.trailingAnchor constraintEqualToAnchor:_playPauseButton.leadingAnchor constant:-8],[_progressView.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],[_progressView.trailingAnchor constraintEqualToAnchor:_titleLabel.trailingAnchor],[_progressView.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:6],[_playPauseButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],[_playPauseButton.widthAnchor constraintEqualToConstant:40],[stop.leadingAnchor constraintEqualToAnchor:_playPauseButton.trailingAnchor constant:2],[stop.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],[stop.widthAnchor constraintEqualToConstant:32],[bookmark.leadingAnchor constraintEqualToAnchor:stop.trailingAnchor constant:2],[bookmark.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8],[bookmark.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],[bookmark.widthAnchor constraintEqualToConstant:34]]];
    }
    return self;
}
- (void)setTitle:(NSString *)title { _title=[title copy]; self.titleLabel.text=_title.length?_title:@"Google Docs"; }
- (void)setProgress:(float)progress { _progress=MAX(0,MIN(progress,1)); self.progressView.progress=_progress; }
- (void)setPlaying:(BOOL)playing { _playing=playing; [self.playPauseButton setTitle:playing?@"Ⅱ":@"▶" forState:UIControlStateNormal]; self.playPauseButton.accessibilityLabel=playing?@"Pause reading":@"Resume reading"; }
- (void)playPauseTapped { if (self.playPauseAction) self.playPauseAction(); }
- (void)stopTapped { if (self.stopAction) self.stopAction(); }
- (void)bookmarkTapped { if (self.bookmarkAction) self.bookmarkAction(); }
@end
