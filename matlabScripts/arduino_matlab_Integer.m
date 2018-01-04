clc;
clear all;
close all;

% Signal file is a CSV file generated from the streamed data over Aduino's serial
% Format is as follows:
% [sample_num, sample, stim_id/mode]
% Data available on request

x = load('data.csv');

s = x(:, 2);
%test = x(:, 3);
%test = test';
%test_final = test([1, diff(test)] ~= 0);
%detections = test_final(test_final == 6);
%false_positives = test_final(test_final == 4);

fs = 250;

test = x(:, 3);
test = test';
test2 = [1, diff(test)] ~= 0;
stim_sample_num = find(test2 > 0);
stim_id = test(stim_sample_num);

event_matrix = [stim_sample_num', stim_id'];

stim_sample_num = stim_sample_num';
stim_id = stim_id';

% filtering
% Integer
B = [             0,           0,           0,           0,           0,           0,             0,           0,           0,           0,           0,           0,             0,           0,           0,           0,           0,           0,             0,           0,           0,           0,           1,           1,             1,           1,           1,           1,           1,           0,             0,           0,           0,           0,          -1,          -1,            -1,          -1,          -1,          -1,          -1,          -1,             0,           0,           0,           0,           1,           1,             1,           1,           1,           1,           1,           1,             1,           0,           0,           0,           0,          -1,            -1,          -1,          -1,          -1,          -1,          -1,            -1,           0,           0,           0,           0,           0,             1,           1,           1,           1,           1,           1,             1,           0,           0,           0,           0,           0,             0,           0,           0,           0,           0,           0,             0,           0,           0,           0,           0,           0,             0,           0,           0,           0,           0];
A = 1;
alpha_signal = filter(B, A, s);

overlap_time = 0.1;
window_time = [2];
overlap_factor = 1 - (overlap_time / window_time);
alpha_epoch_avg = epoch(alpha_signal, window_time, fs, overlap_factor);

%threshold
o = epoch(alpha_signal(stim_sample_num(2) : stim_sample_num(3)), window_time, fs, overlap_factor);
c = epoch(alpha_signal(stim_sample_num(3) : stim_sample_num(4)), window_time, fs, overlap_factor);
threshold = (2/3)*mean(o) + (1/3)*mean(c);

%markers
epoch_event = ceil(stim_sample_num / ((1 - overlap_factor) * fs * window_time));

%eyes_open = stim_sample_num(stim_id == 5);
%eyes_open = ceil(eyes_open / ((1 - overlap_factor) * fs * window_time));
%eyes_open_marker = zeros(length(alpha_epoch_avg), 1);
%eyes_open_marker(eyes_open) = 1200;

eyes_closed = stim_sample_num(stim_id == 5);
eyes_closed = ceil(eyes_closed / ((1 - overlap_factor) * fs * window_time));
eyes_closed_marker = zeros(length(alpha_epoch_avg), 1);
eyes_closed_marker(eyes_closed) = max(alpha_epoch_avg);

system_ready = stim_sample_num(stim_id == 3);
system_ready = ceil(system_ready / ((1 - overlap_factor) * fs * window_time));
system_ready_marker = zeros(length(alpha_epoch_avg), 1);
system_ready_marker(system_ready) = max(alpha_epoch_avg);

system_ready = [system_ready; length(alpha_epoch_avg)];
key_pressed = eyes_closed(1:end);
key_pressed = [key_pressed; length(key_pressed)];

% true positives
alpha_det_pos = [];
j = 1;
k = 1;
flag = [];
detected = 0;
for i = epoch_event(1) : length(alpha_epoch_avg) - 1
    if(i > system_ready(j) && i > key_pressed(j) && i < system_ready(j+1) && detected == 0)
        if(alpha_epoch_avg(i) < threshold && alpha_epoch_avg(i+1) > threshold)
            alpha_det_pos = [alpha_det_pos; i];
            detected = 1;
        end
    end
    if(i > system_ready(j+1))
        j = j + 1;
        if(detected == 0)
            alpha_det_pos = [alpha_det_pos; 0];
        end
        detected = 0;
    end
end

verify = [alpha_det_pos, key_pressed(1:end-1)];
activation_time = (alpha_det_pos - key_pressed(1:end-1))' * overlap_time
mean_activation_time = mean(activation_time(activation_time > 0))
true_positives = sum(activation_time > 0)

alpha_det_plot = zeros(length(alpha_epoch_avg), 1);
alpha_det_plot(alpha_det_pos(alpha_det_pos > 0)) = max(alpha_epoch_avg);

alpha_false_pos = [];
j = 1;
k = 1;
flag = [];
detected = 0;
for i = epoch_event(1) : length(alpha_epoch_avg) - 1
    if(i > system_ready(j) && i < key_pressed(j) && i < system_ready(j+1) && detected == 0)
        if(alpha_epoch_avg(i) < threshold && alpha_epoch_avg(i+1) > threshold)
            alpha_false_pos = [alpha_false_pos; i];
            detected = 1;
            i = i + (5 / overlap_time);
        end
    end
    if(i > system_ready(j+1))
        j = j + 1;
        if(detected == 0)
            alpha_false_pos = [alpha_false_pos; 0];
        end
        detected = 0;
    end
end

false_positives = sum(alpha_false_pos > 0)

alpha_false_plot = zeros(length(alpha_epoch_avg), 1);
alpha_false_plot(alpha_false_pos(alpha_false_pos > 0)) = max(alpha_epoch_avg);

time = 0 : overlap_time : overlap_time * (length(alpha_epoch_avg) - 1);
plot(time, alpha_epoch_avg); axis([0, overlap_time*length(alpha_epoch_avg), 0, max(alpha_epoch_avg)]);
hold on
grid;
hold on
% Horizontal line for threshold
plot(get(gca,'xlim'), [threshold threshold], 'm');
hold on
%stem(time, eyes_open_marker, 'g');
%hold on
stem(time, system_ready_marker, 'k');
hold on
stem(time, eyes_closed_marker, 'r');
hold on
stem(time, alpha_det_plot, 'y');
hold on
stem(time, alpha_false_plot, 'c');