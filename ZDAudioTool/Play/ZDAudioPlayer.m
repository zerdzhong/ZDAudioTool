//
//  ZDAudioPlayer.m
//  ZDAudioTool
//
//  Created by zerd on 15-1-15.
//  Copyright (c) 2015年 zerd. All rights reserved.
//

#import "ZDAudioPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

#define kBufferNumber 3
#define kBufferDurationSeconds .5

@interface ZDAudioPlayer (){
    //manage audio format and audio queue state information
    AudioStreamBasicDescription   mDataFormat;                    // 2
    AudioQueueRef                 mQueue;                         // 3
    AudioQueueBufferRef           mBuffers[kBufferNumber];        // 4
    AudioFileID                   mAudioFile;                     // 5
//    UInt32                        bufferByteSize;                 // 6
    SInt64                        mCurrentPacket;                 // 7
    UInt32                        mNumPacketsToRead;              // 8
    AudioStreamPacketDescription  *mPacketDescs;                  // 9
    bool                          mIsRunning;                     // 10
}

@end

@implementation ZDAudioPlayer

- (instancetype)initWithFilePath:(NSString *)filePath{
    if (self = [super init]) {
        [self createQueueForFile:filePath];
    }
    
    return self;
}

- (void)play{
    
    if (mIsRunning) {
        return;
    }
    
    mCurrentPacket = 0;

    for (int i = 0; i < kBufferNumber; ++i) {
        HandleOutputBuffer((__bridge void *)(self), mQueue, mBuffers[i]);
    }
    
    AudioQueueStart(mQueue, NULL);
//    do {                                               // 5
//        
//        CFRunLoopRunInMode (kCFRunLoopDefaultMode, 0.25, false);
//        
//    } while (mIsRunning);
//    
//    CFRunLoopRunInMode (kCFRunLoopDefaultMode, 1, false);
    
}

- (void)createQueueForFile:(NSString *)filePath{
    CFURLRef audioFile = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
    if (!audioFile) {
        NSLog(@"can't parse file path");
    }
    
    AudioFileOpenURL(audioFile, kAudioFileReadPermission, 0, &mAudioFile);
    
    CFRelease(audioFile);
    
    UInt32 size = sizeof(mDataFormat);
    AudioFileGetProperty(mAudioFile, kAudioFilePropertyDataFormat, &size, &mDataFormat);
    
    [self setUpNewQueue];
}

- (void)setUpNewQueue{
    AudioQueueNewOutput(&mDataFormat, HandleOutputBuffer, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &mQueue);
    
//    Setting playback audio queue buffer size and number of packets to read
//     we need to calculate how many packets we read at a time, and how big a buffer we need
    
    UInt32 maxPacketSize;
    UInt32 size = sizeof(maxPacketSize);
    
    AudioFileGetProperty(mAudioFile,kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize);
    // adjust buffer size to represent about a half second of audio based on this format
    UInt32 bufferByteSize = [self deriveBufferSizeWithDesc:&mDataFormat andSeconds:kBufferDurationSeconds andMaxPacketSize:maxPacketSize];
    
    mNumPacketsToRead = bufferByteSize / maxPacketSize;
    
//    Setting a magic cookie for a playback audio queue
    size = sizeof(UInt32);
    OSStatus result = AudioFileGetPropertyInfo (mAudioFile, kAudioFilePropertyMagicCookieData, &size, NULL);
    
    if (!result && size) {
        char* cookie = (char *) malloc (size);
        AudioFileGetProperty (mAudioFile, kAudioFilePropertyMagicCookieData, &size, cookie);
        AudioQueueSetProperty(mQueue, kAudioQueueProperty_MagicCookie, cookie, size);
        free(cookie);
    }
    
//    AudioQueueAddPropertyListener(mQueue, kAudioQueueProperty_IsRunning, isRunningProc, (__bridge void *)(self));
    
    bool isFormatVBR = (mDataFormat.mBytesPerPacket == 0 || mDataFormat.mFramesPerPacket == 0);
    for (int i = 0; i < kBufferNumber; ++i) {
        AudioQueueAllocateBufferWithPacketDescriptions(mQueue, bufferByteSize, (isFormatVBR ? mNumPacketsToRead : 0), &mBuffers[i]);
//        HandleOutputBuffer((__bridge void *)(self), mQueue, mBuffers[i]);
    }
    
    AudioQueueSetParameter(mQueue, kAudioQueueParam_Volume, 1.0);
}

- (void)disposeQueue{
    AudioQueueDispose (mQueue, true);
    
    AudioFileClose (mAudioFile);            // 4
    free (mPacketDescs);
}

#pragma mark- AudioQueue 需要的内部方法
- (UInt32)deriveBufferSizeWithDesc:(const AudioStreamBasicDescription *)desc andSeconds:(float)seconds andMaxPacketSize:(UInt32)maxPacketSize{
    // we're really trying to get somewhere between 16K and 64K buffers, but not allocate too much if we don't need it
    static const int maxBufferSize = 0x10000; // limit size to 64K
    static const int minBufferSize = 0x4000; // limit size to 16K
    
    UInt32 outBufferSize = 0;
    
    if (desc->mFramesPerPacket) {
        Float64 numPacketsForTime = desc->mSampleRate / desc->mFramesPerPacket * seconds;
        outBufferSize = numPacketsForTime * maxBufferSize;
    } else {
        // if frames per packet is zero, then the codec has no predictable packet == time
        // so we can't tailor this (we don't know how many Packets represent a time period
        // we'll just return a default buffer size
        outBufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    // we're going to limit our size to our default
    if (outBufferSize > maxBufferSize && outBufferSize > maxPacketSize)
        outBufferSize = maxBufferSize;
    else {
        // also make sure we're not too small - we don't want to go the disk for too small chunks
        if (outBufferSize < minBufferSize)
            outBufferSize = minBufferSize;
    }
    
    return outBufferSize;
}

#pragma mark- AudioQueue callback
static void HandleOutputBuffer (void                 *aqData,                 // 1
                                AudioQueueRef        inAQ,                    // 2
                                AudioQueueBufferRef  inBuffer                 // 3
){
    //read data from an audio file and place it in an audio queue buffer
    ZDAudioPlayer *pAqData = (__bridge ZDAudioPlayer *)aqData;
    UInt32 numBytesReadFromFile;
    UInt32 numPackets = pAqData->mNumPacketsToRead;
    AudioFileReadPacketData(pAqData->mAudioFile,false,&numBytesReadFromFile,pAqData->mPacketDescs,pAqData->mCurrentPacket,&numPackets,inBuffer->mAudioData);
    if (numPackets > 0) {
        inBuffer->mAudioDataByteSize = numBytesReadFromFile;
        inBuffer->mPacketDescriptionCount = numPackets;
        AudioQueueEnqueueBuffer(pAqData->mQueue, inBuffer, (pAqData->mPacketDescs ? numPackets : 0), pAqData->mPacketDescs);
        pAqData->mCurrentPacket += numPackets;
    }else{
        AudioQueueStop(pAqData->mQueue, false);
    }
}

void isRunningProc(void *              inUserData,
                   AudioQueueRef           inAQ,
                   AudioQueuePropertyID    inID
                   ){

}

@end
