#import <UIKit/UIKit.h>

@interface SBIconView : UIView
@property (nonatomic, readonly) NSString *applicationBundleIdentifierForShortcuts;
@end

@interface SBSApplicationShortcutItem : NSObject
@property (nonatomic, strong) NSString *localizedTitle;
@property (nonatomic, strong) NSString *type;
@end

@interface LSApplicationProxy : NSObject
+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)identifier;
@property (nonatomic, strong) NSNumber *itemID;
@end

%hook SBIconView

-(NSArray *)applicationShortcutItems {
    LSApplicationProxy *proxy = [LSApplicationProxy applicationProxyForIdentifier:self.applicationBundleIdentifierForShortcuts];
    if (![proxy respondsToSelector:@selector(itemID)] || [proxy.itemID integerValue] == 0) {
        return %orig;
    }

    NSMutableArray *items = [%orig mutableCopy];
    if (!items) items = [NSMutableArray new];

    SBSApplicationShortcutItem *appStoreItem = [[%c(SBSApplicationShortcutItem) alloc] init];
    appStoreItem.localizedTitle = @"Open in App Store";
    appStoreItem.type = @"StoreMenuItem";
    [items addObject:appStoreItem];

    return items;
}

+(void)activateShortcut:(SBSApplicationShortcutItem *)item withBundleIdentifier:(NSString *)bundleIdentifier forIconView:(id)arg3 {
    if ([item.type isEqualToString:@"StoreMenuItem"]) {
        [[%c(UIApplication) sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://apps.apple.com/app/id%@" ,[LSApplicationProxy applicationProxyForIdentifier:bundleIdentifier].itemID]] options:@{} completionHandler:nil];
        return;
    }
    %orig;
}

%end

%hook _UIContextMenuActionView

-(id)initWithTitle:(NSString *)title subtitle:(id)arg2 image:(UIImage *)image {
    if ([title isEqualToString:@"Open in App Store"]) {
        image = [[UIImage imageNamed:@"AppStoreButton" inBundle:[NSBundle bundleWithPath:@"/Library/Application Support/StoreMenu"] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return %orig;
}

%end

%ctor {
    %init;
}
