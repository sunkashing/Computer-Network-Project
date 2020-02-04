%% wifireceiver: Receives a Wi-Fi packet from transimitter
% output = WiFi packet
% Inputs: message = text message, snr = signal to noise ratio, 
% level = number of stages of encoding
function [output, message_length, padding_nums] = wifireceiver(packet, level)
    output = packet;
    
    %% Level #4:  remove random padding and noise
    if (level >= 4)
        [output, padding_nums] = level4(output);
    end
    
    %% Level #3:  unpack OFDM packet
    if (level >= 3)
        output = level3(output);
    end
    
    %% Level #2: convolutional decoding
    if (level >= 2)
        output = level2(output);
    end
    
    %% Level #1: undo interleaving
    if (level >= 1)
        [output, message_length] = level1(output);
    end
end


function [output4, padding_nums] = level4(packet)
    nfft = 64;
    packet = packet.';
    packet_abs = abs(packet);
    threshold = 10;
    start = 0;
    [pks, locs] = findpeaks(packet_abs);
    data_pks_cnt = 1;
    for i = 1 : length(pks)
        if (pks(i) > threshold)
            data_pks(data_pks_cnt) = pks(i);
            data_pks_locs(data_pks_cnt) = locs(i);
            data_pks_cnt = data_pks_cnt + 1;
        end
    end
    padding_nums = data_pks_locs(1) - 1;
    output4 = packet(data_pks_locs(1) : data_pks_locs(data_pks_cnt - 1));
    data_len = length(output4);
    padding = 0;
    tmp = mod(data_len, nfft);
    if (tmp ~= 0)
        padding = nfft - tmp;
    end
    padding_0 = zeros(1, padding);
    output4 = [output4, padding_0];
    
    
end


function output3 = level3(packet)
    nfft = 64;
    nysm = length(packet) / nfft;
    output3 = [];
    for ii = 1 : nysm
        symbol = packet((ii - 1) * nfft + 1 : ii * nfft);
        output3 = [output3, ifft(symbol)];
    end
    
end


function output2 = level2(packet)
    nfft = 64;
    % This is the Encoder/decoder trellis used by WiFi's turbo encoder
    Trellis = poly2trellis(3,[7,5]);
    
    output2 = qamdemod(packet , 4, 'bin', 'OutputType', 'bit');
    output2 = output2(2 * nfft + 1 : end);
    message_part = output2(2 * nfft + 1 : end);
    decodedData = vitdec(message_part, Trellis, 15,'trunc','hard');
    output2 = [output2(1 : 2 * nfft), decodedData];
end


% function decoded_data = viterbi_decode(message, trellis)
%     
% end


function [output1, message_length] = level1(packet)
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
