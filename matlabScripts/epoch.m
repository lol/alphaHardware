function [epoch_avg] = epoch(signal, window_time,fs,overlap_factor)
mat = buffer(signal, window_time*fs, ceil(overlap_factor * window_time * fs));           %create a matrix with overlapped segments, also called 'Time Based Epoching'. 1 sec segments every 0.1 secs.
mat = mat';                                         %segments created by buffer are column vectors, so take the transpose.
mat = mat .* mat;                                   %square the signal. (Simple DSP = x * x)
signal_avg = mean(mat,2);                          %mean of the segments
%epoch_avg = sqrt(signal_avg);
epoch_avg = signal_avg;
end