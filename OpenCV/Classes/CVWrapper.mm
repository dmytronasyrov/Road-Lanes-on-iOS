//
//  CVWrapper.m
//  OpenCV
//
//  Created by Dmytro Nasyrov on 5/1/17.
//  Copyright © 2017 Pharos Production Inc. All rights reserved.
//

#ifdef __cplusplus
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <opencv2/opencv.hpp>
#import "CVWrapper.h"

#pragma clang pop
#endif

using namespace std;
using namespace cv;

#pragma mark - Private Declarations

@interface CVWrapper ()

#ifdef __cplusplus

+ (Mat)_polycut:(Mat)source marginTop:(int)marginTop marginBottom:(int)marginBottom topHalfWidth:(int)topHalfWidth bottomHalfWidth:(int)bottomHalfWidth;
+ (Mat)_rgbToYcr:(Mat)source;
+ (Mat)_gamma:(Mat)source value:(double)value;
+ (Mat)_threshold:(Mat)source min:(int)min max:(int)max;
+ (Mat)_canny:(Mat)source min:(int)min scale:(int)scale;
+ (vector<Vec4i>)_houghLines:(Mat)source rho:(int)rho threshold:(int)threshold minLength:(int)minLength gapMaxLength:(int)gapMaxLength;
+ (tuple<Vec4i, Vec4i>)_lanesFilter:(vector<Vec4i>)lines left:(int)left right:(int)right;
+ (Mat)_drawLanes:(tuple<Vec4i, Vec4i>)lanes size:(cv::Size)size;
+ (Mat)_revertROI:(Mat)source croppedMat:(Mat)croppedMat marginTop:(int)marginTop marginBottom:(int)marginBottom topHalfWidth:(int)topHalfWidth bottomHalfWidth:(int)bottomHalfWidth;
+ (Mat)_overlay:(Mat)sourceA sourceB:(Mat)sourceB;
+ (Mat)_matFrom:(UIImage *)source;
+ (UIImage *)_imageFrom:(Mat)source;

#endif

@end

#pragma mark - CVWrapper

@implementation CVWrapper

#pragma mark Public

+ (UIImage *)lanesFrom:(UIImage *)source {
    cout << "OpenCV: ";

    Mat image = [CVWrapper _matFrom:source];
    Mat imageOut = image.clone();

    imageOut = [CVWrapper _polycut:imageOut marginTop:320 marginBottom:50 topHalfWidth:50 bottomHalfWidth: 400];
    imageOut = [CVWrapper _rgbToYcr:imageOut];
    imageOut = [CVWrapper _gamma:imageOut value:0.5];
    imageOut = [CVWrapper _threshold:imageOut min:100 max:255];
    imageOut = [CVWrapper _canny:imageOut min:100 scale:1.3];
    vector<Vec4i> lines = [CVWrapper _houghLines:imageOut rho:2 threshold:50 minLength:10 gapMaxLength:200];
    tuple<Vec4i, Vec4i> lanes = [CVWrapper _lanesFilter:lines left:25 right:50];
    imageOut = [CVWrapper _drawLanes:lanes size:imageOut.size()];
    imageOut = [CVWrapper _revertROI:image croppedMat:imageOut marginTop:320 marginBottom:50 topHalfWidth:50 bottomHalfWidth:400];
    imageOut = [CVWrapper _overlay:image sourceB:imageOut];

    return [CVWrapper _imageFrom:imageOut];
}

#pragma mark Private

