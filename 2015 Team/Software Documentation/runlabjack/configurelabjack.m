function [ ljudObj, ljhandle, NUMCHANNELS, SCANRATE, DELAY, NUMSCANS...
  ] = configurelabjack( ljudObj, input_decimal, waveforms )
%configures the labjack for the amount of analoginputs used, and the amount
% of full waveforms to be by the labjack for better data consistency. 
% (waveform division based off of 60 Hz signal). input_vec is a decimal 
% that represents a 16 bit binary number.
% This decimal number is the sum of each analog inputs binary value.
% For example, to configure to AIN0 through AIN3 as on and
% the rest off. The binary representation of the decimal is
% 0000 0000 0000 1111. Which in turn means the input_decimal in 1 + 2 + 4 +
% 8 = 15

binary_string = dec2bin (input_decimal); %converts decimal configuration number
%to a binary represenation for use with code

%setting parameters for use in configuration

ii=0;
kk=0;
ioType = 0;
channel = 0;
dblValue = 0;
dblCommBacklog = 0;
dblUDBacklog = 0;

%getting the number of channels based off the decimal input
NUMCHANNELS = 0;
for ii = 1:length(binary_string)
    if binary_string(ii) == '1'
        NUMCHANNELS = NUMCHANNELS + 1;
    end
end

SCANRATE = floor(50000/NUMCHANNELS);%Sampling rate of each individual input. Max sampling rate for all ports is 50 KHz total


DELAY =( .017 * waveforms); %how many seconds we want to system to run, based on the amount of waveforms we want. Based off ~60 Hz waveforms


NUMSCANS = ceil(NUMCHANNELS * SCANRATE * DELAY); %the expected total number of scans based on scan rate
                 % and number of inputs used = ( number of inputs *
                 % scanRate * delay (in seconds)
                 
NUMSCANS = NUMSCANS + rem(NUMSCANS , NUMCHANNELS); %insuring there is the same amount of samples for each input
                 
              

%values used for error checking
dummyInt = 0;
dummyDouble = 0;
dummyDoubleArray = [0];

%configuring LABJACK
try % start of actual implementation
    
    disp('Initiating LABJACK Configuration')
    
    % displaying settings and configuring IO-------------------------------
    
    %Read and display driver information
    disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])
    
    %Open the LabJack U3-LV
    [ljerror, ljhandle] = ljudObj.OpenLabJack( LabJack.LabJackUD.DEVICE.U3 , LabJack.LabJackUD.CONNECTION.USB, '0',true,0);
    
    %Display hardware version of given U3 using devices assigned handle
    [ljerror, dblValue] = ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.GET_CONFIG, LabJack.LabJackUD.CHANNEL.HARDWARE_VERSION, 0, 0);
    disp(['U3 Hardware Version = ' num2str(dblValue)])
    
    [ljerror, dblValue] = ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.GET_CONFIG, LabJack.LabJackUD.CHANNEL.FIRMWARE_VERSION, 0, 0);
    disp(['U3 Firmware Version = ' num2str(dblValue)])
    
    %resetting the pin_configuration to default
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PIN_CONFIGURATION_RESET, 0, 0, 0);
    
    %configuring analog, single ended inputs (range of 0V to 2.4V), the rest will
    %be configured to digital. 
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PUT_ANALOG_ENABLE_PORT, 0, input_decimal, int32(16));
    
    %configuring sample collection-----------------------------------------
    
    %Configuring the stream:
    %Setting the scan rate.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.STREAM_SCAN_FREQUENCY, SCANRATE, 0, 0);
    
    %Give the driver a 5 second buffer (scanRate * 4 channels * 5 seconds).
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.STREAM_BUFFER_SIZE, SCANRATE*NUMCHANNELS*5, 0, 0);
    
    %Configure reads to retrieve whatever data is available without waiting (wait mode LJ_swNONE).
    LJ_swSLEEP = ljudObj.StringToConstant('LJ_swSLEEP');
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.STREAM_WAIT_MODE, LJ_swSLEEP, 0, 0);
    
    %Define the scan list based on analog inputs
    
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.CLEAR_STREAM_CHANNELS, 0, 0, 0, 0);
    for ii = 0 : length(binary_string) - 1
        if binary_string(ii + 1) == '1'
            ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.ADD_STREAM_CHANNEL, ii, 0, 0, 0);
        end
    end

    %small execution to test for errors
    ljudObj.GoOne(ljhandle);
    
    %beginning error checking
    [ljerror, ioType, channel, dblValue, dummyInt, dummyDouble] = ljudObj.GetFirstResult(ljhandle, ioType, channel, dblValue, dummyInt, dummyDouble);
    finished = false;
    
    %error checking loop
    while finished == false
        try
            [ljerror, ioType, channel, dblValue, dummyInt, dummyDouble] = ljudObj.GetNextResult(ljhandle, ioType, channel, dblValue, dummyInt, dummyDouble);
        catch e
            if(isa(e, 'NET.NetException'))
                eNet = e.ExceptionObject;
                if(isa(eNet, 'LabJack.LabJackUD.LabJackUDException'))
                    if(eNet.LJUDError == LabJack.LabJackUD.LJUDERROR.NO_MORE_DATA_AVAILABLE)
                        finished = true;
                    end
                end
            end
            %Report non NO_MORE_DATA_AVAILABLE error.
            if(finished == false)
                throw(e)
            end
        end
    end
    
catch e
    showErrorMessage(e)

end

