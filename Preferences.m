//
//  Preferences.m
//  recsched
//
//  Created by Andrew Kimpton on 1/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"

const float kDurationSliderMinValue = 1.0;
const float kDurationSliderMaxValue = 772.0;
const int k1HourTick = 0;   // Tick mark indices are zero based
const int k3HourTick = 2;
const int k12HoursTick = 5;
const int k24HoursTick   = 9;   // 1 day
const int k168HoursTick = 15;   // 1 week
const int k336HoursTick = 17;   // 2 weeks

NSString *kZap2ItPreferencesToolbarIdentifier = @"Zap2It";
NSString *kTunersPreferencesToolbarIdentifier = @"Tuners";
NSString *kChannelsPreferencesToolbarIdentifier = @"Channels";

NSString *kScheduleDownloadDurationPrefStr = @"scheduleDownloadDuration";

struct discreteSliderMarks
{
  int tickMark;
  float timeValue;
};

const int kNumberDurationSliderTicks = 6;
struct discreteSliderMarks kDownloadDurationSliderMarks[] = { {0, 1.0}, {2, 3.0}, {5, 12.0}, {9, 24.0}, {15, 168.0}, {17, 336} };

// All NSToolbarItems have a unique identifer associated with them, used to tell your delegate/controller what 
// toolbar items to initialize and return at various points.  Typically, for a given identifier, you need to 
// generate a copy of your "master" toolbar item, and return it autoreleased.  The function below takes an
// NSMutableDictionary to hold your master NSToolbarItems and a bunch of NSToolbarItem paramenters,
// and it creates a new NSToolbarItem with those parameters, adding it to the dictionary.  Then the dictionary
// can be used from -toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar: to generate a new copy of the 
// requested NSToolbarItem (when the toolbar wants to redraw, for instance) by simply duplicating and returning
// the NSToolbarItem that has the same identifier in the dictionary.  Plus, it's easy to call this function
// repeatedly to generate lots of NSToolbarItems for your toolbar.
// -------
// label, palettelabel, toolTip, action, and menu can all be NULL, depending upon what you want the item to do
static void addToolbarItem(NSMutableDictionary *theDict,NSString *identifier,NSString *label,NSString *paletteLabel,NSString *toolTip,id target,SEL settingSelector, id itemContent,SEL action, NSMenu * menu)
{
    NSMenuItem *mItem;
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    // the settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
    // one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
    // (in the itemContent parameter).  Then this next line will do the right thing automatically.
    [item performSelector:settingSelector withObject:itemContent];
    [item setAction:action];
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
    // we set it up here.  Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
    // so we create a dummy NSMenuItem that has our real menu as a submenu.
    if (menu!=NULL)
    {
	// we actually need an NSMenuItem here, so we construct one
	mItem=[[[NSMenuItem alloc] init] autorelease];
	[mItem setSubmenu: menu];
	[mItem setTitle: [menu title]];
	[item setMenuFormRepresentation:mItem];
    }
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
}


@implementation Preferences

static Preferences *sSharedInstance = nil;

+ (Preferences *)sharedInstance {
    return sSharedInstance ? sSharedInstance : [[self alloc] init];
}

