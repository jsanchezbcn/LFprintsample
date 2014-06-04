//
//  PRViewController.m
//  printRoll
//
//  Created by Jose A Sanchez on 04/06/14.
//  Copyright (c) 2014 Jose A Sanchez. All rights reserved.
//

#import "PRViewController.h"
#import "PRPageRenderer.h"

#define kTolerance 72*0.5 //half and inch tolerance when printing.

@interface PRViewController ()

@end

@implementation PRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *pdfStringURL = [[NSBundle mainBundle] pathForResource:@"Dsize" ofType:@"pdf"];
    _pdfURL = [NSURL fileURLWithPath:pdfStringURL];
    _document = CGPDFDocumentCreateWithURL((CFURLRef)_pdfURL);
    _docPageRef = CGPDFDocumentGetPage(_document, 1);
   
    _width = CGPDFPageGetBoxRect(_docPageRef, kCGPDFMediaBox).size.width;
    _height = CGPDFPageGetBoxRect(_docPageRef, kCGPDFMediaBox).size.height;
    
    UIWebView *theWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0,40, self.view.frame.size.width , self.view.frame.size.height-300)];
      theWebView.scalesPageToFit=YES;
       [theWebView loadRequest:[NSURLRequest requestWithURL:_pdfURL]];
    
    
    
    [self.view addSubview: theWebView];
}


//print using printingItem (simple way, less control)
- (IBAction)print:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Dsize" ofType:@"pdf"];
	NSData *myData = [NSData dataWithContentsOfFile: path];
	
	
	UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
	
	if(pic && [UIPrintInteractionController canPrintData: myData] ) {
		
		pic.delegate = self;
		
		UIPrintInfo *printInfo = [UIPrintInfo printInfo];
		printInfo.outputType = UIPrintInfoOutputGeneral;
		printInfo.jobName = [path lastPathComponent];
		printInfo.duplex = UIPrintInfoDuplexNone;
		pic.printInfo = printInfo;
		pic.showsPageRange = NO;
		pic.printingItem = myData;
		
		void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
			if (!completed && error) {
				NSLog(@"FAILED! error in  %@ with error %u", error.domain, error.code);
			}
		};
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            [pic presentFromRect:self.printButton.frame inView:self.view animated:YES completionHandler:nil];
        else
            [pic presentAnimated:YES completionHandler:completionHandler];  // iPhone

		
	}
    
    
}


//full control, on rotation, and how to paint the drawing on the paper. Using a page renderer.
- (IBAction)intantPrint:(id)sender {
 
    /* Get the UIPrintInteractionController, which is a shared object */
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
	if(!pic){
		NSLog(@"Couldn't get shared UIPrintInteractionController!");
		return;
	}
    
    /* Set this object as delegate so you can  use the printInteractionController:cutLengthForPaper: delegate */
    pic.delegate = self;
    
  
    PRPageRenderer *pageRenderer = [[PRPageRenderer alloc] initWithPDFPath:_pdfURL];
   
    pic.printPageRenderer = pageRenderer;
 	
    /* Set up a completion handler block.  If the print job has an error before spooling, this is where it's handled. */
	void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if(completed && error)
            NSLog(@"FAILED! due to error in domain %@ with error code %lu", error.domain, (long)error.code);
	};
	
	UIPrintInfo *printInfo = [UIPrintInfo printInfo];
	printInfo.outputType = UIPrintInfoOutputGeneral;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [pic presentFromRect:self.printButton.frame inView:self.view animated:YES completionHandler:nil];
	else
		[pic presentAnimated:YES completionHandler:completionHandler];  // iPhone
    
    
}


//we get a roll size, we have to return the lenght for the roll to be cut.
- (CGFloat)printInteractionController:(UIPrintInteractionController *)printInteractionController cutLengthForPaper:(UIPrintPaper *)paper {

    NSLog (@"Roll of %f inches on the printer.",paper.printableRect.size.width/72) ;
    
    
    CGFloat lengthOfMargins = paper.paperSize.height - paper.printableRect.size.height;
    
    int numberOfPages = CGPDFDocumentGetNumberOfPages(_document);
    if (numberOfPages>0) {
        //TBD implement multipage PDFs
        
        CGRect documentSize = CGPDFPageGetBoxRect(_docPageRef,kCGPDFMediaBox);
        NSLog(@"Document Media box PDF origin: %.f in  %.f in  size: %.f in  %.f in",documentSize.origin.x/72.0,documentSize.origin.y/72.0,documentSize.size.width/72.0,documentSize.size.height/72.0);
        NSLog(@"Document size : %.f x %.f in",documentSize.size.width/72.0,documentSize.size.height/72.0);
        NSLog(@"Document size : %.f x %.f cm",documentSize.size.width/72.0*2.54,documentSize.size.height/72.0*2.54);
        
        //document is portrait, lets find if it could be fitted in landscape (with some kTolerance)
        if (documentSize.size.height>documentSize.size.width && documentSize.size.height<=(paper.paperSize.width + kTolerance)) {
            //then rotate 90%
            return documentSize.size.width+lengthOfMargins;
        }
        //document is landscape or cannot be fitted in landscape
        else{
            //document could be fitted the way it is
            if((paper.paperSize.width+kTolerance)>=documentSize.size.width){
                //just print it with not rotation.
                return documentSize.size.height+lengthOfMargins;
            }
            else {
                //we try to rotate first to check if it fits
                if((paper.paperSize.width+kTolerance)>=documentSize.size.height){
                    return documentSize.size.width+lengthOfMargins;
                }
                else {
                    //we need to scale it.
                    //we try to fit it in half size first.
                    float halfWidth=documentSize.size.width/2.0;
                    float halfHeight=documentSize.size.height/2.0;
                    //document is portrait, lets find if it could be fitted in landscape (with some kTolerance)
                    if (halfHeight>halfWidth && halfHeight<=(paper.paperSize.width + kTolerance)) {
                        //then rotate 90% and print in half size
                        return halfWidth+lengthOfMargins;
                    }
                    else if((paper.paperSize.width+kTolerance)>=halfWidth){
                        //print half size, not rotation
                        return halfHeight+lengthOfMargins;
                        
                    }
                    else{
                        //cannot be printed half size so scale to whatever you have loaded on the printer
                    
                        float scale=paper.printableRect.size.width/documentSize.size.height;
                        return documentSize.size.width*scale+lengthOfMargins;
                    }
                }
            }

        }
    }
    
    //no page on the pdf
    return 0;
}


- (CGPDFDocumentRef)newDocumentWithUrl:(CFURLRef)url {
    CGPDFDocumentRef myDocument = CGPDFDocumentCreateWithURL(url);
    if (myDocument == NULL) {
        return 0;
    }
    if (CGPDFDocumentIsEncrypted (myDocument)
        || !CGPDFDocumentIsUnlocked (myDocument)
        || CGPDFDocumentGetNumberOfPages(myDocument) == 0) {
        return myDocument;
    }
    return myDocument;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{

    CGPDFDocumentRelease(_document);

    
}

@end