+ (Mat)_polycut:(Mat)source marginTop:(int)marginTop marginBottom:(int)marginBottom topHalfWidth:(int)topHalfWidth bottomHalfWidth:(int)bottomHalfWidth {
    cout << "-> polycut ->";
    
    int width = source.cols;
    int height = source.rows;
    int centerX = floor(width / 2.0);
    
    cv::Point P1(centerX - topHalfWidth, marginTop); // from top left clock wise
    cv::Point P2(centerX + topHalfWidth, marginTop);
    cv::Point P3(centerX + bottomHalfWidth, height - marginBottom);
    cv::Point P4(centerX - bottomHalfWidth, height - marginBottom);
    
    int roiX = (P1.x < P4.x ? P1.x : P4.x);
    int roiY = P1.y;
    int topWidth = 2 * topHalfWidth;
    int bottomWidth = 2 * bottomHalfWidth;
    int roiWidth = (topWidth < bottomWidth ? bottomWidth : topWidth);
    int roiHeight = height - marginBottom - marginTop;
    
    vector<vector<cv::Point>> coords;
    coords.push_back(vector<cv::Point>());
    coords[0].push_back(P1);
    coords[0].push_back(P2);
    coords[0].push_back(P3);
    coords[0].push_back(P4);
    
    cv::Rect maskROI(0, 0, width, height);
    Mat mask(height, width, CV_8UC1, Scalar(0));
    drawContours(mask, coords, 0, Scalar(255), CV_FILLED, 8);
    
    Mat srcROI = source(maskROI);
    Mat maskedSource;
    srcROI.copyTo(maskedSource, mask);

    cv::Rect rectROI(roiX, roiY, roiWidth, roiHeight);
    Mat croppedRef(maskedSource, rectROI);
    Mat result;
    croppedRef.copyTo(result);
    
    return result;
}

+ (Mat)_rgbToYcr:(Mat)source {
    cout << "-> RGB-YCR ->";
    
    Mat result;
    cvtColor(source, result, COLOR_BGR2YCrCb);
    
    return result;
}

+ (Mat)_gamma:(Mat)source value:(double)value {
    cout << "-> gamma ->";
    
    double inverse = 1.0 / value;
    Mat lut_matrix(1, 256, CV_8UC1);
    uchar *ptr = lut_matrix.ptr();
    
    for(int i = 0; i <= 255; i++)
        ptr[i] = (int)(pow((double)i / 255.0, inverse) * 255.0);
    
    Mat result;
    LUT(source, lut_matrix, result);
    
    return result;
}

+ (Mat)_threshold:(Mat)source min:(int)min max:(int)max {
    cout << "-> threshold ->";
    
    Mat result;
    threshold(source, result, min, max, THRESH_BINARY);
    
    return result;
}

+ (Mat)_canny:(Mat)source min:(int)min scale:(int)scale {
    cout << "-> canny ->";
    
    Mat result;
    Canny(source, result, min, ceil(min * scale), 3);
    
    return result;
}

+ (vector<Vec4i>)_houghLines:(Mat)source rho:(int)rho threshold:(int)threshold minLength:(int)minLength gapMaxLength:(int)gapMaxLength {
    cout << "-> houghLines ->";

    vector<Vec4i> lines;
    HoughLinesP(source, lines, rho, CV_PI / 180.0, threshold, minLength, gapMaxLength);
    
    return lines;
}

+ (tuple<Vec4i, Vec4i>)_lanesFilter:(vector<Vec4i>)lines left:(int)left right:(int)right {
    cout << "-> lanesFilter ->";
    
    double leftRad = left * CV_PI / 180.0;
    double rightRad = right * CV_PI / 180.0;

    vector<Vec4i> leftLines;
    vector<Vec4i> rightLines;
    
    for(size_t i = 0; i < lines.size(); i++) {
        Vec4i l = lines[i];
        double angle = atan2(l[3] - l[1], l[2] - l[0]);

        if(angle > -rightRad && angle < -leftRad) // left
            leftLines.push_back(l);
        else if(angle > leftRad && angle < rightRad) // right
            rightLines.push_back(l);
    }
    
    std::sort(leftLines.begin(), leftLines.end(), [](const Vec4i &a, const Vec4i &b) {
        return euclidDistSqr(a) > euclidDistSqr(b);
    });
    
    std::sort(rightLines.begin(), rightLines.end(), [](const Vec4i &a, const Vec4i &b) {
        return euclidDistSqr(a) > euclidDistSqr(b);
    });
    
    return tuple<Vec4i, Vec4i>(leftLines.front(), rightLines.front());
}

