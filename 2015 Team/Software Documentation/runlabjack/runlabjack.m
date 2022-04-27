%script to run the labjack
clear
clc

ljasm = NET.addAssembly('LJUDDotNet'); %Make the UD .NET assembly visible for use
ljudObj = LabJack.LabJackUD.LJUD;

prompt = 'Please input LABJACK pin configuration decimal value : ';

input_decimal = input(prompt);

prompt = 'How many periods should we analyze? : ';

waveforms = input(prompt);

%running actual program with user defined parameters

[ ljudObj, ljhandle, NUMCHANNELS, SCANRATE, DELAY, NUMSCANS...
  ] = configurelabjack( ljudObj, input_decimal, waveforms );

[ adblData,actualScanRate, numScansRequested ] = GetData( ljudObj,...
    ljhandle, NUMCHANNELS, SCANRATE, NUMSCANS );

[ viMatrix ] = AnalyzeData( adblData, NUMCHANNELS, actualScanRate, DELAY, numScansRequested );

