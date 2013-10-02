//
//  PullToRevealViewController.m
//  PullToReveal
//

#define kKIPTRAnimationDuration          0.5f
#define defaultContentInset 390.0f

#import "KIPullToRevealViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MKMapView+ZoomToNYC.h"

@interface KIPullToRevealViewController () <UIScrollViewDelegate, UITextFieldDelegate, MKMapViewDelegate>
{
    @private
    BOOL _scrollViewIsDraggedDownwards;
    double _lastDragOffset;
    int middleViewHeight;
}

@property (nonatomic) CGFloat tableViewContentInsetX;
@end

@implementation KIPullToRevealViewController

@synthesize pullToRevealDelegate = _pullToRevealDelegate;
@synthesize centerUserLocation = _centerUserLocation;
@synthesize mapView = _mapView;
@synthesize pinSelectionEnabled = _pinSelectionEnabled;

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        [self commonInitMethod];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInitMethod];
    }
    return self;
}

- (id) init
{
    if (self = [super init]) {
        [self commonInitMethod];
    }
    return self;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInitMethod];
    }
    return self;
}

- (void) commonInitMethod
{
    middleViewHeight = 30;
    _tableViewContentInsetX = defaultContentInset;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initializeMapView];

    middleViewHeight = 30;
    _tableViewContentInsetX = .7 * self.view.frame.size.height;;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self reloadPins];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private methods
- (void) setPinSelection:(BOOL)enabled
{
    if (_pinSelectionEnabled != enabled) {
        _pinSelectionEnabled = enabled;
        [self performSelectorOnMainThread:@selector(reloadPins) withObject:nil waitUntilDone:YES];
    }
}

- (void) initializeMapView
{
    if (!_mapView) {
        [self.tableView setContentInset:UIEdgeInsetsMake(self.tableViewContentInsetX,0,0,0)];
        _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, self.tableView.contentInset.top*-1, self.tableView.bounds.size.width, self.tableView.contentInset.top)];
        [_mapView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_mapView setShowsUserLocation:NO];
        [_mapView setUserInteractionEnabled:YES];
        [self setPinSelection:NO];
        
        if(_centerUserLocation)
        {
            [self centerToUserLocation];
            [self zoomToUserLocation];
        }
        
        _mapView.delegate = self;
        
        [self.tableView insertSubview:_mapView aboveSubview:self.tableView];
    }
}

- (void) centerToUserLocation
{
    [_mapView setCenterCoordinate:_mapView.userLocation.coordinate animated:YES];
}

- (void) zoomToUserLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = _mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.2;
    mapRegion.span.longitudeDelta = 0.2;
    [_mapView setRegion:mapRegion animated: YES];
}

#pragma mark - ScrollView Delegate
- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    double contentOffset = scrollView.contentOffset.y;
    _lastDragOffset = contentOffset;

    if(contentOffset < -self.tableViewContentInsetX)
    {
        [self zoomMapToFitAnnotations];
        [self setPinSelection:YES];
        [UIView animateWithDuration:kKIPTRAnimationDuration
                         animations:^()
         {
             [self.tableView setContentInset:UIEdgeInsetsMake(self.tableViewContentInsetX,0,0,0)];
             [self.tableView scrollsToTop];
         }];
    }
    else if (contentOffset >= -self.tableViewContentInsetX)
    {
        [self setPinSelection:NO];
        
        [UIView animateWithDuration:kKIPTRAnimationDuration
                         animations:^()
         {
             [self.tableView setContentInset:UIEdgeInsetsMake(self.tableViewContentInsetX,0,0,0)];

         }];
        
        if(_centerUserLocation)
        {
            [self centerToUserLocation];
            [self zoomToUserLocation];
        }
        
        [self.tableView scrollsToTop];
    }
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    double contentOffset = scrollView.contentOffset.y;

    if (contentOffset < _lastDragOffset)
        _scrollViewIsDraggedDownwards = YES;
    else
        _scrollViewIsDraggedDownwards = NO;

    if (!_scrollViewIsDraggedDownwards)
    {
        [_mapView setFrame:
         CGRectMake(0, self.tableView.contentInset.top*-1, self.tableView.bounds.size.width, self.tableView.contentInset.top)
         ];
        [self setPinSelection:NO];

        [self.tableView setContentInset:UIEdgeInsetsMake(self.tableViewContentInsetX,0,0,0)];
        
        if(_centerUserLocation)
        {
            [self centerToUserLocation];
            [self zoomToUserLocation];
        }
        
        [self.tableView scrollsToTop];
    }

    if(contentOffset < 0) {
        // Resize map to viewable size
        [_mapView setFrame:
         CGRectMake(0, self.tableView.bounds.origin.y, self.tableView.bounds.size.width, contentOffset*-1)
         ];
        [self zoomMapToFitAnnotations];
    }
    
    if(_centerUserLocation)
    {
        [self centerToUserLocation];
        [self zoomToUserLocation];
        [self reloadPins];
    }
}


#pragma mark - MapView
- (void) reloadPins
{
    NSMutableArray *annotationsToRemove = [NSMutableArray arrayWithCapacity:self.mapView.annotations.count];
    for (id<MKAnnotation> a in self.mapView.annotations)
        if (![a isKindOfClass:[MKUserLocation class]])
            [annotationsToRemove addObject:a];
    [self.mapView removeAnnotations:annotationsToRemove];

    for (int i = 0; i < [self.pullToRevealDelegate numberOfAnnotations]; i++) {
        id<MKAnnotation> annotation = [self.pullToRevealDelegate annotationForIndex:i];
        CLLocationCoordinate2D c = annotation.coordinate;
        if (annotation && c.latitude != 0 && c.longitude != 0) {
            [_mapView addAnnotation:annotation];
        }
    }
    
    [self zoomMapToFitAnnotations];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MKAnnotationView *pin = [mapView dequeueReusableAnnotationViewWithIdentifier:@"Board Pin"];
    if (!pin) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Board Pin"];

        UIButton *disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        pin.rightCalloutAccessoryView = disclosureButton;
        pin.canShowCallout = YES;
    } else {
        pin.annotation = annotation;
    }

    return pin;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([_pullToRevealDelegate respondsToSelector:@selector(didSelectAnnotation:)])
        [_pullToRevealDelegate didSelectAnnotation:view.annotation];
}


- (void) zoomMapToFitAnnotations
{
    if (_mapView.annotations.count == 0) {
        [self.mapView zoomToSoho];
    } else {
    
        MKMapRect zoomRect = MKMapRectNull;
        for (id <MKAnnotation> annotation in _mapView.annotations)
        {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
            if (MKMapRectIsNull(zoomRect)) {
                zoomRect = pointRect;
            } else {
                zoomRect = MKMapRectUnion(zoomRect, pointRect);
            }
        }
        
        double heightInc = zoomRect.size.height * .4;
        double widthInc = zoomRect.size.width * .25;
        MKMapPoint p = zoomRect.origin;
        MKMapSize s = zoomRect.size;
        zoomRect = MKMapRectMake(p.x - (widthInc/2), p.y-(heightInc/2), s.width+widthInc, s.height+heightInc);
        
        
        [_mapView setVisibleMapRect:zoomRect animated:NO];
    }
}

@end
