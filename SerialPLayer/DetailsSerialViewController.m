//
//  DetailsSerialViewController.m
//  SerialPLayer
//
//  Created by Vadim Denisuk on 15.08.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import "DetailsSerialViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "NewsSerialViewCntroller.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <CommonCrypto/CommonDigest.h>
#import "SSVideoPlayContainer.h"
#import "SSVideoPlayController.h"
#import <CCDropDownMenus/CCDropDownMenus.h>
#import "ConnectionChecker.h"

@interface DetailsSerialViewController () <CCDropDownMenuDelegate>
@property (strong, nonatomic) ContentManager *contentManager;
@property (strong, nonatomic) ConnectionChecker *connection;
@property (strong, nonatomic) DetailsSerialModel *detailmodel;
@property (strong, nonatomic) NSString *currentSerialId;
@property (strong, nonatomic) NSString *currentSerialLink;
@property (weak, nonatomic) IBOutlet UIView *translateChange;
@property (strong, nonatomic) IBOutlet UIImageView *posterSerialsLarge;
@property (strong, nonatomic) IBOutlet UIImageView *smallPosters;
@property (strong, nonatomic) IBOutlet UILabel *yearsSerial;
@property (strong, nonatomic) IBOutlet UILabel *countrySerial;
@property (strong, nonatomic) IBOutlet UILabel *ganreSerial;
@property (strong, nonatomic) IBOutlet UITextView *rolesSerial;
@property (strong, nonatomic) IBOutlet UIView *posterSerial;
@property (strong, nonatomic) IBOutlet UILabel *inRolesLabel;
@property (strong, nonatomic) IBOutlet UILabel *serialDescription;
@property (nonatomic,assign) BOOL favoriteStatus;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *favoriteButtonStatus;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *visualEfectLargePosters;
@property (weak, nonatomic) IBOutlet UILabel *labelYear;
@property (weak, nonatomic) IBOutlet UILabel *labelCountry;
@property (weak, nonatomic) IBOutlet UILabel *labelGanre;
    
@property (strong, nonatomic) ManaDropDownMenu *translate;

@end

