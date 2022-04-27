function [ viMatrix ] = AnalyzeData( adblData, NUMCHANNELS, actualScanRate, DELAY, numScansRequested )

%puts the data within the adblData .NET vector into a vi matrix for
%analysis, then calculates and outputs amplitude, phase calculations
%between v and i, power factor

%putting streamed data into a MATLAB matrix

viMatrix = zeros(ceil(numScansRequested/NUMCHANNELS), NUMCHANNELS);

for x = 1:(numScansRequested/NUMCHANNELS)
    
    for y = 1 : NUMCHANNELS

    viMatrix( x , y ) = adblData(NUMCHANNELS*(x-1) + y );
    
    end
end

%calculating the number of datapoints in a single waveform of 60 Hz
% = amount of seconds for a single 60 Hz waveform (1/60) divide by 
% amounts of seconds each data point represents (1/actualscanrate)

%numscansperperwaveform = actualScanRate/60;

%converting voltage DAQ readings to fiiltered actual values in circuit
for x = 1 : NUMCHANNELS/2
    viMatrix(:, 2*x-1) = (viMatrix(:,2*x-1) - 1.2) * 10;
    
    VAvg = mean(viMatrix(:, 2*x-1)); %finding the average current value found to account for inaccuracies
    
    viMatrix(:,2*x-1) = viMatrix(:,2*x-1) -VAvg;
    
    %performing basic filtering via FFT
    Vfft = fft( viMatrix(:,2*x-1) );
    
    meanforVfft = mean(abs(Vfft));
    
    Vfftthreshold = .3 * meanforVfft;
    
    vector = find((abs(Vfft) < Vfftthreshold));
    
    Vfft(vector) = 0;
    
    viMatrix(:,2*x-1) = ifft(Vfft);
    
end

%converting current DAQ readings to actual values in circuit

%converting to voltage output of ACS712 , finding the difference between
%value and zero current point of ACS712(2.5 volts), then using given gain figure 
% from allegro (185 mV/A), calculating current. Theoreticically due to
% design, the max current magnitude should be 2.162 Amps
for y = 1 : NUMCHANNELS/2
    viMatrix(:,2*y) = (viMatrix(:,2*y) + 6.308) / 3; %converting back to ACS712 output
    
    viMatrix(:,2*y) = viMatrix(:,2*y) - 2.5; %finding difference in voltages
    
    viMatrix(:,2*y) = viMatrix(:,2*y) / .185;%calculating current from the difference
    
    IAvg = mean(viMatrix(:, 2*y)); %finding the average current value found to account for inaccuracies
    
    viMatrix(:,2*y) = viMatrix(:,2*y) -IAvg;
    
    %performing basic filtering via FFT
    Ifft = fft( viMatrix(:,2*y) );
    
    meanforIfft = mean(abs(Ifft));
    
    Ifftthreshold = meanforIfft;
    
    Ifilter = find(abs(Ifft) < Ifftthreshold);
    
    Ifft(Ifilter) = 0;
    
    viMatrix(:,2*y) = ifft(Ifft);
    
end

%absVImatrix = abs(viMatrix); %creating an absolute matrix for finding zero crossing points of voltage and current
%in theory, the absolute matrix is minimum at the zero crossing points. The
%zero crossing points can then be used to calculate

for ii = 1:NUMCHANNELS/2
    %plotting data points onto figure
    figure(ii)
    
    
    jj = 1 : numScansRequested/NUMCHANNELS;
    [ax, Vplot{ii}, Iplot{ii}] = plotyy(jj, viMatrix(jj, ii * 2 - 1), jj, viMatrix(jj, ii * 2),'plot','plot');
    grid on
    ylabel(ax(1), 'Voltage(V)')
    ylabel(ax(2), 'Current(A)')
    xlabel( 'Sample Number' )
    set(Vplot{ii}, 'LineStyle', '-')
    set(Iplot{ii}, 'LineStyle', '-')
    set(Vplot{ii}, 'LineWidth', 2)
    set(Iplot{ii}, 'LineWidth', 1)
    title(['V-I Values for Sensor ' num2str(ii)])
    
    sprintf('\n\n'); %begin printing out values to screen
    disp(['----------------Sensor ' num2str(ii) ' Data----------------']);
    
    %find phase angle between signals
    [c, lags]= xcorr(viMatrix(jj, ii*2 -1),viMatrix(jj,ii * 2)); %correlating the two signals
    [maxC,I] = max(c);%finding the point of max correlation
    lagtime = lags(I); %finding the lagtime in time units
    
    conversion = 1/actualScanRate; %how many seconds per time unit = 1/actualScanRate
    
    %converting lagtime into seconds
    secondslagtime = lagtime*conversion;
 
    disp(['VI lagtime in seconds=' num2str(secondslagtime)])
    
    %converting seconds to radians
    
    angleconversion = 120 * pi; % 120 pi radians per second for a 60 Hz signal
    phase = secondslagtime * angleconversion; %how large the angle is in terms of radians
    
    disp(['Calculated VI-Phase via correlation = ' num2str(phase) ' radians'])
    powerfactor = cos(phase);
    disp(['Calculated Power Factor = ' num2str( powerfactor)])
    
    Vrms = rms(viMatrix(jj,ii*2 - 1));
    Irms = rms(viMatrix(jj,ii*2));
    
    disp(['Vrms = ' num2str(Vrms)]);
    disp(['Irms = ' num2str(Irms)]);
    
    
end


end