+ (void)setupDefaults
{
    NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
    NSDictionary *initialValuesDict;
    NSArray *resettableUserDefaultsKeys;
    
    // load the default values for the user defaults
    userDefaultsValuesPath=[[NSBundle mainBundle] pathForResource:@"UserDefaults" 
                               ofType:@"plist"];
    userDefaultsValuesDict=[NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
    
    // if your application supports resetting a subset of the defaults to 
    // factory values, you should set those values 
    // in the shared user defaults controller
    resettableUserDefaultsKeys=[NSArray arrayWithObjects:kScheduleDownloadDurationPrefStr,nil];
    initialValuesDict=[userDefaultsValuesDict dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
    
    // Set the initial values in the shared user defaults controller 
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
}

- (id)init
{
    if (sSharedInstance)
    {		// We just have one instance of the Preferences class, return that one instead
        [self release];
    }
    else if (self = [super init])
    {
        sSharedInstance = self;
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.scheduleDownloadDuration" options:NSKeyValueObservingOptionNew context:nil];
    }
    return sSharedInstance;
}

- (void)dealloc
{
    if (self != sSharedInstance)
      [super dealloc];	// Don't free the shared instance
}

// When we launch, we have to get our NSToolbar set up.  This involves creating a new one, adding the NSToolbarItems,
// and installing the toolbar in our window.
-(void)awakeFromNib
{
//    NSFont *theFont;
    NSToolbar *toolbar=[[[NSToolbar alloc] initWithIdentifier:@"myToolbar"] autorelease];
    
    // Here we create the dictionary to hold all of our "master" NSToolbarItems.
    mToolbarItems=[[NSMutableDictionary dictionary] retain];

    // often using an image will be your standard case.  You'll notice that a selector is passed
    // for the action (blueText:), which will be called when the image-containing toolbar item is clicked.
    addToolbarItem(mToolbarItems,kZap2ItPreferencesToolbarIdentifier,@"Zap2It",@"Zap2It",@"Zap2It User ID & Schedule",self,@selector(setImage:), nil /* image */,@selector(showZap2ItPrefs:),NULL);
    addToolbarItem(mToolbarItems,kTunersPreferencesToolbarIdentifier,@"Tuner",@"Tuner",@"Tuner Selection",self,@selector(setImage:), nil /* image */,@selector(showTunerPrefs:),NULL);
    addToolbarItem(mToolbarItems,kChannelsPreferencesToolbarIdentifier,@"Channels",@"Channels",@"Customize Channels you recieve",self,@selector(setImage:), nil /* image */,@selector(showChannelPrefs:),NULL);
     
    // the toolbar wants to know who is going to handle processing of NSToolbarItems for it.  This controller will.
    [toolbar setDelegate:self];
    // If you pass NO here, you turn off the customization palette.  The palette is normally handled automatically
    // for you by NSWindow's -runToolbarCustomizationPalette: method; you'll notice that the "Customize Toolbar"
    // menu item is hooked up to that method in Interface Builder.  Interface Builder currently doesn't automatically 
    // show this action (or the -toggleToolbarShown: action) for First Responder/NSWindow (this is a bug), so you 
    // have to manually add those methods to the First Responder in Interface Builder (by hitting return on the First Responder and 
    // adding the new actions in the usual way) if you want to wire up menus to them.
    [toolbar setAllowsUserCustomization:YES];

    // tell the toolbar that it should save any configuration changes to user defaults.  ie. mode changes, or reordering will persist. 
    // specifically they will be written in the app domain using the toolbar identifier as the key. 
    [toolbar setAutosavesConfiguration: YES]; 
    
    // tell the toolbar to show icons only by default
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    // install the toolbar.
    [mPanel setToolbar:toolbar];
}

- (void)showPanel:(id)sender
{
    if (!mPanel) {
        if (![NSBundle loadNibNamed:@"Preferences" owner:self]) 
        {
            NSLog(@"Failed to load Preferences.nib");
            NSBeep();
            return;
        }
	[mPanel setHidesOnDeactivate:NO];
	[mPanel setExcludedFromWindowsMenu:YES];
	[mPanel setMenu:nil];
        [self updateUI];
        [mPanel center];
    }
    [mPanel makeKeyAndOrderFront:nil];
}

- (void)updateUI
{
  [mDurationTextField setHidden:YES];
        
        // Now update the slider position for the default value
        float currDuration = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kScheduleDownloadDurationPrefStr] floatValue];
        float newSliderValue = 0.0;
        int i=0;
        for (i=1; i < kNumberDurationSliderTicks; i++)
        {
          if (currDuration <= kDownloadDurationSliderMarks[i].timeValue)
          {
            newSliderValue = (currDuration - kDownloadDurationSliderMarks[i-1].timeValue)  / 
              ( kDownloadDurationSliderMarks[i].timeValue - kDownloadDurationSliderMarks[i-1].timeValue) 
              * ([mDurationSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i].tickMark] - [mDurationSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i-1].tickMark])
                + [mDurationSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i-1].tickMark];
            break;
          }
        }
        if (newSliderValue >= 0.0)
          [mDurationSlider setDoubleValue:newSliderValue];
}

