// libRecSchedCommon - Common code shared between UI application and background server
// Copyright (C) 2007 Andrew Kimpton
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#import <CoreData/CoreData.h>

@class Z2ITLineup;
@class Z2ITSchedule;
@class Z2ITGenre;
@class Z2ITCrewMember;

@interface Z2ITProgram : NSManagedObject {

}

// Fetch the Program with the given ID from the Managed Object Context
+ (Z2ITProgram *) fetchProgramWithID:(NSString*)inProgramID inManagedObjectContext:(NSManagedObjectContext*)inMOC;

// Fetch all the programs present with supplied IDs
+ (NSArray *) fetchProgramsWithIDS:(NSArray*)inProgramIDS inManagedObjectContext:(NSManagedObjectContext*)inMOC;

- (void) addToSchedule:(Z2ITSchedule *)inSchedule;

- (void) addProductionCrewWithXMLElement:(NSXMLElement *)inXMLElement;
- (void) addGenreWithXMLElement:(NSXMLElement *)inXMLElement;
- (void) addScheduleWithXMLElement:(NSXMLElement *)inXMLElement;

- (void) initializeWithXMLElement:(NSXMLElement *)inXMLElement;

- (BOOL) isMovie;

- (void)addAdvisory:(NSString *)value;
- (Z2ITGenre*) genreWithRelevance:(int)inRelevance;

@property (retain) NSString * colorCode;
@property (retain) NSString * descriptionStr;
@property (retain) NSString * mpaaRating;
@property (retain) NSDate * originalAirDate;
@property (retain) NSString * programID;
@property (retain) NSNumber * runTimeHours;
@property (retain) NSNumber * runTimeMinutes;
@property (retain) NSString * series;
@property (retain) NSString * showType;
@property (retain) NSNumber * starRating;
@property (retain) NSString * subTitle;
@property (retain) NSString * syndicatedEpisodeNumber;
@property (retain) NSString * title;
@property (retain) NSNumber * year;
@property (retain) NSSet* advisories;
@property (retain) NSSet* crewMembers;
@property (retain) NSSet* genres;
@property (retain) NSSet* schedules;

@end

// coalesce these into one @interface Z2ITProgram (CoreDataGeneratedAccessors) section
@interface Z2ITProgram (CoreDataGeneratedAccessors)
- (void)addAdvisoriesObject:(NSManagedObject *)value;
- (void)removeAdvisoriesObject:(NSManagedObject *)value;
- (void)addAdvisories:(NSSet *)value;
- (void)removeAdvisories:(NSSet *)value;

- (void)addCrewMembersObject:(Z2ITCrewMember *)value;
- (void)removeCrewMembersObject:(Z2ITCrewMember *)value;
- (void)addCrewMembers:(NSSet *)value;
- (void)removeCrewMembers:(NSSet *)value;

- (void)addGenresObject:(Z2ITGenre *)value;
- (void)removeGenresObject:(Z2ITGenre *)value;
- (void)addGenres:(NSSet *)value;
- (void)removeGenres:(NSSet *)value;

- (void)addSchedulesObject:(Z2ITSchedule *)value;
- (void)removeSchedulesObject:(Z2ITSchedule *)value;
- (void)addSchedules:(NSSet *)value;
- (void)removeSchedules:(NSSet *)value;

@end

@interface Z2ITCrewMember : NSManagedObject {
};


// Fetch the CrewRole Object with the given string from the Managed Object Context
+ (NSManagedObject *) fetchCrewRoleWithName:(NSString*)inCrewRoleNameString inManagedObjectContext:(NSManagedObjectContext *)inMOC;

@property (retain) NSString * givenname;
@property (retain) NSString * surname;
@property (retain) Z2ITProgram * program;
@property (retain) NSManagedObject * role;

@end

// coalesce these into one @interface Z2ITCrewMember (CoreDataGeneratedAccessors) section
@interface Z2ITCrewMember (CoreDataGeneratedAccessors)
@end


@interface Z2ITGenre : NSManagedObject {
};

+ (Z2ITGenre *) createGenreWithClassName:(NSString*)inGenreClassNameString andRelevance:(NSNumber*)inRelevance inManagedObjectContext:(NSManagedObjectContext *)inMOC;
+ (Z2ITGenre *) fetchGenreWithClassName:(NSString*)inGenreClassNameString andRelevance:(NSNumber*)inRelevance inManagedObjectContext:(NSManagedObjectContext *)inMOC;

@property (retain) NSNumber * relevance;
@property (retain) NSManagedObject * genreClass;
@property (retain) NSSet* programs;

@end

// coalesce these into one @interface Z2ITGenre (CoreDataGeneratedAccessors) section
@interface Z2ITGenre (CoreDataGeneratedAccessors)
- (void)addProgramsObject:(Z2ITProgram *)value;
- (void)removeProgramsObject:(Z2ITProgram *)value;
- (void)addPrograms:(NSSet *)value;
- (void)removePrograms:(NSSet *)value;

@end
