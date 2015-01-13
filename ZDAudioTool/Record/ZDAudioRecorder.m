//
//  ZDAudioRecorder.m
//  ZDAudioTool Example
//
//  Created by zerd on 15-1-13.
//  Copyright (c) 2015年 zerd. All rights reserved.
//

#import "ZDAudioRecorder.h"


#define kBufferNumber 3
#define kBufferDurationSeconds .5

//structure to manage the audio format and audio queue state information.
typedef struct ZDAudioRecorderState {
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue;
    AudioQueueBufferRef          mBuffers[kBufferNumber];
    AudioFileID                  mAudioFile;
    UInt32                       bufferByteSize;
    SInt64                       mCurrentPacket;
    bool                         mIsRunning;
    __unsafe_unretained ZDAudioRecorder *recorder;
} ZDAudioRecorderState;


//Recording Audio Queue Callback Declaration,called when an input buffers has been filled.
static void HandleInputBuffer (
                               void                                *aqData,             // 1
                               AudioQueueRef                       inAQ,                // 2
                               AudioQueueBufferRef                 inBuffer,            // 3
                               const AudioTimeStamp                *inStartTime,        // 4
                               UInt32                              inNumPackets,        // 5
                               const AudioStreamPacketDescription  *inPacketDesc        // 6
){
    ZDAudioRecorderState *pAqData = (ZDAudioRecorderState *)aqData;
    
    if (inNumPackets > 0 && pAqData->mDataFormat.mBytesPerPacket != 0) {
        
        //write audio data to file
        OSStatus status = AudioFileWritePackets(pAqData->mAudioFile, false,
                              inBuffer->mAudioDataByteSize, inPacketDesc,
                              pAqData->mCurrentPacket, &inNumPackets,
                              inBuffer->mAudioData);
        if (status == noErr) {
            pAqData->mCurrentPacket += inNumPackets;
        }
        
    }
    
    //    Enqueuing an audio queue buffer after writing to disk
    if (pAqData->mIsRunning) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
    
    //
    //  Check metering levels and detect silence
    //
    AudioQueueLevelMeterState meters[1];
    UInt32 dlen = sizeof(meters);
    OSStatus status = AudioQueueGetProperty(pAqData->mQueue,kAudioQueueProperty_CurrentLevelMeterDB,meters,&dlen);
    if (status == noErr) {
        if ([pAqData->recorder.delegate respondsToSelector:@selector(onRecordPower:)]) {
            [pAqData->recorder.delegate onRecordPower:meters[0].mAveragePower];
        }
    }else{
        NSLog(@"status:%d",status);
    }
    
    if ([pAqData->recorder.delegate respondsToSelector:@selector(onRecordBuffer:bufferSize:)]) {
        [pAqData->recorder.delegate onRecordBuffer:inBuffer->mAudioData bufferSize:inBuffer->mAudioDataByteSize];
    }

}

@interface ZDAudioRecorder (){
    ZDAudioRecorderState        audioRecorderState;
    AudioStreamBasicDescription recordFormat;
    AudioFileID					recordFile;
}


@end

@implementation ZDAudioRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        //init audioFormat
        [self setAudioFormat];
        
        //Create the Recording Audio Queue
        AudioQueueNewInput(&recordFormat, HandleInputBuffer, &audioRecorderState, NULL, kCFRunLoopCommonModes, 0, &audioRecorderState.mQueue);
        
        //Getting the Full Audio Format from the Audio Queue
        UInt32 dataFormatSize = sizeof (recordFormat);
        AudioQueueGetProperty(audioRecorderState.mQueue, kAudioQueueProperty_StreamDescription, &recordFormat, &dataFormatSize);
        
        // allocate and enqueue buffers
        // enough bytes for half a second
        
        UInt32 bufferByteSize = [self deriveBufferSizeWithDesc:&recordFormat andSeconds:kBufferDurationSeconds];
        
        for (int i = 0; i < kBufferNumber; ++i) {
            
            AudioQueueAllocateBuffer (audioRecorderState.mQueue,
                                      bufferByteSize,
                                      &audioRecorderState.mBuffers[i]
                                      );
            
            
            
            AudioQueueEnqueueBuffer (audioRecorderState.mQueue,
                                     audioRecorderState.mBuffers[i],
                                     0,
                                     NULL
                                     );
            
        }
        
        //Turn on level metering
        UInt32 on = 1;
        AudioQueueSetProperty(audioRecorderState.mQueue,kAudioQueueProperty_EnableLevelMetering,&on,sizeof(on));
        
        audioRecorderState.recorder = self;
    }
    return self;
}