@implementation DetailsSerialViewController
@synthesize scrollerView;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _connection = [[ConnectionChecker alloc] init];
    ;
    if([_connection checkInternetConnection] == NO)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Ошибка" message:@"Приложение не чуствуєт интернет соединения" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }else{
    
    UIImage *imageBackground  = [UIImage imageNamed:@"orange_bg"];
    scrollerView.backgroundColor = [UIColor colorWithPatternImage:imageBackground];
    
    loadingView = [[UIView alloc]initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - 40, self.view.bounds.size.height / 2 -40, 80, 80)];
    loadingView.backgroundColor = [UIColor colorWithWhite:0. alpha:0.6];
    loadingView.layer.cornerRadius = 5;
    
    UIActivityIndicatorView *activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.center = CGPointMake(loadingView.frame.size.width / 2.0, 35);
    [activityView startAnimating];
    activityView.tag = 100;
    [loadingView addSubview:activityView];
    
    UILabel* lblLoading = [[UILabel alloc]initWithFrame:CGRectMake(0, 48, 80, 30)];
    lblLoading.text = @"Loading...";
    lblLoading.textColor = [UIColor whiteColor];
    lblLoading.font = [UIFont fontWithName:lblLoading.font.fontName size:15];
    lblLoading.textAlignment = NSTextAlignmentCenter;
    [loadingView addSubview:lblLoading];
    
    [self.view addSubview:loadingView];
    
    [loadingView setHidden:NO];
    
    scrollerView.scrollEnabled = YES;
    scrollerView.pagingEnabled = NO;
    scrollerView.showsVerticalScrollIndicator = YES;
    scrollerView.showsHorizontalScrollIndicator = NO;
    _contentManager = [ContentManager sharedInstance];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        [self loadDataFromSerial];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            
            [self displayAfterLoadData];
            NSData *data = [NSData dataWithContentsOfURL:[_detailmodel posterSerialLarge]];
            if (data == nil)
            {
                data = [NSData dataWithContentsOfURL:[_detailmodel posterSerialNormal]];
            }
            self.posterSerialsLarge.image = [[UIImage alloc] initWithData:data];
            
            NSData *dataSmallImage = [NSData dataWithContentsOfURL:[_detailmodel posterSerialNormal]];
            self.smallPosters.image = [[UIImage alloc] initWithData:dataSmallImage];
            
            self.NameSerial.text = [_detailmodel NameSerial];
            self.yearsSerial.text = [_detailmodel year];
            self.countrySerial.text = [_detailmodel counrty];
            self.ganreSerial.text = [_detailmodel genre];
            
            UIBezierPath * wrappedRectRoles = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.inRolesLabel.frame.size.width, self.inRolesLabel.frame.size.height - 4.0)];
            self.rolesSerial.textContainer.lineFragmentPadding = 0;
            self.rolesSerial.textContainerInset = UIEdgeInsetsZero;
            self.rolesSerial.textContainer.exclusionPaths = @[wrappedRectRoles];
            self.rolesSerial.textColor = [UIColor redColor];
            self.rolesSerial.text = [_detailmodel roles];
            [self sizeroleSerials];
            
            CGFloat rolesPositionBlock = self.rolesSerial.frame.origin.y + self.rolesSerial.bounds.size.height;
            CGFloat posterPositionBlock = self.translateChange.frame.origin.y + self.translateChange.bounds.size.height;
            
            self.serialDescription.text = [_detailmodel descriptionSerial];
            
            if(rolesPositionBlock > posterPositionBlock)
            {
                [self.serialDescription setFrame:CGRectMake(10, rolesPositionBlock + 10.0, scrollerView.bounds.size.width - 20.0, 10.0)];
            }
            else
            {
                [self.serialDescription setFrame:CGRectMake(10, posterPositionBlock + 10.0, scrollerView.bounds.size.width - 20.0, 10.0)];
            }
            [self.serialDescription sizeToFit];
            NSString *string = [[[_detailmodel serialLinks] objectAtIndex:0]objectForKey:@"Name"];
            NSString *squashed = [string stringByReplacingOccurrencesOfString:@"[ ]+"
                                                                   withString:@" "
                                                                      options:NSRegularExpressionSearch
                                                                        range:NSMakeRange(0, string.length)];
            
            NSString *final = [squashed stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
#pragma mark seasonChanger
            CGFloat descriptionTextPositionBlock = self.serialDescription.frame.origin.y + self.serialDescription.bounds.size.height;
            UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
            [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
            _collectionView=[[UICollectionView alloc] initWithFrame:CGRectMake(10, descriptionTextPositionBlock + 10, scrollerView.bounds.size.width - 20.0, 80) collectionViewLayout:layout];

            [_collectionView setDataSource:self];
            [_collectionView setDelegate:self];
            
            [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
            [_collectionView setBackgroundColor:[UIColor clearColor]];
            
            [scrollerView addSubview:_collectionView];
            [_collectionView reloadData];
            NSLog(@"first link %@",final);
            self.rolesSerial.textColor = [UIColor whiteColor];
            [self scrollerSize];
            self.favoriteStatus = [_detailmodel favorite];
            if(self.favoriteStatus)
            {
                self.favoriteButtonStatus.image = [UIImage imageNamed:@"faboriteFull"];
            }
            _translate = [[ManaDropDownMenu alloc] initWithFrame:CGRectMake(10, self.translateChange.frame.origin.y, self.translateChange.bounds.size.width, self.translateChange.bounds.size.height) title:@"Озвучка"];
            _translate.delegate = self;
            _translate.numberOfRows = [[_detailmodel translateList] count];
            _translate.textOfRows = [_detailmodel translateList];
            if ([[_detailmodel translateList] count])
            {
              [scrollerView addSubview:_translate];  
            }
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
            [loadingView setHidden:YES];
        });
    });
    }
}
#pragma mark collectionViewCreator
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_detailmodel serialLinks].count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    
    //cell.backgroundColor=[UIColor greenColor];
    [[[cell contentView] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIView *itemSeason = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height)];
    UILabel *seasonNumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height)];
    seasonNumber.text = [NSString stringWithFormat:@"%ld %@", (long)indexPath.row + 1, @"Сезон"];
    seasonNumber.textColor = [UIColor whiteColor];
    //[[_detailmodel serialLinks objectAtIndex:indexPath.row]
    [itemSeason addSubview:seasonNumber];
    [cell.contentView addSubview:itemSeason];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(80, 80);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath

