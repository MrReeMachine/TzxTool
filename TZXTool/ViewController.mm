//
//  ViewController.m
//  TZXTool
//
//  Created by Richard Baxter on 11/11/2019.
//  Copyright © 2019 OhCrikey!. All rights reserved.
//

#import "ViewController.h"
#import "TZXFile.h"

@implementation ViewController

NSString *g_strFileLoadedFileName = @"";
TZXFile *g_pTzxFile = NULL;
char *g_pWavAudioData = NULL;
BOOL g_bIsPlaying = false;

NSSound *g_pAudio = NULL;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self refreshDisplay];
    [self updatePlaybackUI];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self  selector:@selector(onTick:) userInfo:nil repeats:true];
    }


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

-(void)onTick:(NSTimer *)timer
{
    [self updatePlaybackUI];
}

- (void)refreshDisplay
{
    if(g_pTzxFile)
    {
        [_fileNameLabel setStringValue:g_strFileLoadedFileName ];
        
        
    } else {
        [_fileNameLabel setStringValue:@"No File Loaded" ];
        
    }
    [_tableView reloadData];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if(g_pTzxFile)
    {
        TZXBlock *pBlock = g_pTzxFile->GetBlockPtr((int)row);
        float time = pBlock->GetAudioBufferOffsetLocationInSeconds()+0.001f;
        _timeSlider.doubleValue = time;
        g_pAudio.currentTime = time;
        return true;
    }
    return false;
}

-(void)updatePlaybackUI
{
    // Update volume label and also volume of playback
    int volume = [_volumeSlider intValue ];
    float vol = ((float)volume)/100.0f;
    if(g_pAudio)
    {
        NSString *timeString = [NSString stringWithFormat:@"%0.1f / %0.1f", [g_pAudio currentTime], [g_pAudio duration]];
        [_timeLabel setStringValue:timeString];
        g_pAudio.volume = vol;
        
        _timeSlider.doubleValue = g_pAudio.currentTime;
        
        int block = [self calculateCurrentPlaybackBlock];
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:block] byExtendingSelection:false];
    } else {
        [_timeLabel setStringValue:@"-/-"];
    }
    [_volumeLabel setStringValue:[NSString stringWithFormat:@"%d%%",volume]];
}

-(int)calculateCurrentPlaybackBlock
{
    if(g_pTzxFile)
    {
        int currentBlock = 0;
        int blockCount = g_pTzxFile->GetBlockCount();
        for(int i=0;i<blockCount;i++)
        {
            TZXBlock *pBlock = g_pTzxFile->GetBlockPtr(i);
            if(g_pAudio.currentTime >= pBlock->GetAudioBufferOffsetLocationInSeconds())
            {
                currentBlock = i;
            } else {
                return currentBlock;
            }
        }
        return currentBlock;
    }
    return -1;
}



- (IBAction)onOpenButtonClicked:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:false];
    [panel setCanChooseDirectories:false];
    [panel setCanChooseFiles:true];
    [panel setFloatingPanel:true];
    NSInteger result = [panel runModal];
    
    g_bIsPlaying = false;
    if(g_pAudio)
    {
        [g_pAudio stop];
    }
    g_pAudio = NULL;
    
    if(result == NSModalResponseOK)
    {
        // Load the file
        NSArray *ar = [panel URLs];
        NSLog(@"%s", [[ar objectAtIndex:0] fileSystemRepresentation]);
        NSString *str = [NSString stringWithUTF8String:[[ar objectAtIndex:0] fileSystemRepresentation]] ;
        [_fileNameLabel setStringValue:@"No File Loaded" ];
        g_strFileLoadedFileName = @"";
        
        // Load the data for the file into memory...
        FILE *hFile = NULL;
        hFile = fopen([[ar objectAtIndex:0] fileSystemRepresentation], "rb");
        if(hFile == NULL)
        {
            printf("Error reading input file: %s\n", [[ar objectAtIndex:0] fileSystemRepresentation]);
            
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            //[alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Error opening file!"];
            [alert setInformativeText:@"There was an error opening the file, the file open action has been terminated."];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert runModal];
            
//            if ([alert runModal] == NSAlertFirstButtonReturn)
//            {
//            }
            [self refreshDisplay];
            return;
        }

        // Calculate the memory required to read the file and allocate
        fseek(hFile, SEEK_SET, SEEK_END);
        unsigned int nFileLength = (unsigned int)ftell(hFile);
        fseek(hFile, SEEK_SET, SEEK_SET);

        if(nFileLength < 2)
        {
            printf("Input file is empty\n");
            fclose(hFile);
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            //[alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Error opening file!"];
            [alert setInformativeText:@"The file is too small to be either a tzx or tap file. The file open action has been terminated."];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert runModal];
            [self refreshDisplay];
            return;
        }
        
        char *pData = new char[nFileLength];
        if(pData==NULL)
        {
            printf("Couldn't allocate %d bytes of memory.\n", nFileLength);
            fclose(hFile);
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            //[alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Error opening file!"];
            [alert setInformativeText:@"Could not allocate enough memory to open the file. The file open action has been terminated."];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert runModal];
            [self refreshDisplay];
            return;
        }
        
        TZXFile *pTzxFile = new TZXFile();
        if(pTzxFile==NULL)
        {
            printf("Couldn't allocate enough memory for TzxFile object.\n");
            fclose(hFile);
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            //[alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Error opening file!"];
            [alert setInformativeText:@"Could not allocate enough memory to open the file. The file open action has been terminated."];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert runModal];
            [self refreshDisplay];
            return;
        }
        
        // Read the file into memory
        int read = (int)fread(pData, nFileLength, 1, hFile);
        if(read != 1)
        {
            printf("Couldn't read the tzx file.\n");
            fclose(hFile);
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            //[alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Error opening file!"];
            [alert setInformativeText:@"Could not successfully the file into memory? The file open action has been terminated."];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert runModal];
            
            delete pTzxFile;
            if(g_pTzxFile) delete g_pTzxFile;
            g_pTzxFile = NULL;
            [self refreshDisplay];
            return;
        }
        
        EFileType result = pTzxFile->DecodeFile((unsigned char *)pData, nFileLength);
        if(result==FileTypeUndetermined)
        {
            printf("Couldn't decode the tzx file.\n");
            fclose(hFile);
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            //[alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Error opening file!"];
            [alert setInformativeText:@"Could not successfully decode the selected file perhaps the file is not a .TZX or .TAP file? The file open action has been terminated."];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert runModal];
            
            delete pTzxFile;
            if(g_pTzxFile) delete g_pTzxFile;
            g_pTzxFile = NULL;
            [self refreshDisplay];
            return;
        }
        
        if(g_pTzxFile) delete g_pTzxFile;
        g_pTzxFile = pTzxFile;
        fclose(hFile);
        [_fileNameLabel setStringValue:str ];
        g_strFileLoadedFileName = str;
        
        // Finally generate the audio data
        g_pTzxFile->GenerateAudioData();
        
        [self BuildWavAudioBufferFromAudioData];
        [self refreshDisplay];
        
        [_timeSlider setMaxValue:[g_pAudio duration]];

        return;
    }
}

