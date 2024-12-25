% File: fire_code_simulation_updated.m

% Simulation parameters
clear; clc;

n = 15; % Code length
k = 7;  % Message length
t = 3;  % Maximum burst error length
numBits = 1e5; % Number of bits to simulate
snrRange = 0:2:12; % SNR range in dB

% Generator polynomial (Fire code)
p1 = [1 1 1];       % (x^2 + x + 1)
p2 = [1 0 0 0 1];   % (x^4 + 1)
g = conv(p1, p2);   % Generator polynomial

% Preallocate BER results
ber = zeros(size(snrRange));

% Simulation loop
for idx = 1:length(snrRange)
    snr = snrRange(idx);
    numErrors = 0;
    totalBits = 0;
    
    % Generate random messages
    for iter = 1:numBits/k
        % Generate random message
        message = randi([0 1], 1, k);
        
        % Encode using Fire code
        codeword = encode_fire(message, g, n);
        
        % Simulate channel (AWGN + burst errors)
        noisyCodeword = add_burst_errors(codeword, t);
        noisyCodeword = awgn(noisyCodeword, snr, 'measured'); % Add Gaussian noise
        
        % Decode and detect errors
        decodedMessage = decode_fire(noisyCodeword, g, k, n);
        
        % Count bit errors
        numErrors = numErrors + sum(decodedMessage~= message);
        totalBits = totalBits + k;
    end
    
    % Calculate BER
    ber(idx) = numErrors / totalBits;
end

% Plot results
figure;
semilogy(snrRange, ber, '-o', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('BER Performance of Fire Code');
legend('Fire Code');

% ===== Auxiliary Functions =====

function codeword = encode_fire(message, g, n)
    % Encode using Fire code
    % Inputs:
    % - message: input binary message
    % - g: generator polynomial
    % - n: code length
    % Output:
    % - codeword: encoded binary codeword
    
    k = length(message); % Message length
    paddedMessage = [message, zeros(1, n-k)]; % Pad message to code length
    [~, remainder] = deconv(paddedMessage, g); % Polynomial division
    remainder = mod(remainder, 2); % Modulo 2 operation
    codeword = mod(paddedMessage + remainder, 2);
end

function decodedMessage = decode_fire(received, g, k, n)
    % Decode using Fire code
    % Inputs:
    % - received: received codeword
    % - g: generator polynomial
    % - k: message length
    % - n: code length
    % Output:
    % - decodedMessage: decoded binary message
    
    [~, remainder] = deconv(received, g); % Polynomial division
    remainder = mod(remainder, 2); % Check remainder
    if any(remainder) % If remainder is non-zero, error detected
        % Attempt error correction (limited correction logic here)
        % Assume uncorrectable errors are approximated as original
        corrected = mod(received, 2);
    else
        corrected = received;
    end
    decodedMessage = corrected(1:k); % Extract message part
end

function noisyCodeword = add_burst_errors(codeword, t)
    % Add burst errors to the codeword
    % Inputs:
    % - codeword: input codeword
    % - t: maximum burst error length
    % Output:
    % - noisyCodeword: codeword with burst errors
    
    noisyCodeword = codeword;
    if rand < 0.5 % Add burst error with probability 0.5
        burstStart = randi([1, length(codeword) - t + 1]);
        burstError = randi([0 1], 1, t);
        noisyCodeword(burstStart:burstStart+t-1) = ...
            mod(noisyCodeword(burstStart:burstStart+t-1) + burstError, 2);
    end
end