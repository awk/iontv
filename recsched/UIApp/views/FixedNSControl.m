//
//  FixedNSControl.m
//
//  Credit goes to Mike Ash for this solution.
//  http://www.mikeash.com/blog/pivot/entry.php?id=17
//

#import "FixedNSControl.h"


@implementation FixedNSControl

+ (void)load {
  [self poseAsClass: [NSControl class]];
}

- initWithCoder:(NSCoder *)origCoder {
  BOOL sub = YES;

  sub = sub && [origCoder isKindOfClass: [NSKeyedUnarchiver class]]; // no support for 10.1 nibs
  sub = sub && ![self isMemberOfClass: [NSControl class]]; // no raw NSControls
  sub = sub && [[self superclass] cellClass] != nil; // need to have something to substitute

  // Find the ancestor whose name starts with "NS"
  // -- should end up at NSControl if nothing else.
  Class nsSuperclass = [self superclass];
  while (![NSStringFromClass(nsSuperclass) hasPrefix:@"NS"]) {
    nsSuperclass = [nsSuperclass superclass];
  }
  sub = sub && [nsSuperclass cellClass] != [[self class] cellClass]; // pointless if same

  // Fix for combo boxes.
  sub = sub && ([NSStringFromClass( [[self class] cellClass]) hasPrefix:@"NS"] == NO);

  if(!sub) {
    self = [super initWithCoder: origCoder];
  } else {
    NSKeyedUnarchiver *coder = (id)origCoder;

    // gather info about the superclass's cell and save the archiver's old mapping
    Class superCell = [nsSuperclass cellClass];
    NSString *oldClassName = NSStringFromClass( superCell );
    Class oldClass = [coder classForClassName: oldClassName];
    if( !oldClass ) {
      oldClass = superCell;
    }
    // override what comes out of the unarchiver
    [coder setClass: [[self class] cellClass] forClassName: oldClassName];

    // unarchive
    self = [super initWithCoder: coder];

    // set it back
    [coder setClass: oldClass forClassName: oldClassName];
  }

  return self;
}

@end