-(void) BuildWavAudioBufferFromAudioData
{
    g_pTzxFile->WriteAudioToUncompressedWavFile("Temp.wav");
    g_pAudio = [[NSSound alloc]initWithContentsOfFile:@"Temp.wav" byReference:true];
    [g_pAudio play];
    [g_pAudio pause];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(g_pTzxFile)
    {
        return g_pTzxFile->GetBlockCount();
    } else {
        return 0;
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return false;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(g_pTzxFile)
    {
        int maxBlocks = g_pTzxFile->GetBlockCount();
        if(rowIndex < maxBlocks)
        {
            if([aTableColumn.identifier isEqualToString:@"ID"])
            {
                NSString *retString = [NSString stringWithFormat:@"Block %i",(int)rowIndex];
                return retString;
            } else if([aTableColumn.identifier isEqualToString:@"Description"])
            {
                TZXBlock *pBlock = g_pTzxFile->GetBlockPtr((int)rowIndex);
                NSString *retString = [NSString stringWithUTF8String:pBlock->GetDescription()];
                return retString;
            } else if([aTableColumn.identifier isEqualToString:@"Time"])
            {
                TZXBlock *pBlock = g_pTzxFile->GetBlockPtr((int)rowIndex);
                NSString *retString = [NSString stringWithFormat:@"%0.1fs",pBlock->GetAudioBufferOffsetLocationInSeconds()];
                return retString;
            }
            

        }
    }
    return @"Error";
    
}
- (IBAction)rewindButtonPressed:(id)sender {
    if(g_pAudio)
    {
        g_pAudio.currentTime = 0.0;
    }
}

- (IBAction)skipBackButtonPressed:(id)sender {
    int block = [self calculateCurrentPlaybackBlock];
    block = block -1;
    if(block < 0) block = 0;
    if(g_pTzxFile)
    {
        TZXBlock *pBlock = g_pTzxFile->GetBlockPtr(block);
        g_pAudio.currentTime = pBlock->GetAudioBufferOffsetLocationInSeconds()+0.001f;
    }
}

- (IBAction)playPauseButtonPressed:(id)sender
{
    if(g_bIsPlaying)
    {
        [g_pAudio pause];
        g_bIsPlaying = false;
        [_playPauseButton setTitle: @">"];
    } else {
        //if([g_pAudio currentTime] > 0.0)
        //{
        if(!g_pAudio.isPlaying)
        {
            [g_pAudio play];
            [g_pAudio pause];
        }
            [g_pAudio resume];
        //} else {
            //[g_pAudio play];
        //}
        g_bIsPlaying = true;
        [_playPauseButton setTitle: @"||"];
    }
}
- (IBAction)skipForwardButtonPressed:(id)sender {
    int block = [self calculateCurrentPlaybackBlock];
    if(g_pTzxFile)
    {
        block = block + 1;
        if(block > (g_pTzxFile->GetBlockCount()-1)) return;
        TZXBlock *pBlock = g_pTzxFile->GetBlockPtr(block);
        g_pAudio.currentTime = pBlock->GetAudioBufferOffsetLocationInSeconds()+0.001f;
    }
}
- (IBAction)volumeSliderChanged:(id)sender
{
    
    [self updatePlaybackUI];
}
- (IBAction)timeSliderChanged:(id)sender {
    if(g_pAudio)
    {
        g_pAudio.currentTime = _timeSlider.doubleValue;
    }
}

@end
