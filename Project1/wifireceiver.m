%% wifireceiver: Receives a Wi-Fi packet from transimitter
% output = WiFi packet
% Inputs: message = text message, snr = signal to noise ratio, 
% level = number of stages of encoding

function output = wifireceiver(packet, level)
    nfft = 64;
    output = packet;
    
    UnInterleave = reshape(reshape([1:2*nfft], 2 * nfft / 4, []).', [], 1);
    
    if (level >= 1)
        length_part = output(1 : 2 * nfft);
        data_part = output(2 * nfft + 1 : length(output));
        
        nsym = length(data_part) / (2 * nfft);
        output = [];
        for ii = 1 : nsym
            symbol = data_part((ii - 1) * 2 * nfft + 1 : ii * 2 * nfft);
            output = [output, symbol(UnInterleave)];
        end
        
        % calculate length of message:
        message_length = 0;
        for i = 1 : 2 * nfft
            message_length = message_length + length_part(i) * (2 ^ (2 * nfft - i));
        end
        
        data_part = output;
        data_part = data_part(1 : message_length * 8);
        output = '';
        for a = 1 : 8 : length(data_part)
            curr_char = 0;
            for b = 0 : 7
                curr_char = curr_char + data_part(a + b) * (2 ^ (7 - b));
            end
            output = [output, char(curr_char)];
        end
        
    end
end