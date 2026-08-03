#import "GDTSettingsPanel.h"

@interface GDTSettingsViewController ()
@property(nonatomic, strong) id<GDTLibraryStore> store;
@property(nonatomic, strong) GDTSettings *settings;
@end

@implementation GDTSettingsViewController

- (instancetype)initWithStore:(id<GDTLibraryStore>)store {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _store = store;
        _settings = [store settings];
        self.title = @"Reading settings";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 4 : (section == 1 ? 3 : 5); }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @[@"Speech", @"Reading", @"Playback"][section]; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.section == 0 && indexPath.row < 3) {
        NSArray<NSString *> *labels = @[@"Speed", @"Pitch", @"Volume"];
        cell.textLabel.text = labels[indexPath.row];
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 180, 32)];
        if (indexPath.row == 0) { slider.minimumValue = 0.1f; slider.maximumValue = 1.0f; slider.value = self.settings.speed; [slider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged]; }
        if (indexPath.row == 1) { slider.minimumValue = 0.5f; slider.maximumValue = 2.0f; slider.value = self.settings.pitch; [slider addTarget:self action:@selector(pitchChanged:) forControlEvents:UIControlEventValueChanged]; }
        if (indexPath.row == 2) { slider.minimumValue = 0.0f; slider.maximumValue = 1.0f; slider.value = self.settings.volume; [slider addTarget:self action:@selector(volumeChanged:) forControlEvents:UIControlEventValueChanged]; }
        cell.accessoryView = slider;
    } else if (indexPath.section == 0) {
        cell.textLabel.text = @"Voice";
        cell.detailTextLabel.text = self.settings.voiceIdentifier.length ? self.settings.voiceIdentifier : @"System default";
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == 1) {
        cell.textLabel.text = indexPath.row == 0 ? @"Auto-scroll" : (indexPath.row == 1 ? @"Remember position" : @"Accessibility announcements");
        UISwitch *toggle = [UISwitch new];
        toggle.on = indexPath.row == 0 ? self.settings.autoScroll : (indexPath.row == 1 ? self.settings.rememberPosition : self.settings.accessibilityAnnouncements);
        toggle.tag = 100 + indexPath.row;
        [toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
    } else if (indexPath.row < 3) {
        cell.textLabel.text = @[@"Sentence highlight", @"Paragraph highlight", @"Word highlight"][indexPath.row];
        cell.accessoryType = self.settings.highlightMode == indexPath.row + 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else if (indexPath.row == 3) {
        cell.textLabel.text = @"Sleep timer";
        cell.detailTextLabel.text = self.settings.sleepTimer > 0 ? [NSString stringWithFormat:@"%.0f min", self.settings.sleepTimer / 60.0] : @"Off";
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.textLabel.text = @"Theme";
        cell.detailTextLabel.text = self.settings.theme.capitalizedString;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)speedChanged:(UISlider *)slider { self.settings.speed = slider.value; [self.store saveSettings:self.settings]; }
- (void)pitchChanged:(UISlider *)slider { self.settings.pitch = slider.value; [self.store saveSettings:self.settings]; }
- (void)volumeChanged:(UISlider *)slider { self.settings.volume = slider.value; [self.store saveSettings:self.settings]; }
- (void)toggleChanged:(UISwitch *)toggle { if (toggle.tag == 100) self.settings.autoScroll = toggle.isOn; else if (toggle.tag == 101) self.settings.rememberPosition = toggle.isOn; else self.settings.accessibilityAnnouncements = toggle.isOn; [self.store saveSettings:self.settings]; }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 3) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Voice identifier" message:@"Enter an AVSpeechSynthesisVoice identifier, or leave blank for automatic voice." preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.text = self.settings.voiceIdentifier; }];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { self.settings.voiceIdentifier = alert.textFields.firstObject.text ?: @""; [self.store saveSettings:self.settings]; [tableView reloadData]; }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (indexPath.section == 2 && indexPath.row < 3) {
        self.settings.highlightMode = indexPath.row + 1;
        [self.store saveSettings:self.settings];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
    } else if (indexPath.section == 2 && indexPath.row == 3) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sleep timer" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        for (NSNumber *minutes in @[@0, @15, @30, @60]) {
            NSString *title = minutes.integerValue ? [NSString stringWithFormat:@"%ld minutes", (long)minutes.integerValue] : @"Off";
            [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { self.settings.sleepTimer = minutes.doubleValue * 60.0; [self.store saveSettings:self.settings]; [tableView reloadData]; }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (indexPath.section == 2 && indexPath.row == 4) {
        UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Theme" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        for (NSString *theme in @[@"system", @"light", @"dark"]) { [alert addAction:[UIAlertAction actionWithTitle:theme.capitalizedString style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){ self.settings.theme=theme; [self.store saveSettings:self.settings]; [tableView reloadData]; }]]; }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

@end
