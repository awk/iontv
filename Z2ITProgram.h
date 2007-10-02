//
//  Z2ITProgram.h
//  recsched
//
//  Created by Andrew Kimpton on 1/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Z2ITLineup;
@class Z2ITSchedule;
@class Z2ITGenre;
@class Z2ITCrewMember;

@interface Z2ITProgram : NSManagedObject {

}

// Fetch the Program with the given ID from the Managed Object Context
+ (Z2ITProgram *) fetchProgramWithID:(NSString*)inProgramID;

// Fetch all the programs present with supplied IDs
+ (NSArray *) fetchProgramsWithIDS:(NSArray*)inProgramIDS;

- (void) addToSchedule:(Z2ITSchedule *)inSchedule;

- (void) addProductionCrewWithXMLElement:(NSXMLElement *)inXMLElement;
- (void) addGenreWithXMLElement:(NSXMLElement *)inXMLElement;
- (void) addScheduleWithXMLElement:(NSXMLElement *)inXMLElement;

- (void) initializeWithXMLElement:(NSXMLElement *)inXMLElement;

// Accessor and mutator for the Lineup ID attribute
- (NSString *)programID;
- (void)setProgramID:(NSString *)value;

// Accessor and mutator for the color code attribute
- (NSString *)colorCode;
- (void)setColorCode:(NSString *)value;

// Accessor and mutator for the description string attribute
- (NSString *)descriptionStr;
- (void)setDescriptionStr:(NSString *)value;

// Accessor and mutator for the MPAA Rating attribute
- (NSString *)mpaaRating;
- (void)setMpaaRating:(NSString *)value;

// Accessor and mutator for the original air date attribute
- (NSDate *)originalAirDate;
- (void)setOriginalAirDate:(NSDate *)value;

// Accessor and mutator for the type attribute
- (NSNumber *)runTimeHours;
- (void)setRunTimeHours:(NSNumber *)value;

// Accessor and mutator for the user lineup name attribute
- (NSNumber *)runTimeMinutes;
- (void)setRunTimeMinutes:(NSNumber *)value;

// Accessor and mutator for the series attribute
- (NSString *)series;
- (void)setSeries:(NSString *)value;

// Accessor and mutator for the show type attribute
- (NSString *)showType;
- (void)setShowType:(NSString *)value;

// Accessor and mutator for the star rating attribute
- (NSNumber *)starRating;
- (void)setStarRating:(NSNumber *)value;

// Accessor and mutator for the sub-title attribute
- (NSString *)subTitle;
- (void)setSubTitle:(NSString *)value;

// Accessor and mutator for the syndicated episode number attribute
- (NSString *)syndicatedEpisodeNumber;
- (void)setSyndicatedEpisodeNumber:(NSString *)value;

// Accessor and mutator for the title attribute
- (NSString *)title;
- (void)setTitle:(NSString *)value;

// Accessor and mutator for the year attribute
- (NSNumber *)year;
- (void)setYear:(NSNumber *)value;

// Accessor and mutator for the advisory attributes
- (NSSet *)advisories;
- (void)clearAdvisories;
- (void)addAdvisory:(NSString *)value;

// Accessor and mutator for the genres relationships
- (NSSet *)genres;
- (void)clearGenres;
- (void)addGenre:(Z2ITGenre *)value;

// Accessor and mutator for the crew member relationships
- (NSSet *)crewMembers;
- (void)clearCrewMembers;
- (void)addCrewMember:(Z2ITCrewMember *)value;

// Accessor and mutator for the schedules relationship
- (NSSet *)schedules;
@end

@interface Z2ITCrewMember : NSManagedObject {
};

// Accessor and mutator for the Role attribute
- (NSString *)roleName;
- (void)setRoleName:(NSString *)value;

// Accessor and mutator for the surname attribute
- (NSString *)surname;
- (void)setSurname:(NSString *)value;

// Accessor and mutator for the givenname attribute
- (NSString *)givenname;
- (void)setGivenname:(NSString *)value;

@end

@interface Z2ITGenre : NSManagedObject {
};

// Accessor and mutator for the Genre Class Name attribute
- (NSString *)genreClassName;
- (void)setGenreClassName:(NSString *)value;

// Accessor and mutator for the surname attribute
- (NSNumber *)relevance;
- (void)setRelevance:(NSNumber *)value;

@end
