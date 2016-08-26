//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAirplayOverlayView.h"

#import "NSBundle+SRGMediaPlayer.h"

@interface SRGAirplayOverlayView ()

@property (nonatomic) MPVolumeView *volumeView;

@end

static const CGFloat RTSAirplayOverlayViewDefaultFillFactor = 0.6f;

static void commonInit(SRGAirplayOverlayView *self);

@implementation SRGAirplayOverlayView

#pragma mark Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.autoresizesSubviews = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor clearColor];
        commonInit(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

- (void)setFillFactor:(CGFloat)fillFactor
{
    if (fillFactor <= 0.f) {
        _fillFactor = RTSAirplayOverlayViewDefaultFillFactor;
    }
    else if (fillFactor > 1.f) {
        _fillFactor = 1.f;
    }
    else {
        _fillFactor = fillFactor;
    }

    [self setNeedsDisplay];
}

- (NSString *)activeAirplayOutputRouteName
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
    
    for (AVAudioSessionPortDescription *outputPort in currentRoute.outputs) {
        if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay]) {
            return outputPort.portName;
        }
    }
    
    return RTSMediaPlayerLocalizedString(@"External device", nil);
}

#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{
    CGFloat width, height;
    CGFloat stringRectHeight = 30.f;
    CGFloat stringRectMargin = 5.f;
    CGFloat lineWidth = 4.f;
    CGFloat shapeSeparatorDelta = 5.f;
    CGFloat quadCurveHeight = 20.f;

    CGFloat maxWidth = CGRectGetWidth(self.bounds) * self.fillFactor - 2.f * lineWidth;
    CGFloat maxHeight = CGRectGetHeight(self.bounds) * self.fillFactor - stringRectHeight - quadCurveHeight - shapeSeparatorDelta - 10.f;
    CGFloat aspectRatio = 16.f / 10.f;

    if (maxWidth < maxHeight * aspectRatio) {
        width = maxWidth;
        height = width / aspectRatio;
    }
    else {
        height = maxHeight;
        width = height * aspectRatio;
    }

    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetAllowsAntialiasing(context, YES);

    CGContextSetLineWidth(context, 4.f);
    CGContextSetStrokeColorWithColor(context, self.tintColor.CGColor);

    CGRect rectangle = CGRectMake(midX - width / 2.f, midY - height / 2.f, width, height);
    CGContextAddRect(context, rectangle);
    CGContextStrokePath(context);

    CGContextMoveToPoint(context, midX - width / 4.f, midY + height / 2.f + shapeSeparatorDelta);
    CGContextAddQuadCurveToPoint(context, midX, midY + height / 2.f + quadCurveHeight, midX + width / 4.f, midY + height / 2.f + shapeSeparatorDelta);
    CGContextSetFillColorWithColor(context, self.tintColor.CGColor);
    CGContextFillPath(context);

    CGRect titleRect = CGRectInset(rectangle, 8.f, 10.f);
    [self drawTitleInRect:titleRect];

    CGRect subtitleRect = CGRectMake(stringRectMargin, midY + height / 2.f + quadCurveHeight - 5.f, CGRectGetMaxX(rect) - 2.f * stringRectMargin, stringRectHeight);
    [self drawSubtitleInRect:subtitleRect];
}

- (void)drawTitleInRect:(CGRect)rect
{
    NSDictionary *attributes = [self airplayOverlayViewTitleAttributedDictionary:self];
    if ([self.dataSource respondsToSelector:@selector(airplayOverlayViewTitleAttributedDictionary:)]) {
        attributes = [self.dataSource airplayOverlayViewTitleAttributedDictionary:self];
    }

    NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];

    NSString *title = @"Airplay";
    [title drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:drawingContext];
}

- (void)drawSubtitleInRect:(CGRect)rect
{
    NSString *routeName = [self activeAirplayOutputRouteName];

    NSString *subtitle = [self airplayOverlayView:self subtitleForAirplayRouteName:routeName];
    if ([self.dataSource respondsToSelector:@selector(airplayOverlayView:subtitleForAirplayRouteName:)]) {
        subtitle = [self.dataSource airplayOverlayView:self subtitleForAirplayRouteName:routeName];
    }

    if (subtitle.length > 0) {
        NSDictionary *attributes = [self airplayOverlayViewSubtitleAttributedDictionary:self];
        if ([self.dataSource respondsToSelector:@selector(airplayOverlayViewSubtitleAttributedDictionary:)]) {
            attributes = [self.dataSource airplayOverlayViewSubtitleAttributedDictionary:self];
        }

        NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
        drawingContext.minimumScaleFactor = 3.f / 4.f;

        [subtitle drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:drawingContext];
    }
}

#pragma mark RTSAirplayOverlayViewDataSource protocol

- (NSDictionary *)airplayOverlayViewTitleAttributedDictionary:(SRGAirplayOverlayView *)airplayOverlayView
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;

    return @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:14.f],
              NSForegroundColorAttributeName: self.tintColor,
              NSParagraphStyleAttributeName: style };
}

- (NSString *)airplayOverlayView:(SRGAirplayOverlayView *)airplayOverlayView subtitleForAirplayRouteName:(NSString *)routeName
{
    return [NSString stringWithFormat:RTSMediaPlayerLocalizedString(@"This media is playing on «%@»", nil), routeName];
}

- (NSDictionary *)airplayOverlayViewSubtitleAttributedDictionary:(SRGAirplayOverlayView *)airplayOverlayView
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    style.lineBreakMode = NSLineBreakByTruncatingTail;

    return @{ NSFontAttributeName: [UIFont systemFontOfSize:12.f],
              NSForegroundColorAttributeName: self.tintColor,
              NSParagraphStyleAttributeName: style };
}

#pragma mark Notifications

- (void)wirelessRouteActiveDidChange:(NSNotification *)notification
{
    [self setNeedsDisplay];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
    
    BOOL hidden = YES;
    for (AVAudioSessionPortDescription *outputPort in currentRoute.outputs) {
        if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay]) {
            hidden = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(airplayOverlayViewCouldBeDisplayed:)]) {
                if (! [self.delegate airplayOverlayViewCouldBeDisplayed:self]) {
                    hidden = YES;
                }
            }
            break;
        }
    }
    
    [self setHidden:hidden];
}

@end

static void commonInit(SRGAirplayOverlayView *self)
{
    self.contentMode = UIViewContentModeRedraw;
    self.userInteractionEnabled = NO;
    self.hidden = YES;
    self.fillFactor = RTSAirplayOverlayViewDefaultFillFactor;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wirelessRouteActiveDidChange:)
                                                 name:MPVolumeViewWirelessRouteActiveDidChangeNotification
                                               object:nil];
    
    self.volumeView = [[MPVolumeView alloc] init];
}