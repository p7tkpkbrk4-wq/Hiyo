#import "HistoryViewController.h"
#import "HYColors.h"
#import <Masonry/Masonry.h>

@interface HistoryViewController ()

@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIImageView *emptyIcon;

@end

@implementation HistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"历史记录";
    self.view.backgroundColor = DarkBackground;
    [self setupUI];
}

- (void)setupUI {
    self.emptyIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"clock.fill"]];
    self.emptyIcon.tintColor = [UIColor systemGrayColor];
    self.emptyIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.emptyIcon];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"暂无历史记录";
    self.emptyLabel.font = [UIFont systemFontOfSize:16];
    self.emptyLabel.textColor = TextMuted;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.emptyLabel];

    [self.emptyIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(-30);
        make.width.height.equalTo(@60);
    }];

    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.emptyIcon.mas_bottom).offset(16);
    }];
}

@end