{
    //connection = [ConnectionChecker sharedInstance];

    if([_connection checkInternetConnection] == NO)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Ошибка" message:@"Приложение не чуствуєт интернет соединения" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
    NSString *idSeason = [[NSString alloc] init];
    idSeason = [[[[[_detailmodel serialLinks] objectAtIndex:indexPath.row] objectForKey:@"Url"] componentsSeparatedByString:@"-"] objectAtIndex:1];
    NSString *urlSeason = [[NSString alloc] init];
    urlSeason = [[[_detailmodel serialLinks] objectAtIndex:indexPath.row] objectForKey:@"Url"];
    DetailsSerialViewController *detailsSerialController =[self.storyboard instantiateViewControllerWithIdentifier:@"DetailSerialPlayer"];
    
    [detailsSerialController serialDetails:idSeason serialLink:urlSeason];
    [self.navigationController pushViewController:detailsSerialController animated:YES];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] init];
    NSString *barBackItem = [[NSString alloc] initWithString:[[[_detailmodel serialLinks] objectAtIndex:indexPath.row] objectForKey:@"Name"]];
    NSString *squashed = [barBackItem stringByReplacingOccurrencesOfString:@"[ ]+"
                                                           withString:@" "
                                                              options:NSRegularExpressionSearch
                                                                range:NSMakeRange(0, barBackItem.length)];
    
    NSString *final = [squashed stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    barButton.title = @"Назад";
    self.navigationController.navigationBar.topItem.backBarButtonItem = barButton;
    }
}


    -(void)displayAfterLoadData
    {
        self.inRolesLabel.hidden = NO;
        self.posterSerialsLarge.hidden = NO;
        self.visualEfectLargePosters.hidden = NO;
        self.NameSerial.hidden = NO;
        self.labelYear.hidden = NO;
        self.labelGanre.hidden = NO;
        self.labelCountry.hidden = NO;
        self.posterSerial.hidden = NO;
    }
- (void)dropDownMenu:(CCDropDownMenu *)dropDownMenu didSelectRowAtIndex:(NSInteger)index {
    
    NSMutableArray *playlistVideoLink = [_contentManager getDovloadTask:self.currentSerialId translate:[[_detailmodel translateList] objectAtIndex:index]];
    if ([playlistVideoLink count] > 0)
    {
        [self openPlayer:playlistVideoLink];
    }
    else
    {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Сочуствие"
                                      message:@"Материалов в даной озвучке не найдено, попробуйде другую озвучку. Приятного просмотра."
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            
            //do something when click button
        }];
        [alert addAction:okAction];
        UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        [vc presentViewController:alert animated:YES completion:nil];

    }
}
-(void)loadDataFromSerial
{
    _detailmodel = [_contentManager getDetailsSerialWithLink:self.currentSerialLink WithId:self.currentSerialId];
}
- (void)didMoveToParentViewController:(UIViewController *)parent
{
    // parent is nil if this view controller was removed
    
}

