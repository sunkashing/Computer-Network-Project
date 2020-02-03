%% wifitransmitter: Creates a Wi-Fi packet
% output = WiFi packet
% Inputs: message = text message, snr = signal to noise ratio, 
% level = number of stages of encoding
function output = wifitransmitter(message, level, snr)

    %% Default values
    if(nargin < 2)
        level = 4;
    end
    if(nargin < 3)
        snr = Inf;
    end 
    
    %% Sanity checks
    
    % check if message length is reasonable
    if(length(message) > 10000)
        fprintf(2, 'Error: Message too long\n');
        output=[];
        return;
    end
    
    % check if level is between 1 and 4
    if(level > 4 || level < 1)
        fprintf(2, 'Error: Invalid level, must be 1-4\n');
        output=[];
        return;
    end
        
    %% Some constants
    
    % We will split the data into a cluster of 2*nfft bits
    % mulitplicative factor 2 is due to 4 QAM modulation used later
    nfft = 64;
    % This is the Encoder/decoder trellis used by WiFi's turbo encoder
%     Trellis = poly2trellis(3,[7,5]);
    % Every WiFi packet will start with this exact preamble
    preamble = [1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1,1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1];
%    preamble_symbols = qammod(preamble.',4,'InputType','bit');
   
    % Every 128 bits are mixed up like below:
    Interleave = reshape(reshape([1:2*nfft], 4, []).', [], 1);
    
    %% Lets learn about the message
    % Length
    len = length(message);
    
    %% Level #1: First lets do interleaving, which permutes the bits 
    if (level >= 1)
        % This basically converts the message into a sequence of bits
        bits = reshape(dec2bin(double(message).', 8).', 1, [])-'0';
                
        % We append as many bits as necessary to make this a multiple of
        % 2*nfft
        bits = [bits, zeros(1, mod(-length(bits), 2*nfft))];
        
        nsym = length(bits)/(2*nfft);
         
        output = [];
        % Number of symbols in the message
        for ii = 1:nsym
            % Collect the iith symbol
            symbol = bits((ii-1)*2*nfft + 1: ii*2*nfft);
            % Interleave the symbol and append to output
            output = [output, symbol(Interleave)];
        end
        % Finaally, let's pre-pend the length to the message
        output = [dec2bin(len,2*nfft)-'0',output];

    end
    
    
    %% Level #2: Next, lets do convolutional encoding, which adds redundancy to the bits
       % and modulate the bits to symbols 
    if (level >= 2)
       
        % Next, we apply the convolutional encoder to the message part
       coded_message = convenc(output(2*nfft + 1:end),Trellis);
       
       % Pre-pend the length to the coded message
       output = [output(1:2*nfft),coded_message];
       
       % Next, lets do modulation, which maps the bits to a modulation (QAM)
       % Do 4-QAM modulation
       output = qammod(output.',4,'InputType','bit');
       % Prepend a preamble
       output = [preamble_symbols; output];
    
    end
    
    %% Level #3: Next, lets create an OFDM packet
    if (level >= 3)
       % Number of symbols in message
       nsym = length(output)/nfft;
       for ii = 1:nsym
            % Collect the iith symbol
            symbol = output((ii-1)*nfft+1:ii*nfft);
            % Run an FFT on the symbol
            output((ii-1)*nfft+1:ii*nfft) = fft(symbol);
        end 
    end
    
    %% Level #4: Finally, lets add some random padding and noise
    if (level >= 4)
        % Lets add some (random) empty space to the beginning and end
        noise_pad_begin = zeros(1, round(rand*1000)).';
        noise_pad_end = zeros(1, round(rand*1000)).';
        length(noise_pad_begin)
        output = [noise_pad_begin; output; noise_pad_end];
        
        % Let's add additive white gaussian noise
        output = awgn(output, snr);
    end

end