#pragma mark- 外部接口实现
- (void)startRecord:(NSString *)fileName{
    
    //create audio file depend recordFormat and filepath
    NSString *recordFileString = [NSTemporaryDirectory() stringByAppendingPathComponent: fileName];
    
    CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)recordFileString, NULL);
    
    AudioFileCreateWithURL(url, kAudioFileCAFType, &recordFormat, kAudioFileFlags_EraseFile, &recordFile);
    CFRelease(url);
    
    //copy the cookie first to give the file object as much info as we can about the data going in
    // not necessary for pcm, but required for some compressed audio
    
    [self setMagicCookieToFile];
        
    //start queue
    
    audioRecorderState.mIsRunning = true;
    audioRecorderState.mCurrentPacket = 0;
    AudioQueueStart(audioRecorderState.mQueue, NULL);
    
}
- (void)stopRecord{
    if ([self isRunning]) {
        AudioQueueStop(audioRecorderState.mQueue, true);
        audioRecorderState.mIsRunning = false;
    }
}

- (Boolean)isRunning{
    return audioRecorderState.mIsRunning;
}

#pragma mark- 内部方法
// Determine the size, in bytes, of a buffer necessary to represent the supplied number
// of seconds of audio data.
- (int)deriveBufferSizeWithDesc:(const AudioStreamBasicDescription *)desc andSeconds:(float)seconds{
    
    static const int maxBufferSize = 0x50000;                 // 5
    
    int maxPacketSize = desc->mBytesPerPacket;       // 6
    
    if (maxPacketSize == 0) {                                 // 7
        
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        
        AudioQueueGetProperty (
                               audioRecorderState.mQueue,
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

    OSStatus err = AudioQueueGetPropertySize (audioRecorderState.mQueue,kAudioQueueProperty_MagicCookie,&cookieSize);
    
    if (err == noErr && cookieSize > 0) {
        
        char* magicCookie = (char *) malloc (cookieSize);                       // 6
        
        err = AudioQueueGetProperty (audioRecorderState.mQueue,kAudioQueueProperty_MagicCookie,magicCookie,&cookieSize);
        
        if (err == noErr){
            result = AudioFileSetProperty (recordFile,kAudioFilePropertyMagicCookieData,cookieSize,magicCookie);
        }
        free (magicCookie);                                     // 9
    }
    
}

- (void)setAudioFormat{
    memset(&recordFormat, 0, sizeof(recordFormat));
    
    recordFormat.mFormatID         = kAudioFormatLinearPCM; // 2
    
    recordFormat.mSampleRate       = 44100.0;               // 3
    
    recordFormat.mChannelsPerFrame = 2;                     // 4
    
    recordFormat.mBitsPerChannel   = 16;                    // 5
    
    recordFormat.mBytesPerPacket   = recordFormat.mChannelsPerFrame * sizeof (SInt16);                        // 6
    recordFormat.mBytesPerFrame    = recordFormat.mChannelsPerFrame * sizeof (SInt16);
    
    recordFormat.mFramesPerPacket  = 1;                     // 7
    
//    AudioFileTypeID fileType             = kAudioFileAIFFType;    // 8
    
    recordFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
}

@end
