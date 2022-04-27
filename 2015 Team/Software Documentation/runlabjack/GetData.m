function [ adblData,actualScanRate,numScansRequested ] = GetData( ljudObj, ljhandle, NUMCHANNELS, SCANRATE, NUMSCANS )
%reads in the data from the labjack and outputs an .NET array of data
%points or an error indication if necessary

dblValue = 0;
dblCommBacklog = 0;
dblUDBacklog = 0;
dummyDoubleArray = [0];
numScansRequested = 0;
    
    %starting the actual streaming of data
    [ljerror, actualScanRate] = ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.START_STREAM, 0, 0, 0);
    
    %actual scan rate might be different depending on the LabJacks internal
    %clock
    disp(['User Defined Scan Rate = ' num2str(SCANRATE)])
    disp(['Actual Scan Rate = ' num2str(actualScanRate)])
    disp(['Actual Sample Rate = ' num2str(actualScanRate * NUMCHANNELS)]) %since samplingrate = #channels * scanrate
    
    %for ii=1:loopAmount
    
    while numScansRequested == 0
        
        %initiate an array to store data
        adblData = NET.createArray('System.Double', NUMCHANNELS*NUMSCANS);
        
        numScansRequested = NUMSCANS ;
        
        %put all the data from the stream into the array created
        [ljerror, numScansRequested] = ljudObj.eGetPtr(ljhandle, LabJack.LabJackUD.IO.GET_STREAM_DATA, LabJack.LabJackUD.CHANNEL.ALL_CHANNELS, numScansRequested, adblData);
        
        %%disp(['Iteration # = ' num2str(ii)])
        disp(['Number Of Data Points Read = ' num2str(numScansRequested)])
        
        %retrieve communications backlog
        [ljerror, dblCommBacklog] = ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.GET_CONFIG, LabJack.LabJackUD.CHANNEL.STREAM_BACKLOG_COMM, dblCommBacklog, dummyDoubleArray);
        
        %retrieve UD backlog
        [ljerror, dblUDBacklog] = ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.GET_CONFIG, LabJack.LabJackUD.CHANNEL.STREAM_BACKLOG_UD, dblUDBacklog, dummyDoubleArray);
        
        
        
        
    end
    
    %Stopping the stream
    ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.STOP_STREAM, 0, 0, 0);
    
    disp( 'Done Logging Data Points' )

end