-(void) serialDetails:(NSString *)serialID serialLink:(NSString *)link
{
    self.currentSerialId = serialID;
    self.currentSerialLink =link;
}
- (IBAction)favoriteButton:(id)sender {
    if(!self.favoriteStatus)
    {
       BOOL operationStatus = [_contentManager writeToFavorite:self.NameSerial.text WithLink:self.currentSerialLink WithId: self.currentSerialId];
        
         if(operationStatus)
         {
             self.favoriteButtonStatus.image = [UIImage imageNamed:@"faboriteFull"];
             self.favoriteStatus = YES;
         }
    }else
    {
        BOOL operationStatus = [_contentManager delFromFavorite:self.currentSerialId];
        if(operationStatus)
        {
            self.favoriteButtonStatus.image = [UIImage imageNamed:@"Favorite-tab-bar"];
            self.favoriteStatus = NO;
        }
    }
}


- (IBAction)OpenVideoLayer:(id)sender {

    if([_connection checkInternetConnection] == NO)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Ошибка" message:@"Приложение не чуствуєт интернет соединения" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
    
    NSMutableArray *playlistVideoLink = [_contentManager getDovloadTask:self.currentSerialId translate:@"Стандартный"];
    if ([playlistVideoLink count] > 0)
    {
        [self openPlayer:playlistVideoLink];
    }
    else
    {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Сочуствие"
                                      message:@"Материалов в даной озвучке не найдено, попробуйде другую озвучку. Приятного просмотра."
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            
            //do something when click button
        }];
        [alert addAction:okAction];
        UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        [vc presentViewController:alert animated:YES completion:nil];
        
    }
    }
    
}
-(void)openPlayer:(NSMutableArray *)playlistVideoLink
{

    if([_connection checkInternetConnection] == NO)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Ошибка" message:@"Приложение не чуствуєт интернет соединения" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
    NSMutableArray *videoList = [NSMutableArray array];
    for (NSInteger i = 0; i<playlistVideoLink.count; i++) {
        SSVideoModel *model = [[SSVideoModel alloc]initWithName:[playlistVideoLink[i] objectForKey:@"Name"] path:[playlistVideoLink[i] objectForKey:@"Path"]];
        [videoList addObject:model];
    }
    SSVideoPlayController *playController = [[SSVideoPlayController alloc]initWithVideoList:videoList presentButton:YES];
    SSVideoPlayContainer *playContainer = [[SSVideoPlayContainer alloc]initWithRootViewController:playController];
    [self presentViewController:playContainer animated:NO completion:nil];
    }
}
- (void) didRotate:(NSNotification *)notification
{
    [self sizeroleSerials];
    CGFloat rolesPositionBlock = self.rolesSerial.frame.origin.y + self.rolesSerial.bounds.size.height;
    CGFloat posterPositionBlock = self.translateChange.frame.origin.y + self.translateChange.bounds.size.height;
    
    self.serialDescription.text = [_detailmodel descriptionSerial];
    
    if(rolesPositionBlock > posterPositionBlock)
    {
        [self.serialDescription setFrame:CGRectMake(10, rolesPositionBlock + 10.0, scrollerView.bounds.size.width - 20.0, 10.0)];
    }
    else
    {
        [self.serialDescription setFrame:CGRectMake(10, posterPositionBlock + 10.0, scrollerView.bounds.size.width - 20.0, 10.0)];
    }
    [self.serialDescription sizeToFit];
    CGFloat descriptionTextPositionBlock = self.serialDescription.frame.origin.y + self.serialDescription.bounds.size.height;
    [_collectionView setFrame:CGRectMake(10, descriptionTextPositionBlock + 10, scrollerView.bounds.size.width - 20.0, 80)];
    [self scrollerSize];
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIDeviceOrientationLandscapeLeft)
    {
        NSLog(@"Landscape Left!");
    }
}
-(void)scrollerSize
{
    CGFloat lastPositionBlock = _collectionView.frame.origin.y + _collectionView.bounds.size.height + 20;
    scrollerView.contentSize = CGSizeMake(self.view.bounds.size.width, lastPositionBlock);
}
-(void)sizeroleSerials
{
    [self.rolesSerial sizeToFit];
    CGRect frame;
    frame = self.rolesSerial.frame;
    frame.size.height = [self.rolesSerial contentSize].height;
    self.rolesSerial.frame = frame;
}
@end
