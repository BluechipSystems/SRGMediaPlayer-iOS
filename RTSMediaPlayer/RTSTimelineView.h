//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSTimelineEvent.h>
#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;
@protocol RTSTimelineViewDataSource;
@protocol RTSTimelineViewDelegate;

/**
 *  A view displaying events associated with a stream. The view is made of two parts:
 *
 *    - A scrollable area presenting each event with an associated cell
 *    - An overview showing where each event is located within the stream
 *
 *  As the user scrolls events, the overview highlights those events matching the visible cells above it.
 *
 *  To add a timeline to a custom player layout, simply drag and drop an RTSTimelineView onto the player layout,
 *  and bind its mediaPlayerController, dataSource and delegate outlets. Then implement the RTSTimelineViewDataSource
 *  and RTSTimelineViewDelegate protocols to supply the information required by the timeline.
 *
 *  The timeline itself does not implement any event retrieval mechanism. The responsibility of retrieving events
 *  is namely usually the responsibility of a parent view controller. For periodic update of the timeline, the
 *  RTSMediaPlayerController class offers an -addPlaybackTimeObserverForInterval:queue:usingBlock: method you
 *  can use, typically for calling a web service.
 *
 *  Customisation of timeline cells is achieved through subclassing of UICollectionViewCell, exactly like a usual 
 *  UICollectionView. Events are represented by the RTSTimelineEvent class, which only carries a position in time. If
 *  you need more information to be displayed on a cell (e.g. a title or a thumbnail), subclass RTSTimelineEvent to 
 *  add the data you need, and use this information when returning cells from your data source.
 */
@interface RTSTimelineView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

/**
 *  The current events displayed by the timeline. Setting this property triggers an update of the timeline
 */
@property (nonatomic) NSArray *events;

/**
 *  The width of cells within the timeline. Defaults to 60
 */
@property (nonatomic) CGFloat itemWidth;

/**
 * The spacing between cells in the timeline. Defaults to 4
 */
@property (nonatomic) CGFloat itemSpacing;

/**
 *  The media player controller to which the timeline is bound
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet UILabel *timeLeftValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

/**
 *  Register cell classes for reuse. Cells must be subclasses of UICollectionViewCell and can be instantiated either
 *  programmatically or using a nib. For more information about cell reuse, refer to UICollectionView documentation
 */
- (void) registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (void) registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

/**
 *  Dequeue a reusable cell for a given event
 *
 *  @param identifier The cell identifier (must be appropriately set for the cell)
 *  @param event      The event for which a cell must be dequeued
 */
- (id) dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forEvent:(RTSTimelineEvent *)event;

/**
 *  The timeline data source
 */
@property (nonatomic, weak) IBOutlet id<RTSTimelineViewDataSource> dataSource;

/**
 *  The timeline delegate
 */
@property (nonatomic, weak) IBOutlet id<RTSTimelineViewDelegate> delegate;

@end

/**
 *  Timeline data source protocol
 */
@protocol RTSTimelineViewDataSource <NSObject>

/**
 *  Return the cell to be displayed for an event. You should call -dequeueReusableCellWithReuseIdentifier:forEvent:
 *  within the implementation of this method to reuse existing cells and improve scrolling smoothness
 *
 *  @param timelineView The timeline
 *  @param event        The event for which the cell must be returned
 *
 *  @return The cell to use
 */
- (UICollectionViewCell *) timelineView:(RTSTimelineView *)timelineView cellForEvent:(RTSTimelineEvent *)event;

@optional

/**
 *  Return the icon to be displayed on the overview. If this method is not implemented, a white dot is displayed by
 *  default. Images should have the recommended size of 8x8 pixels
 *
 *  @param timelineView The timeline
 *  @param event        The event for which the icon must be returned
 *
 *  @return The image to use
 */
- (UIImage *) timelineView:(RTSTimelineView *)timelineView iconImageForEvent:(RTSTimelineEvent *)event;

@end

/**
 *  Timeline delegate protocol
 */
@protocol RTSTimelineViewDelegate <NSObject>

@optional

/**
 *  This method is called when the user taps on a cell. If the method is not implemented, the default action is to
 *  resume playback at the associated event location
 *
 *  @param timelineView The timeline
 *  @param event        The event which has been selected
 */
- (void) timelineView:(RTSTimelineView *)timelineView didSelectEvent:(RTSTimelineEvent *)event;

@end
