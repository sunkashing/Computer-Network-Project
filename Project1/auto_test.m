function auto_test()
    for i = 1 : 2000
        a = wifitransmitter('hello world', 4, 15);
        [b, c, d] = wifireceiver(a, 4);
    end

end