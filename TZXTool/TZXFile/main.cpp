//
//  main.cpp
//  Tzx2Wav
//
//  Created by Richard Baxter on 31/10/2019.
//  Copyright © 2019 Richard Baxter. All rights reserved.
//

#include <iostream>
#include "TZXFile.h"

TZXFile *g_pTzxFile = NULL;


#define BLOCKSIZE 22050

bool ConvertTzxFileToWav(const char *filePath, const char *outputPath)
{
    //if (g_sndTzxAudio != 0) agk::DeleteSound(g_sndTzxAudio);

    FILE *hFile = NULL;
    hFile = fopen(filePath, "rb");
    if(hFile == NULL)
    {
        printf("Error reading input file: %s\n", filePath);
        return false;
    }
    fseek(hFile, SEEK_SET, SEEK_END);
    unsigned int nFileLength = (unsigned int)ftell(hFile);
    fseek(hFile, SEEK_SET, SEEK_SET);
    
    if(nFileLength < 7)
    {
        printf("Input file is empty\n");
        fclose(hFile);
        return false;
    }

    char *pData = new char[nFileLength];
    if (fread(pData, nFileLength, 1, hFile)==1)
    {
        g_pTzxFile = new TZXFile();
        if(g_pTzxFile->Decode((unsigned char *)pData, nFileLength) != TZX_SUCCESS)
        {
            printf("Error decoding input file: %s\n", filePath);
            delete[] pData;
            fclose(hFile);
            return false;
        }
        g_pTzxFile->GenerateAudioData();
        if(!g_pTzxFile->WriteAudioToUncompressedWavFile(outputPath))
        {
            printf("Error writing output file: %s\n", outputPath);
            delete[] pData;
            fclose(hFile);
            return false;
        }
    } else {
        printf("Error reading input file: %s\n", filePath);
        delete[] pData;
        fclose(hFile);
        return false;
    }

    delete[] pData;
    fclose(hFile);
    return true;
}

bool ConvertTapFileToWav(const char *input, const char *output)
{
    // Load the tap file and turn it into a tzx object
    FILE *hFile = NULL;
    hFile = fopen(input, "rb");
    if(hFile == NULL)
    {
        printf("Error reading input file: %s\n", input);
        return false;
    }
    fseek(hFile, SEEK_SET, SEEK_END);
    unsigned int nFileLength = (unsigned int)ftell(hFile);
    fseek(hFile, SEEK_SET, SEEK_SET);
    
    if(nFileLength < 2)
    {
        printf("Input file is empty\n");
        fclose(hFile);
        return false;
    }
    
    char *pData = new char[nFileLength];
    if (fread(pData, nFileLength, 1, hFile)==1)
    {
        g_pTzxFile = new TZXFile();
        if(g_pTzxFile->DecodeTapFileData((unsigned char *)pData, nFileLength) != TZX_SUCCESS)
        {
            printf("Error decoding input file: %s\n", input);
            delete[] pData;
            fclose(hFile);
            return false;
        }
        g_pTzxFile->GenerateAudioData();
        if(!g_pTzxFile->WriteAudioToUncompressedWavFile(output))
        {
            printf("Error writing output file: %s\n", output);
            delete[] pData;
            fclose(hFile);
            return false;
        }
    } else {
        printf("Error reading input file: %s\n", input);
        delete[] pData;
        fclose(hFile);
        return false;
    }
    
    delete[] pData;
    fclose(hFile);
    return true;
    
}

void DisplayHelp()
{
    printf("Usage:\nTzxConv <inputfile.tzx>\nTzxCov <inputfile.tzx> <outputfile.wav>\n\nIf no output file is specified then the output file will have the same name as the input file but with .wav extension appended to the end.\n");
}

int main(int argc, const char * argv[]) {
    // insert code here...
    printf("TzxConv - (c)2019 Richard Baxter\n\n");
    
    //LoadTzxFile((char *)"Bigfoot.tzx");
    char *output = NULL;
    bool result = false;
    
    if(argc < 2)
    {
        printf("Invalid number of parameters.\n");
        DisplayHelp();
        return 2;
    }
    
    // Convert string to uppercase
    bool istapfile = false;
    char temp[8096];
    strcpy(temp,argv[1]);
    for(int i=0;i<strlen(temp);i++)
    {
        temp[i] = toupper(temp[i]);
    }
    int len = (int)strlen(temp);
    if(strcmp(temp+len-4, ".TAP")==0)
    {
        istapfile = true;
    }
    
    if(argc==2)
    {
        output = new char[strlen(argv[1])+5];
        
        strcpy(output, argv[1]);
        strcat(output,".wav");
        
        if(istapfile)
        {
            result = ConvertTapFileToWav(argv[1], output);
        } else {
            result = ConvertTzxFileToWav(argv[1], output);
        }
        delete[] output;
    } else {
        if(istapfile)
        {
            result = ConvertTapFileToWav(argv[1], argv[2]);
        } else {
            result = ConvertTzxFileToWav(argv[1], argv[2]);
        }
    }
    
    
    if(!result) return 1;
    
    
    printf("File successfully converted.\n");
    return 0;
}
