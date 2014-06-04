//
//  PRViewController.h
//  printRoll
//
//  Created by Jose A Sanchez on 04/06/14.
//  Copyright (c) 2014 Jose A Sanchez. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PRViewController : UIViewController<UIPrintInteractionControllerDelegate>{

    NSURL *_pdfURL;
    CGPDFDocumentRef _document;
    CGPDFPageRef _docPageRef;
    float _width,_height;
}

@property (weak, nonatomic) IBOutlet UIButton *printButton;
@end
