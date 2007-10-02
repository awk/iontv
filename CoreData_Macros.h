/*
 *  CoreData_Macros.h
 *  recsched
 *
 *  Created by Andrew Kimpton on 1/20/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#define COREDATA_ACCESSOR(ATTRIB_TYPE, ENTITY_ATTRIB) \
    ATTRIB_TYPE tmpValue; \
    [self willAccessValueForKey: ENTITY_ATTRIB]; \
    tmpValue = [self primitiveValueForKey: ENTITY_ATTRIB];\
    [self didAccessValueForKey: ENTITY_ATTRIB];\
    return tmpValue;

#define COREDATA_MUTATOR(ATTRIB_TYPE, ENTITY_ATTRIB) \
    [self willChangeValueForKey: ENTITY_ATTRIB]; \
    [self setPrimitiveValue: value forKey: ENTITY_ATTRIB]; \
    [self didChangeValueForKey: ENTITY_ATTRIB]; 

#define COREDATA_BOOL_ACCESSOR(ENTITY_ATTRIB) \
    NSNumber *tmpValue; \
    [self willAccessValueForKey: ENTITY_ATTRIB]; \
    tmpValue = [self primitiveValueForKey: ENTITY_ATTRIB];\
    [self didAccessValueForKey: ENTITY_ATTRIB];\
    if (tmpValue) \
      return [tmpValue boolValue]; \
    else \
      return NO;

#define COREDATA_BOOL_MUTATOR(ENTITY_ATTRIB) \
    [self willChangeValueForKey: ENTITY_ATTRIB]; \
    [self setPrimitiveValue:[NSNumber numberWithBool:value] forKey: ENTITY_ATTRIB]; \
    [self didChangeValueForKey: ENTITY_ATTRIB]; 