- (void) updateDurationLabel
{
  float newDuration = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kScheduleDownloadDurationPrefStr] floatValue];
  if (newDuration < 24.0)
    [mDurationTextField setStringValue:[NSString stringWithFormat:@"%d Hours", (int)(newDuration + 0.5f)]];
  else if (newDuration < 169)
    [mDurationTextField setStringValue:[NSString stringWithFormat:@"%d Days", (int)((newDuration / 24.0f) + 0.5f)]];
  else
    [mDurationTextField setStringValue:[NSString stringWithFormat:@"%.1f Weeks", (newDuration / 168.0f)]];
}

- (IBAction) durationSliderChanged:(NSSlider *)inSlider
{
  float newSliderValue = [inSlider floatValue];
  float newDuration = 1.0f;
  int i=0;
  
  // Run through the list of tick marks and time values scale the duration between the nearest two tick marks.
  for (i=1; i < kNumberDurationSliderTicks; i++)
  {
    if (newSliderValue <= [inSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i].tickMark])
    {
        newDuration = kDownloadDurationSliderMarks[i-1].timeValue + (newSliderValue - [inSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i-1].tickMark]) / ([inSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i].tickMark] - [inSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i-1].tickMark]) * (kDownloadDurationSliderMarks[i].timeValue - kDownloadDurationSliderMarks[i-1].timeValue);
        break;
    }
  }
  
  NSUserDefaultsController *theController = [NSUserDefaultsController sharedUserDefaultsController];
  [[theController values] setValue:[NSNumber numberWithFloat:newDuration] forKey:kScheduleDownloadDurationPrefStr];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == [NSUserDefaultsController sharedUserDefaultsController]) && ([keyPath isEqual:@"values.scheduleDownloadDuration"]))
    {
      [self updateDurationLabel];
    }
}

- (void) showZap2ItPrefs:(id)sender
{
	NSLog(@"Show Zap2It Preferences");
}

- (void) showTunerPrefs:(id)sender
{
	NSLog(@"Show Tuner Preferences");
}

- (void) showChannelPrefs:(id)sender
{
	NSLog(@"Show Channel Preferences");
}

#pragma mark - Toolbar Delegates

// This method is required of NSToolbar delegates.  It takes an identifier, and returns the matching NSToolbarItem.
// It also takes a parameter telling whether this toolbar item is going into an actual toolbar, or whether it's
// going to be displayed in a customization palette.
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    NSToolbarItem *newItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    NSToolbarItem *item=[mToolbarItems objectForKey:itemIdentifier];
    
    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=NULL)
    {
		[newItem setView:[item view]];
    }
    else
    {
		[newItem setImage:[item image]];
    }
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view]!=NULL)
    {
		[newItem setMinSize:[[item view] bounds].size];
		[newItem setMaxSize:[[item view] bounds].size];
    }

    return newItem;
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
// set of toolbar items.  It can also be called by the customization palette to display the default toolbar.    
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:kZap2ItPreferencesToolbarIdentifier, kTunersPreferencesToolbarIdentifier, kChannelsPreferencesToolbarIdentifier,nil];
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
// toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:kZap2ItPreferencesToolbarIdentifier, kTunersPreferencesToolbarIdentifier, kChannelsPreferencesToolbarIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,NSToolbarFlexibleSpaceItemIdentifier,nil];
}


@end
