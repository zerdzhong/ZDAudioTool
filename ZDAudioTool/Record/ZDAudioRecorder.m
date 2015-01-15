//
//  ZDAudioRecorder.m
//  ZDAudioTool
//
//  Created by zerd on 15-1-13.
//  Copyright (c) 2015年 zerd. All rights reserved.
//

#import "ZDAudioRecorder.h"
@import AVFoundation;

#define kBufferNumber 3
#define kBufferDurationSeconds .1

@interface ZDAudioRecorder (){
    //manage the audio format and audio queue state information.
    AudioStreamBasicDescription  mRecordFormat;
    AudioQueueRef                mQueue;
    AudioQueueBufferRef          mBuffers[kBufferNumber];
    AudioFileID                  mRecordFile;
    SInt64                       mCurrentPacket;
    bool                         mIsRunning;
}


@end

@implementation ZDAudioRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark- 外部接口实现
- (void)startRecord:(NSString *)filePath{
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //init audioFormat
        [self setAudioFormat];
        
        //Create the Recording Audio Queue
        AudioQueueNewInput(&mRecordFormat, HandleInputBuffer, (__bridge void *)(self), NULL, kCFRunLoopCommonModes, 0, &mQueue);
        
        //Getting the Full Audio Format from the Audio Queue
        UInt32 dataFormatSize = sizeof (mRecordFormat);
        AudioQueueGetProperty(mQueue, kAudioQueueProperty_StreamDescription, &mRecordFormat, &dataFormatSize);
        
        //create audio file depend recordFormat and filepath
        
        CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)filePath, NULL);
        
        AudioFileCreateWithURL(url, kAudioFileCAFType, &mRecordFormat, kAudioFileFlags_EraseFile, &mRecordFile);
        CFRelease(url);
        
        //copy the cookie first to give the file object as much info as we can about the data going in
        // not necessary for pcm, but required for some compressed audio
        
        [self setMagicCookieToFile];
        
        // allocate and enqueue buffers
        // enough bytes for half a second
        
        UInt32 bufferByteSize = [self deriveBufferSizeWithDesc:&mRecordFormat andSeconds:kBufferDurationSeconds];
        
        for (int i = 0; i < kBufferNumber; ++i) {
            
            AudioQueueAllocateBuffer (mQueue,bufferByteSize,&mBuffers[i]);
            AudioQueueEnqueueBuffer (mQueue,mBuffers[i],0,NULL);
            
        }
        
        //Turn on level metering
        UInt32 on = 1;
        AudioQueueSetProperty(mQueue,kAudioQueueProperty_EnableLevelMetering,&on,sizeof(on));
        
        //start queue
        
        mIsRunning = true;
        mCurrentPacket = 0;
        AudioQueueStart(mQueue, NULL);
//    });
    
}
- (void)stopRecord{
    if (mIsRunning) {
        AudioQueueStop(mQueue, true);
        mIsRunning = false;
    }
}

- (Boolean)isRunning{
    return mIsRunning;
}

#pragma mark- AudioQueue 需要的内部方法
// Determine the size, in bytes, of a buffer necessary to represent the supplied number
// of seconds of audio data.
- (int)deriveBufferSizeWithDesc:(const AudioStreamBasicDescription *)desc andSeconds:(float)seconds{
    
    static const int maxBufferSize = 0x50000;                 // 5
    
    int maxPacketSize = desc->mBytesPerPacket;       // 6
    
    if (maxPacketSize == 0) {                                 // 7
        
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        
        AudioQueueGetProperty (mQueue,
                               kAudioQueueProperty_MaximumOutputPacketSize, // in Mac OS X v10.5, instead use kAudioConverterPropertyMaximumOutputPacketSize
                               &maxPacketSize,
                               &maxVBRPacketSize
                               );
    }
    
    
    
    Float64 numBytesForTime = desc->mSampleRate * maxPacketSize * seconds; // 8
    
    UInt32 size  = (numBytesForTime < maxBufferSize) ? (numBytesForTime) : (maxBufferSize);                     // 9
    
    return size;
}

