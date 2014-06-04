//
//  PRPageRenderer.m
//
//
//  Created by Sergio De Simone on 29/11/13.
//

#import "PRPageRenderer.h"
#define kTolerance 72*0.5 //half and inch Tolerance when printing.


@implementation PRPageRenderer

- (instancetype)initWithPDFPath:(NSURL*)pdfURL{
 
    if ((self = [super init])) {
        
        _scale = 1;
        _pdfURL = pdfURL;
        
    }
    return self;
}

- (NSInteger)numberOfPages {
    
    //TBD multiple pages
    return 1;
}


- (void)drawContentForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)printableRect
{
    if (pageIndex == 0) {
        
        [self renderPDFInFrame:printableRect];
        
    }
}


- (void)renderPDFInFrame:(CGRect)printableRect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPDFDocumentRef document = [self newDocumentWithUrl:(CFURLRef)_pdfURL];
    CGPDFPageRef docPageRef = CGPDFDocumentGetPage(document, 1);
    CGRect pageRect = CGPDFPageGetBoxRect(docPageRef, kCGPDFMediaBox);
    if (printableRect.size.width == 0)
        printableRect = pageRect;
    
    
    CGSize imageableAreaSize = printableRect.size;
    
    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
    CGContextFillRect(context, printableRect);
    CGContextSaveGState(context);

    
    //check if can be printed at 100% first.
    
    //document is portrait, lets find if it could be fitted in landscape (with some kTolerance)
    if (pageRect.size.height>pageRect.size.width && pageRect.size.height<=(printableRect.size.width + kTolerance)) {
        //then rotate 90%
        CGContextTranslateCTM(context, printableRect.origin.x, printableRect.origin.y);
        CGContextScaleCTM(context, 1, -1);
        // Rotate the coordinate system.
        CGContextRotateCTM(context, -M_PI / 2);
        _scale=1;
        
    }
    else{
        //it fits in portrait, not need to scale.
        if (((pageRect.size.height <= (printableRect.size.height+ kTolerance))) && (pageRect.size.width <= (printableRect.size.width + kTolerance))) {
            _scale = 1;
            CGContextTranslateCTM(context,printableRect.origin.x, imageableAreaSize.height);
            CGContextScaleCTM(context, 1.0, -1.0);
        }
        else {
    
            //we need to scale it.
            //we try to fit it in half size first.
            float halfWidth=pageRect.size.width/2.0;
            float halfHeight=pageRect.size.height/2.0;
            if(halfHeight>halfWidth && halfHeight<=(printableRect.size.width + kTolerance)) {
                //then rotate 90% and print in half size
                CGContextTranslateCTM(context, printableRect.origin.x, printableRect.origin.y);
                CGContextScaleCTM(context, 1, -1);
                // Rotate the coordinate system.
                CGContextRotateCTM(context, -M_PI / 2);
                _scale=0.5;
            }
            else if((printableRect.size.width+kTolerance)>=halfWidth){
                //print half size, not rotation
                _scale = 0.5;
                CGContextTranslateCTM(context,printableRect.origin.x, imageableAreaSize.height);
                CGContextScaleCTM(context, 1.0, -1.0);
            }
            else{
                //cannot be printed half size so scale to whatever you have loaded on the printer
            
                if (pageRect.size.width > pageRect.size.height) {
                    _scale = printableRect.size.height/pageRect.size.width;
                    //lets rotate 90%
                    // Reverse the Y axis to grow from bottom to top.
                    CGContextTranslateCTM(context, printableRect.origin.x, printableRect.origin.y);
                    CGContextScaleCTM(context, 1, -1);
                    // Rotate the coordinate system.
                    CGContextRotateCTM(context, -M_PI / 2);
                }
                else {
                    
                    CGContextTranslateCTM(context, 0, printableRect.size.height);
                    CGContextScaleCTM(context, 1, -1);
                    _scale = printableRect.size.height/pageRect.size.height;
                }
            }
        }
    }

    //scale the context to the right scale.
    CGContextScaleCTM(context, _scale, _scale);

    CGContextDrawPDFPage(context, docPageRef);
    
    CGContextRestoreGState(context);
    
    //draw the wattermark
    [self drawWaterMark:printableRect];


    CGPDFDocumentRelease(document);

}

-(void)drawWaterMark:(CGRect)printableRect{
    
    if(_scale<1){
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);

        NSString *message;
        if(_scale==.5)
            message=@"Halfsize";
        else
            message=[NSString stringWithFormat:@"%d%% Scale",(int)(_scale*100)];
        
        //choose a big font size
        int fontsize=printableRect.size.height/6;
        
        UIFont *font = [UIFont fontWithName:@"Helvetica" size:fontsize];
        
        NSDictionary *attrsDictionary =
        [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
         [NSNumber numberWithFloat:1.0], NSBaselineOffsetAttributeName,[UIColor colorWithWhite:0.8 alpha:0.3], NSForegroundColorAttributeName, nil];
        
        //rotate message 45 degrees
        CGAffineTransform transform1 = CGAffineTransformMakeRotation(-45.0 * M_PI/180.0);
        CGContextConcatCTM(context, transform1);
        
        CGSize messagesize=[message sizeWithAttributes:attrsDictionary];
        [message drawAtPoint:CGPointMake(-messagesize.height, printableRect.size.width/2) withAttributes:attrsDictionary];
        CGContextRestoreGState(context);

    }

}



- (CGPDFDocumentRef)newDocumentWithUrl:(CFURLRef)url {
    CGPDFDocumentRef myDocument = CGPDFDocumentCreateWithURL(url);
    if (myDocument == NULL) {
        return 0;
    }
    if (CGPDFDocumentIsEncrypted (myDocument)
        || !CGPDFDocumentIsUnlocked (myDocument)
        || CGPDFDocumentGetNumberOfPages(myDocument) == 0) {
        //CGPDFDocumentRelease(myDocument);
        return myDocument;
    }
    return myDocument;
}


@end
