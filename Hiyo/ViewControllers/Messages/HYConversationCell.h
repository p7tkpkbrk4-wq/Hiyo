#import <UIKit/UIKit.h>

@class HYConversation;

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const HYConversationCellDidTapDeleteNotification;

@interface HYConversationCell : UITableViewCell

@property (nonatomic, assign) NSInteger conversationIndex;

- (void)configWithConversation:(HYConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
