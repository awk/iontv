#import "AtomicParsley.h"
#import "RSTranscodingAdditions.h"
#import "RSTranscoding.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"

@implementation RSTranscoding (MetaDataAdditions)

- (void)updateMetadata {
  const char *posixPath = [self.mediaFile UTF8String];
  
  APar_ScanAtoms(posixPath);
  
  if ( !APar_assert(metadata_style == ITUNES_STYLE, 1, "Using iTunes atoms") ) {
    return;
  }
  
  // Media type (TV vs Movie)
  uint8_t stik_value = 0;
  if (![self.schedule.program isMovie]) {
    // Additions to the iTunes library are movies by default
    stik_value = 10;
  }
  AtomicInfo* stikData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.stik.data", [self.schedule.program.programID UTF8String], AtomFlags_Data_UInt);
  APar_Unified_atom_Put(stikData_atom, NULL, UTF8_iTunesStyle_256glyphLimited, stik_value, 8);

  // Show name
  AtomicInfo* tvshownameData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.tvsh.data", [self.schedule.program.title UTF8String], AtomFlags_Data_Text);
  APar_Unified_atom_Put(tvshownameData_atom, [self.schedule.program.title UTF8String], UTF8_iTunesStyle_256glyphLimited, 0, 0);

  // Album Artist (used as part of the sorting/grouping in iTunes)
  AtomicInfo* albumartistData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.aART.data", [self.schedule.program.title UTF8String], AtomFlags_Data_Text);
  APar_Unified_atom_Put(albumartistData_atom, [self.schedule.program.title UTF8String], UTF8_iTunesStyle_256glyphLimited, 0, 0);

  // Artist (used as part of the sorting/grouping in iTunes)
  AtomicInfo* artistData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.""\xa9""ART.data", [self.schedule.program.title UTF8String], AtomFlags_Data_Text);
  APar_Unified_atom_Put(artistData_atom, [self.schedule.program.title UTF8String], UTF8_iTunesStyle_256glyphLimited, 0, 0);

  // Subtitle (episode name)
  if (self.schedule.program.subTitle != nil) {
    AtomicInfo* titleData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.\xa9nam.data", [self.schedule.program.subTitle UTF8String], AtomFlags_Data_Text);
    APar_Unified_atom_Put(titleData_atom, [self.schedule.program.subTitle UTF8String], UTF8_iTunesStyle_256glyphLimited, 0, 0);
  }

  // Description
  AtomicInfo* descriptionData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.desc.data", [self.schedule.program.descriptionStr UTF8String], AtomFlags_Data_Text);
  APar_Unified_atom_Put(descriptionData_atom, [self.schedule.program.descriptionStr UTF8String], UTF8_iTunesStyle_256glyphLimited, 0, 0);

  if (self.schedule.program.syndicatedEpisodeNumber) {
    // Episode ID
    AtomicInfo* tvepisodeData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.tven.data", [self.schedule.program.syndicatedEpisodeNumber UTF8String], AtomFlags_Data_Text);
    APar_Unified_atom_Put(tvepisodeData_atom, [self.schedule.program.syndicatedEpisodeNumber UTF8String], UTF8_iTunesStyle_256glyphLimited, 0, 0);

    int episodeID = [self.schedule.program.syndicatedEpisodeNumber intValue];
    if ((episodeID >= 100) && (episodeID < 99999)) {
      // Season Number
      AtomicInfo* tvseasonData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.tvsn.data", [self.schedule.program.syndicatedEpisodeNumber UTF8String], AtomFlags_Data_UInt);
      //season is [0, 0, 0, 0,   0, 0, 0, data_value]; BUT that first uint32_t is already accounted for in APar_MetaData_atom_Init
      APar_Unified_atom_Put(tvseasonData_atom, NULL, UTF8_iTunesStyle_256glyphLimited, 0, 16);
      APar_Unified_atom_Put(tvseasonData_atom, NULL, UTF8_iTunesStyle_256glyphLimited, episodeID / 100, 16);

      // Episode Number
      AtomicInfo* tvepisodenumData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.tves.data", [self.schedule.program.syndicatedEpisodeNumber UTF8String], AtomFlags_Data_UInt);
      //episodenumber is [0, 0, 0, 0,   0, 0, 0, data_value]; BUT that first uint32_t is already accounted for in APar_MetaData_atom_Init
      APar_Unified_atom_Put(tvepisodenumData_atom, NULL, UTF8_iTunesStyle_256glyphLimited, 0, 16);
      APar_Unified_atom_Put(tvepisodenumData_atom, NULL, UTF8_iTunesStyle_256glyphLimited,  episodeID % 100, 16);

      // 'Album' - really the collection name used for all episodes in the same season
      NSString *album = [NSString stringWithFormat:@"%@, Season %d", self.schedule.program.title, episodeID / 100];
      AtomicInfo* albumData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.""/xa9""alb.data", [album UTF8String], AtomFlags_Data_Text);
      APar_Unified_atom_Put(albumData_atom, [album UTF8String], UTF8_iTunesStyle_256glyphLimited, 0, 0);
    }
  }
  // Date
  NSCalendarDate *originalAirDate = [self.schedule.program.originalAirDate dateWithCalendarFormat:nil timeZone:nil];
  AtomicInfo* yearData_atom = APar_MetaData_atom_Init("moov.udta.meta.ilst.""\xa9""day.data", [[originalAirDate description] UTF8String], AtomFlags_Data_Text);
  APar_Unified_atom_Put(yearData_atom, [[originalAirDate description] UTF8String], UTF8_iTunesStyle_256glyphLimited, 0, 0);
  
  // Genre - 'gnre'
  Z2ITGenre *theGenre = [self.schedule.program genreWithRelevance:0];
  NSString *genreName = [[theGenre genreClass] valueForKey:@"name"];
  APar_MetaData_atomGenre_Set([genreName UTF8String]);
  
  // Atom "----" [com.apple.iTunes;iTunEXTC] contains: us-tv|TV-14|500|  - custom TV rating ? 
  
  // Write the updated atoms out to disk
  APar_DetermineAtomLengths();
  APar_OpenISOBaseMediaFile(posixPath, true);
  APar_WriteFile(posixPath, NULL, true);

	APar_FreeMemory();
}

@end
