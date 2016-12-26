//
//  DEMOHomeViewController.m
//  REFrostedViewControllerStoryboards
//
//  Created by Roman Efimov on 10/9/13.
//  Copyright (c) 2013 Roman Efimov. All rights reserved.
//

#import "NewsSerialViewCntroller.h"
#import <QuartzCore/QuartzCore.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "NewsSerialCollectionViewCell.h"
#import "DetailsSerialViewController.h"
#import "ConnectionChecker.h"

@interface NewsSerialViewCntroller ()
@property (strong, nonatomic) NSMutableArray *content;
@property (strong, nonatomic) NSMutableArray *allContent;
@property (strong, nonatomic) NSString *headerTitle;
@property (nonatomic, assign) BOOL textFieldSearch;
@property (nonatomic, assign) ItemMenu currentMenu;
@property(nonatomic) UIBarButtonItemStyle style;
@property (strong, nonatomic) ConnectionChecker *connection;

@end

@interface UIImage (TPAdditions)
- (UIImage*)imageScaledToSize:(CGSize)size;
@end

@implementation UIImage (TPAdditions)
- (UIImage*)imageScaledToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end

@implementation NewsSerialViewCntroller
@synthesize searchField;
ContentManager *contentManager;


- (void)viewDidLoad {
    [super viewDidLoad];
    _connection = [[ConnectionChecker alloc] init];
    //connection = [ConnectionChecker sharedInstance];
    [self initMainViewController];
    if( [_connection checkInternetConnection] == NO)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Ошибка" message:@"Приложение не чуствуєт интернет соединения" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        // Connected to the internet
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            static dispatch_once_t task;
            dispatch_once(&task, ^{
                [contentManager setSetting];
            });
        });
        
    }
    
}
-(void)initMainViewController
{
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
    spinner.tag = 12;
    [self.view addSubview:spinner];
    [spinner startAnimating];
    
    contentManager = [ContentManager sharedInstance];
    self.textFieldSearch = NO;
    
    
    
    self.searchField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, 21.0)];
    
    static dispatch_once_t task;
    dispatch_once(&task, ^{
        [self menuSerial:News];

    });
    searchField.delegate = self;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor whiteColor]];
    [self.collectionView addSubview:refreshControl];
}
-(void)refresh:(UIRefreshControl *)refreshControl
{

    if( [_connection checkInternetConnection] == NO)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Ошибка" message:@"Приложение не чуствуєт интернет соединения" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }else
    {

    }
    self.content= nil;
    [self menuSerial:_currentMenu];
    [self.collectionView reloadData];
    [refreshControl endRefreshing];

}
-(void)menuSerial:(ItemMenu)typeMenu
{
    self.currentMenu = typeMenu;
    if(self.content == nil)
    {
        self.content = [contentManager getArraySerials:typeMenu];

        switch (typeMenu) {
            case News:
                self.navigationItem.title = @"Новые серии";
                break;
            case All:
                self.navigationItem.title = @"Все сериалы";
                break;
            case Favorite:
                self.navigationItem.title = @"Любимые Сериалы";
                break;
            default:
                break;
        }
        self.allContent = self.content;
    }
}

- (IBAction)showMenu
{
    [self.view endEditing:YES];
    [self.frostedViewController.view endEditing:YES];

    [self.frostedViewController presentMenuViewController];
}
- (IBAction)searchButton:(id)sender {
    
    NSString *titleText =  self.navigationItem.title;
    
    if(!self.textFieldSearch)
    {
        self.textFieldSearch = YES;
        UIBarButtonItem *newUndoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(searchButton:)];
        self.navigationItem.rightBarButtonItem = newUndoButton;
        self.navigationItem.titleView = self.searchField;
        
        [searchField becomeFirstResponder];
    }
    else
    {
        self.textFieldSearch = NO;
        [searchField removeFromSuperview];
        UIBarButtonItem *newUndoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButton:)];
        self.navigationItem.rightBarButtonItem = newUndoButton;
        UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 220, 44)];
        titleView.text = titleText;
        titleView.textColor = [UIColor colorWithRed:0.98 green:0.42 blue:0.22 alpha:1.0];
        [titleView setFont:[UIFont fontWithName:@"Arial-BoldMT" size:18]];
        titleView.textAlignment = NSTextAlignmentCenter;
        self.navigationItem.titleView = titleView;
    }
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    textField.textColor = [UIColor colorWithRed:0.98 green:0.42 blue:0.22 alpha:1.0];
    if(textField.text.length > 2)
    {
        //[_allSerials removeAllObjects];
        NSMutableArray *containText = [[NSMutableArray alloc] init];
        int i;
        for (i=0; i < _allContent.count; i++)
        {
            if([[[_allContent objectAtIndex:i] Name] containsString: textField.text])
            {
                //NSLog(@"string YES %@", [[_allSerialsSearch objectAtIndex:i] objectForKey:@"Name"]);
                [containText addObject:[_allContent objectAtIndex:i]];
            }
        }
        _content = containText;
        [self.collectionView reloadData];
    }
    if(textField.text.length < 2)
    {
        _content = _allContent;
        [self.collectionView reloadData];
    }
    
    return YES;
}

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    [[self.view viewWithTag:12] stopAnimating];
    return self.content.count;
}
-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    __weak NewsSerialCollectionViewCell *aCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"serialNewsCell" forIndexPath:indexPath];
    
    aCell.SerialName.text = [[self.content objectAtIndex:indexPath.row] Name];
    //[aCell.SerialName sizeToFit];
    aCell.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];

    NSURLRequest *request = [NSURLRequest requestWithURL:[[self.content objectAtIndex:indexPath.row] ImageURL]];
    UIImage *placeholderImage = [UIImage imageNamed:@"placeholder"];
    
    [aCell.posterNewsSerial setImageWithURLRequest:request
                          placeholderImage:placeholderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       
                                       aCell.posterNewsSerial.image = image;
                                       [aCell setNeedsLayout];
                                       
                                   } failure:nil];
    
    return aCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath

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
    DetailsSerialViewController *detailsSerialController =[self.storyboard instantiateViewControllerWithIdentifier:@"DetailSerialPlayer"];

    [detailsSerialController serialDetails:[[self.content objectAtIndex:indexPath.row] Id] serialLink:[[self.content objectAtIndex:indexPath.row] Url]];
    [self.navigationController pushViewController:detailsSerialController animated:YES];
    }
    
}
@end