- (void)setMagicCookieToFile{
    
    OSStatus result = noErr;                                    // 3
    UInt32 cookieSize;                                          // 4

    OSStatus err = AudioQueueGetPropertySize (mQueue,kAudioQueueProperty_MagicCookie,&cookieSize);
    
    if (err == noErr && cookieSize > 0) {
        
        char* magicCookie = (char *) malloc (cookieSize);                       // 6
        
        err = AudioQueueGetProperty (mQueue,kAudioQueueProperty_MagicCookie,magicCookie,&cookieSize);
        
        if (err == noErr){
            result = AudioFileSetProperty (mRecordFile,kAudioFilePropertyMagicCookieData,cookieSize,magicCookie);
        }
        free (magicCookie);                                     // 9
    }
    
}

- (void)setAudioFormat{
    memset(&mRecordFormat, 0, sizeof(mRecordFormat));
    
    
    //    recordFormat.mSampleRate       = 44100.0;               // 3
    mRecordFormat.mSampleRate = [AVAudioSession sharedInstance].sampleRate;
    mRecordFormat.mChannelsPerFrame = (UInt32)[AVAudioSession sharedInstance].inputNumberOfChannels;
    
    mRecordFormat.mFormatID = kAudioFormatLinearPCM; // 2
    
    if (mRecordFormat.mFormatID == kAudioFormatLinearPCM)
    {
        // if we want pcm, default to signed 16-bit little-endian
        mRecordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        mRecordFormat.mBitsPerChannel = 16;
        mRecordFormat.mBytesPerPacket = mRecordFormat.mBytesPerFrame = (mRecordFormat.mBitsPerChannel / 8) * mRecordFormat.mChannelsPerFrame;
        mRecordFormat.mFramesPerPacket = 1;
    }
}

#pragma mark- AudioQueue callback

//Recording Audio Queue Callback Declaration,called when an input buffers has been filled.
static void HandleInputBuffer (
                               void                                *aqData,             // 1
                               AudioQueueRef                       inAQ,                // 2
                               AudioQueueBufferRef                 inBuffer,            // 3
                               const AudioTimeStamp                *inStartTime,        // 4
                               UInt32                              inNumPackets,        // 5
                               const AudioStreamPacketDescription  *inPacketDesc        // 6
){
    ZDAudioRecorder *pAqData = (__bridge ZDAudioRecorder *)aqData;
    
    if (inNumPackets > 0 && pAqData->mRecordFormat.mBytesPerPacket != 0) {
        
        //write audio data to file
        OSStatus status = AudioFileWritePackets(pAqData->mRecordFile, false,
                                                inBuffer->mAudioDataByteSize, inPacketDesc,
                                                pAqData->mCurrentPacket, &inNumPackets,
                                                inBuffer->mAudioData);
        if (status == noErr) {
            pAqData->mCurrentPacket += inNumPackets;
        }else{
            NSLog(@"write file error:%d",status);
        }
        
    }
    
    //    Enqueuing an audio queue buffer after writing to disk
    if (pAqData->mIsRunning) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
    
    //
    //  Check metering levels and detect silence
    //
    AudioQueueLevelMeterState meters;
    UInt32 dlen = sizeof(meters);
    OSStatus status = AudioQueueGetProperty(pAqData->mQueue,kAudioQueueProperty_CurrentLevelMeterDB,&meters,&dlen);
    if (status == noErr) {
        if ([pAqData.delegate respondsToSelector:@selector(onRecordPower:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [pAqData.delegate onRecordPower:meters.mAveragePower];
            });
        }
    }else{
        NSLog(@"status:%d",status);
    }
    
    if ([pAqData.delegate respondsToSelector:@selector(onRecordBuffer:bufferSize:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [pAqData.delegate onRecordBuffer:inBuffer->mAudioData bufferSize:inBuffer->mAudioDataByteSize];
        });
    }
    
}

@end
