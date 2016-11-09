%==========================================================================
% Digital and Analog Communication Course
% Written By : Ehsan Misaghi - 8933002
% Course     : Communication Systems - June 2014
%==========================================================================
clear all
clc
close  
%   ---------------
%   A: Setting Parameters
%   ---------------
M = 1024;                          %   QPSK signal constellation
block_size = 8;                 %   size of each ofdm block
cp_len = ceil(0.1*block_size);  %   length of cyclic prefix
no_of_ifft_points = block_size;           %   8 points for the FFT/IFFT
no_of_fft_points = block_size;
%   ---------------------------------------------
%   B:  %   +++++   TRANSMITTER    +++++
%   ---------------------------------------------
%   1.  Generate 1 x 1000 vector of EEG signal from a simulator
eeg = eeg(1000, 1, 250);
data = (eeg - min(eeg)) * 1000;
data_source = floor(data/(max(data)/(M-1)));
figure(1)
stem(data_source); grid on; xlabel('Data Points'); ylabel('Amplitude')
title('Transmitted Data "O"')


%   2.  Perform QPSK modulation
qpsk_modulated_data = pskmod(data_source, M);
scatterplot(qpsk_modulated_data);title('MODULATED TRANSMITTED DATA');

%   3.  Do IFFT on each block
%   Make the serial stream a matrix where each column represents a pre-OFDM
%   block (w/o cyclic prefixing)
%   First: Find out the number of colums that will exist after reshaping
num_cols=length(qpsk_modulated_data)/block_size;
data_matrix = reshape(qpsk_modulated_data, block_size, num_cols);

%   Second: Create empty matrix to put the IFFT'd data
cp_start = block_size-cp_len;
cp_end = block_size;

%   Third: Operate columnwise & do CP
for i=1:num_cols,
    ifft_data_matrix(:,i) = ifft((data_matrix(:,i)),no_of_ifft_points);
    %   Compute and append Cyclic Prefix
    for j=1:cp_len,
       actual_cp(j,i) = ifft_data_matrix(j+cp_start,i);
    end
    %   Append the CP to the existing block to create the actual OFDM block
    ifft_data(:,i) = vertcat(actual_cp(:,i),ifft_data_matrix(:,i));
end

%   4.  Convert to serial stream for transmission
[rows_ifft_data cols_ifft_data]=size(ifft_data);
len_ofdm_data = rows_ifft_data*cols_ifft_data;

%   Actual OFDM signal to be transmitted
ofdm_signal = reshape(ifft_data, 1, len_ofdm_data);
figure(3)
plot(real(ofdm_signal)); xlabel('Time'); ylabel('Amplitude');
title('OFDM Signal');grid on;

%   ------------------------------------------
%   C:  %   +++++   HPA    +++++
%   ------------------------------------------
%To show the effect of the PA simply we will add random complex noise
%when the power exceeds the avg. value, otherwise we add nothing.

% 1. Generate random complex noise
noise = randn(1,len_ofdm_data) +  sqrt(-1)*randn(1,len_ofdm_data);

% 2. Transmitted OFDM signal after passing through HPA
avg=0.4;
for i=1:length(ofdm_signal)
	if ofdm_signal(i) > avg
		ofdm_signal(i) = ofdm_signal(i)+noise(i);
    end
    if ofdm_signal(i) < -avg
		ofdm_signal(i) = ofdm_signal(i)+noise(i);
    end
end
figure(4)
plot(real(ofdm_signal)); xlabel('Time'); ylabel('Amplitude');
title('OFDM Signal after HPA');grid on;



%   --------------------------------
%   D:  %   +++++   CHANNEL    +++++
%   --------------------------------
%   Create a complex multipath channel
channel = randn(1,block_size) + sqrt(-1)*randn(1,block_size);

%   ------------------------------------------
%   E:  %   +++++   RECEIVER    +++++
%   ------------------------------------------

%   1.  Pass the ofdm signal through the channel
after_channel = filter(channel, 1, ofdm_signal);

%   2.   Add Noise
awgn_noise = awgn(zeros(1,length(after_channel)),0);

%   3.  Add noise to signal...

recvd_signal = awgn_noise+after_channel;

%   4.  Convert Data back to "parallel" form to perform FFT
recvd_signal_matrix = reshape(recvd_signal,rows_ifft_data, cols_ifft_data);

%   5.  Remove CP
recvd_signal_matrix(1:cp_len,:)=[];

%   6.  Perform FFT
for i=1:cols_ifft_data,
    %   FFT
    fft_data_matrix(:,i) = fft(recvd_signal_matrix(:,i),no_of_fft_points);
end

%   7.  Convert to serial stream
recvd_serial_data = reshape(fft_data_matrix, 1,(block_size*num_cols));
scatterplot(recvd_serial_data);title('MODULATED RECEIVED DATA');

%   8.  Demodulate the data
qpsk_demodulated_data = pskdemod(recvd_serial_data,M);
scatterplot(recvd_serial_data);title('MODULATED RECEIVED DATA');
figure(5)
stem(qpsk_demodulated_data,'rx');
grid on;xlabel('Data Points');ylabel('Amplitude');title('Received Data "X"')