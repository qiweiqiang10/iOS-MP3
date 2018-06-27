//
//  ViewController.m
//  TestNewR
//
//  Created by PrimeCloud on 2018/6/22.
//  Copyright © 2018年 QiZhuo. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "MLAudioRecorder.h"
#import "CafRecordWriter.h"
#import "AmrRecordWriter.h"
#import "Mp3RecordWriter.h"
#import "MLAudioMeterObserver.h"


@interface ViewController ()<AVAudioPlayerDelegate,AVAudioRecorderDelegate>


@property (nonatomic, strong) MLAudioRecorder *recorder;
@property (nonatomic, strong) CafRecordWriter *cafWriter;
@property (nonatomic, strong) AmrRecordWriter *amrWriter;
@property (nonatomic, strong) Mp3RecordWriter *mp3Writer;

@property (nonatomic, strong) MLAudioMeterObserver *meterObserver;

@property (retain, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    CafRecordWriter *writer = [[CafRecordWriter alloc]init];
    writer.filePath = [path stringByAppendingPathComponent:@"record.caf"];
    self.cafWriter = writer;

    AmrRecordWriter *amrWriter = [[AmrRecordWriter alloc]init];
    amrWriter.filePath = [path stringByAppendingPathComponent:@"record.amr"];
    amrWriter.maxSecondCount = 60;
    amrWriter.maxFileSize = 1024*256;
    self.amrWriter = amrWriter;

    Mp3RecordWriter *mp3Writer = [[Mp3RecordWriter alloc]init];
    mp3Writer.filePath = [path stringByAppendingPathComponent:@"record.mp3"];
//    mp3Writer.maxSecondCount = 60;
//    mp3Writer.maxFileSize = 1024*256;
    mp3Writer.maxSecondCount = 300;
    mp3Writer.maxFileSize = 1024*256 * 100;
    self.mp3Writer = mp3Writer;

    MLAudioMeterObserver *meterObserver = [[MLAudioMeterObserver alloc]init];
    meterObserver.actionBlock = ^(NSArray *levelMeterStates,MLAudioMeterObserver *meterObserver){
        DLOG(@"volume:%f",[MLAudioMeterObserver volumeForLevelMeterStates:levelMeterStates]);
    };
    meterObserver.errorBlock = ^(NSError *error,MLAudioMeterObserver *meterObserver){
        [[[UIAlertView alloc]initWithTitle:@"错误" message:error.userInfo[NSLocalizedDescriptionKey] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"知道了", nil]show];
    };
    self.meterObserver = meterObserver;

    MLAudioRecorder *recorder = [[MLAudioRecorder alloc]init];
    __weak __typeof(self)weakSelf = self;
    recorder.receiveStoppedBlock = ^{
//        [weakSelf.recordButton setTitle:@"Record" forState:UIControlStateNormal];
        weakSelf.meterObserver.audioQueue = nil;
    };
    recorder.receiveErrorBlock = ^(NSError *error){
//        [weakSelf.recordButton setTitle:@"Record" forState:UIControlStateNormal];
        weakSelf.meterObserver.audioQueue = nil;

        [[[UIAlertView alloc]initWithTitle:@"错误" message:error.userInfo[NSLocalizedDescriptionKey] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"知道了", nil]show];
    };


    //caf
//            recorder.fileWriterDelegate = writer;
    //        self.filePath = writer.filePath;
    //mp3
        recorder.fileWriterDelegate = mp3Writer;
//        self.filePath = mp3Writer.filePath;

    //amr
//    recorder.bufferDurationSeconds = 0.25;
//    recorder.fileWriterDelegate = self.amrWriter;

    self.recorder = recorder;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//点击录音按钮
- (IBAction)didClickRecordButon:(id)sender {

    [[AVAudioSession sharedInstance]requestRecordPermission:^(BOOL granted) {
        if (granted) {
            NSLog(@"开始录制");
            [self.recorder startRecording];
            self.meterObserver.audioQueue = self.recorder->_audioQueue;
        }
    }];

}
//点击停止按钮
- (IBAction)didClickStopButtonAction:(id)sender {
    [self.recorder stopRecording];
    NSLog(@"%@-------%@",_amrWriter.filePath,_mp3Writer.filePath);

}
//点击播放按钮
- (IBAction)didClickPlayButtonAction:(id)sender {
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if (_audioPlayer.isPlaying) {
        [_audioPlayer stop];
    }
    long long fileLength = [self fileSizeAtPath:_mp3Writer.filePath];
    NSLog(@"%lld",fileLength);
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:self.mp3Writer.filePath] error:nil];
    _audioPlayer.delegate = self;
    [_audioPlayer play];

}

- (long long) fileSizeAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}


@end
