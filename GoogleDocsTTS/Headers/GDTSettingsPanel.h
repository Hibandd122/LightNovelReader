#import <UIKit/UIKit.h>
#import "GDTStores.h"

NS_ASSUME_NONNULL_BEGIN

@interface GDTSettingsViewController : UITableViewController
- (instancetype)initWithStore:(id<GDTLibraryStore>)store;
@end

NS_ASSUME_NONNULL_END