+ (Mat)_drawLines:(vector<Vec4i>)lines size:(cv::Size)size {
    Mat result = Mat::zeros(size, CV_8UC3);
    
    for(size_t i = 0; i < lines.size(); i++) {
        Vec4i l = lines[i];
        cv::line(result, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), Scalar(255, 0, 0), 2, CV_AA);
    }
    
    return result;
}

+ (Mat)_drawLanes:(tuple<Vec4i, Vec4i>)lanes size:(cv::Size)size {
    cout << "-> drawLanes ->";
    
    Scalar leftColor = Scalar(0, 0, 255);
    Scalar rightColor = Scalar(255, 0, 0);
    int lineWidth = 4;
    
    Mat result = Mat::zeros(size, CV_8UC3);
    
    Vec4i leftLane, rightLane;
    std::tie(leftLane, rightLane) = lanes;
    cv::line(result, cv::Point(leftLane[0], leftLane[1]), cv::Point(leftLane[2], leftLane[3]), leftColor, lineWidth, CV_AA);
    cv::line(result, cv::Point(rightLane[0], rightLane[1]), cv::Point(rightLane[2], rightLane[3]), rightColor, lineWidth, CV_AA);
    
    return result;
}

+ (Mat)_revertROI:(Mat)source croppedMat:(Mat)croppedMat marginTop:(int)marginTop marginBottom:(int)marginBottom topHalfWidth:(int)topHalfWidth bottomHalfWidth:(int)bottomHalfWidth {
    cout << "-> revertROI ->";
    
    int width = source.cols;
    int height = source.rows;
    int centerX = floor(width / 2.0);
    
    cv::Point P1(centerX - topHalfWidth, marginTop); // from top left clock wise
    cv::Point P4(centerX - bottomHalfWidth, height - marginBottom);
    int roiX = (P1.x < P4.x ? P1.x : P4.x);
    
    Mat result = Mat::zeros(source.size(), CV_8UC3);
    croppedMat.copyTo(result(cv::Rect(roiX, P1.y, croppedMat.cols, croppedMat.rows)));
    
    return result;
}

+ (Mat)_overlay:(Mat)sourceA sourceB:(Mat)sourceB {
    cout << "-> overlay ->";
    
    Mat result;
    cv::bitwise_or(sourceA, sourceB, result);
    
    return result;
}

+ (Mat)_matFrom:(UIImage *)source {
    cout << "matFrom ->";
    
    CGImageRef image = CGImageCreateCopy(source.CGImage);
    CGFloat cols = CGImageGetWidth(image);
    CGFloat rows = CGImageGetHeight(image);
    Mat result4(rows, cols, CV_8UC4);
    
    CGBitmapInfo bitmapFlags = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = result4.step[0];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    
    CGContextRef context = CGBitmapContextCreate(result4.data, cols, rows, bitsPerComponent, bytesPerRow, colorSpace, bitmapFlags);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, cols, rows), image);
    CGContextRelease(context);
    
    Mat result3 = Mat::zeros(result4.size(), CV_8UC3);
    cvtColor(result4, result3, CV_BGRA2BGR);
    
    return result3;
}

+ (UIImage *)_imageFrom:(Mat)source {
    cout << "-> imageFrom\n";
    
    NSData *data = [NSData dataWithBytes:source.data length:source.elemSize() * source.total()];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    CGBitmapInfo bitmapFlags = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = source.step[0];
    CGColorSpaceRef colorSpace = (source.elemSize() == 1 ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB());

    CGImageRef image = CGImageCreate(source.cols, source.rows, bitsPerComponent, bitsPerComponent * source.elemSize(), bytesPerRow, colorSpace, bitmapFlags, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *result = [UIImage imageWithCGImage:image];
    
    CGImageRelease(image);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return result;
}

double euclidDistSqr(const Vec4i &line) {
    return static_cast<double>(pow(line[0] - line[2], 2), pow(line[1] - line[3], 2));
}

@end
