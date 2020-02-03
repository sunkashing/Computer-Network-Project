%% wifireceiver: Receives a Wi-Fi packet from transimitter
% output = WiFi packet
% Inputs: message = text message, snr = signal to noise ratio, 
% level = number of stages of encoding
function output = wifireceiver(packet, level)
    output = packet;
    
    
    
    %% Level #2: convolutional decoding
    
    
    
    
    
    %% Level #1: undo interleaving
    if (level >= 1)
        output = level1(packet);
    end
end

function output1 = level1(packet)
    nfft = 64;
    length_part = packet(1 : 2 * nfft);
    data_part = packet(2 * nfft + 1 : length(packet));
    UnInterleave = reshape(reshape([1:2*nfft], 2 * nfft / 4, []).', [], 1);
    
    nsym = length(data_part) / (2 * nfft);
    output1 = [];
    for ii = 1 : nsym
        symbol = data_part((ii - 1) * 2 * nfft + 1 : ii * 2 * nfft);
        output1 = [output1, symbol(UnInterleave)];
    end

    % calculate length of message:
    message_length = 0;
    for i = 1 : 2 * nfft
        message_length = message_length + length_part(i) * (2 ^ (2 * nfft - i));
    end

    data_part = output1;
    data_part = data_part(1 : message_length * 8);
    output1 = '';
    for a = 1 : 8 : length(data_part)
        curr_char = 0;
        for b = 0 : 7
            curr_char = curr_char + data_part(a + b) * (2 ^ (7 - b));
        end
        output1 = [output1, char(curr_char)];
    end
end
