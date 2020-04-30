//
//  OpenCVWrapper.m
//  FrameExtraction
//
//  Created by Spencer Hamilton on 7/30/19.
//  Copyright © 2019 Spencer Hamilton. All rights reserved.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "opencv2/objdetect.hpp"
#import "opencv2/highgui.hpp"
#import "opencv2/imgproc.hpp"


using namespace std;
using namespace cv;
void detectAndDraw(cv::Mat& img, cv::CascadeClassifier& cascade, cv::CascadeClassifier& nestedCascade, double scale, bool tryflip );
void detectFace(cv::Mat& img);

//for facial recognition
string cascadeName;
string nestedCascadeName;

@implementation OpenCVWrapper
- (UIImage *)a:(UIImage *)image {
    //cout << image << endl;
    cv::Mat mat = cv::Mat();
    
    
    //create Mat representation of image
    UIImageToMat(image, mat, 0);
    
    //call to mat manipulation
    //flip(mat, mat, 1);
    detectFace(mat);
    
    //convert back to UIImage
    image = MatToUIImage(mat);
    
    return image;
}
@end

void detectFace(Mat& img)
{
    bool tryflip = 0;
    CascadeClassifier cascade, nestedCascade;
    double scale = 1;
    
    // get main app bundle
    NSBundle * appBundle = [NSBundle mainBundle];
    // constant file name
    NSString * cascadeName = @"haarcascade_frontalface_alt";
    NSString * cascadeType = @"xml";
    NSString * nestedCascadeName = @"haarcascade_eye_tree_eyeglasses";
    NSString * nestedCascadeType = @"xml";
    
    // get file path in bundle
    NSString * cascadePathInBundle = [appBundle pathForResource: cascadeName ofType: cascadeType];
    NSString * nestedCascadePathInBundle = [appBundle pathForResource: nestedCascadeName ofType: nestedCascadeType];
    
    // convert NSString to std::string
    std::string cascadePath([cascadePathInBundle UTF8String]);
    std::string nestedCascadePath([nestedCascadePathInBundle UTF8String]);
    
    // load cascade
    if (cascade.load(cascadePath) && nestedCascade.load(nestedCascadePath)){
        //printf("Load complete");
    }else{
        //printf("Load error");
    }
    
    //detect and draw on image
    if (!img.empty()) detectAndDraw(img, cascade, nestedCascade, scale, tryflip);
}

//for facial recognition
void detectAndDraw( Mat& img, CascadeClassifier& cascade,
                   CascadeClassifier& nestedCascade,
                   double scale, bool tryflip )
{
    double t = 0;
    vector<cv::Rect> faces, faces2;
    const static Scalar colors[] =
    {
        Scalar(255,0,0),
        Scalar(255,128,0),
        Scalar(255,255,0),
        Scalar(0,255,0),
        Scalar(0,128,255),
        Scalar(0,255,255),
        Scalar(0,0,255),
        Scalar(255,0,255)
    };
    Mat gray, smallImg;
    cvtColor( img, gray, COLOR_BGR2GRAY );
    double fx = 1 / scale;
    resize( gray, smallImg, cv::Size(), fx, fx, INTER_LINEAR_EXACT );
    equalizeHist( smallImg, smallImg );
    t = (double)getTickCount();
    cascade.detectMultiScale( smallImg, faces,
                             1.1, 2, 0
                             //|CASCADE_FIND_BIGGEST_OBJECT
                             //|CASCADE_DO_ROUGH_SEARCH
                             |CASCADE_SCALE_IMAGE,
                             cv::Size(30, 30) );
    if( tryflip )
    {
        flip(smallImg, smallImg, 1);
        cascade.detectMultiScale( smallImg, faces2,
                                 1.1, 2, 0
                                 //|CASCADE_FIND_BIGGEST_OBJECT
                                 //|CASCADE_DO_ROUGH_SEARCH
                                 |CASCADE_SCALE_IMAGE,
                                 cv::Size(30, 30) );
        for( vector<cv::Rect>::const_iterator r = faces2.begin(); r != faces2.end(); ++r )
        {
            faces.push_back(cv::Rect(smallImg.cols - r->x - r->width, r->y, r->width, r->height));
        }
    }
    t = (double)getTickCount() - t;
    //printf( "detection time = %g ms\n", t*1000/getTickFrequency());
    for ( size_t i = 0; i < faces.size(); i++ )
    {
        cv::Rect r = faces[i];
        Mat smallImgROI;
        vector<cv::Rect> nestedObjects;
        cv::Point center;
        Scalar color = colors[i%8];
        int radius;
        double aspect_ratio = (double)r.width/r.height;
        if( 0.75 < aspect_ratio && aspect_ratio < 1.3 )
        {
            center.x = cvRound((r.x + r.width*0.5)*scale);
            center.y = cvRound((r.y + r.height*0.5)*scale);
            radius = cvRound((r.width + r.height)*0.25*scale);
            circle( img, center, radius, color, 3, 8, 0 );
        }
        else
            rectangle( img, cv::Point(cvRound(r.x*scale), cvRound(r.y*scale)),
                      cv::Point(cvRound((r.x + r.width-1)*scale), cvRound((r.y + r.height-1)*scale)),
                      color, 3, 8, 0);
        if( nestedCascade.empty() )
            continue;
        smallImgROI = smallImg( r );
        nestedCascade.detectMultiScale( smallImgROI, nestedObjects,
                                       1.1, 2, 0
                                       //|CASCADE_FIND_BIGGEST_OBJECT
                                       //|CASCADE_DO_ROUGH_SEARCH
                                       //|CASCADE_DO_CANNY_PRUNING
                                       |CASCADE_SCALE_IMAGE,
                                       cv::Size(30, 30) );
        for ( size_t j = 0; j < nestedObjects.size(); j++ )
        {
            cv::Rect nr = nestedObjects[j];
            center.x = cvRound((r.x + nr.x + nr.width*0.5)*scale);
            center.y = cvRound((r.y + nr.y + nr.height*0.5)*scale);
            radius = cvRound((nr.width + nr.height)*0.25*scale);
            circle( img, center, radius, color, 3, 8, 0 );
        }
    }
}

