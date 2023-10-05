clear;
clc;
close all;

num_bits = 1e5;                
SNR = 0:2:30;             
M = 20;                     
sampling_instant = 20;     

% Waveform 
s1 = ones(1, M);      % s1(t) is rectangular signal with Amp=1
s2 = zeros(1, M);     % s2(t) is zero signal

% Create an appropriate matched filter to detect a known signal (s2) within a noisy received signal (s1).
matched_filter = s1(end:-1:1) - s2(end:-1:1);

% Calclate threshold, the average of the values of s1 and s2 at a specific time instant
threshold = (s1(sampling_instant) + s2(sampling_instant)) / 2;

% Generate random binary data
data = randi([0 1], 1, num_bits);

% Represent each bit with proper waveform
Tx = [];
for i = 1 : length(data)
    if data(i)
        Tx = [Tx s1];
    else
        Tx = [Tx s2];
    end
end

BER = zeros(1, length(SNR));
BER_simple = zeros(1, length(SNR));
BER_c = zeros(1, length(SNR));
for i = 1 : length(SNR)

    % Add noise to trasnmitted signal to the received signal
    Rx = awgn(Tx, SNR(i), 'measured');
    simple = zeros(1, num_bits);
    detected_data = zeros(1, num_bits);
    detected_data_c = zeros(1, num_bits);
    for j = 1 : length(Rx)/M
        
        % Simple detection
        symbol = Rx(M*(j-1)+1:M*j);
        simple(j) = symbol(sampling_instant) > threshold;

        % Without correlator
        Y = filter(matched_filter,1,symbol);
        detected_data(j) = Y(sampling_instant) > threshold;
    
        % With correlator
        Y_c = sum(symbol.*(s1-s2));
        detected_data_c(j) = Y_c > threshold;
    end
    
    num_of_err_simple = biterr(data, simple);
    BER_simple(i) = num_of_err_simple / num_bits; 

    num_of_err = biterr(data, detected_data);
    BER(i) = num_of_err / num_bits; 

    num_of_err_c = biterr(data, detected_data_c);
    BER_c(i) = num_of_err_c / num_bits; 
end

% Calculate transmitted signal power
P_tx = mean(abs(Tx).^2);
fprintf('Transmitted signal power2: %f\n', P_tx);

% Plot SNR against BER
semilogy(SNR, BER, '-o'); xlabel("SNR"); ylabel("BER");
title("Matched filter vs Simple Detector");
hold on 
semilogy(SNR, BER_simple, '-o');
legend('Matched Filter Receiver', 'Simple Detector');

hold off

figure;
semilogy(SNR, BER_c, '-o'); xlabel("SNR"); ylabel("BER");
title("Correlator vs Simple Detector");
hold on 
semilogy(SNR, BER_simple, '-o');
legend('Correlator', 'Simple Detector');

%To Find The SNR Value At Which The Matched Filter Receiver Has The Lowest BER:
[Min_BER, Min_index] = min(BER);
SNR_min_BER = SNR(Min_index);
fprintf("SNR At Which Matched Filter Receiver Has Lowest BER: %f\n", SNR_min_BER);

%To Find The SNR Value At Which The simple detector Receiver Has The Lowest BER:
[Min_BER_simple, Min_index_simple] = min(BER_simple);
SNR_min_BER_simple = SNR(Min_index_simple);
fprintf("SNR At Which simple detector Receiver Has Lowest BER: %f\n", SNR_min_BER_simple);

%To Find The SNR Value At Which The correlator Receiver Has The Lowest BER:
[Min_BER_c, Min_index_c] = min(BER_c);
SNR_min_BER_c = SNR(Min_index_c);
fprintf("SNR At Which correlator Receiver Has Lowest BER: %f\n", SNR_min_BER_c);