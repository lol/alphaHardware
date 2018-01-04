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
B = [0.004452370147772, 0.004793233634895, 0.004789208864513, 0.004374904045711, 0.003513441625887, 0.002203690069909,0.0004849670359367, -0.00156147606397, -0.003814640387892,-0.006119790084214,-0.008298102936972, -0.01015943071472,   -0.01151731376463, -0.01220512253132, -0.01209200841011, -0.01109726052046,  -0.009201698337839,-0.006454887425477,-0.002977240565214, 0.001043557813095,   0.005361917126328,  0.00968912249455,  0.01371267539821,   0.0171188969702,     0.0196171453217,  0.02096376722845,  0.02098382099618,  0.01958868584202,    0.01678791459981,  0.01269407771881, 0.007519860524967, 0.001567273947972,  -0.004790526010273, -0.01113369522464, -0.01702476879108, -0.02204023875569,   -0.02580226577704, -0.02800805751634, -0.02845455461849, -0.02705636863085,   -0.02385539503416, -0.01902114333171, -0.01284153684411,-0.005704680721792,   0.001927183091294, 0.009549680347188,  0.01665191883371,  0.02275304843217,    0.02743699768732,  0.03038273285569,  0.03138771333834,  0.03038273285569,    0.02743699768732,  0.02275304843217,  0.01665191883371, 0.009549680347188,   0.001927183091294,-0.005704680721792, -0.01284153684411, -0.01902114333171,   -0.02385539503416, -0.02705636863085, -0.02845455461849, -0.02800805751634,   -0.02580226577704, -0.02204023875569, -0.01702476879108, -0.01113369522464,  -0.004790526010273, 0.001567273947972, 0.007519860524967,  0.01269407771881,    0.01678791459981,  0.01958868584202,  0.02098382099618,  0.02096376722845,     0.0196171453217,   0.0171188969702,  0.01371267539821,  0.00968912249455,   0.005361917126328, 0.001043557813095,-0.002977240565214,-0.006454887425477,  -0.009201698337839, -0.01109726052046, -0.01209200841011, -0.01220512253132,   -0.01151731376463, -0.01015943071472,-0.008298102936972,-0.006119790084214,  -0.003814640387892, -0.00156147606397,0.0004849670359367, 0.002203690069909,   0.003513441625887, 0.004374904045711, 0.004789208864513, 0.004793233634895,   0.004452370147772];
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
eyes_closed_marker(eyes_closed) = 1200;

system_ready = stim_sample_num(stim_id == 3);
system_ready = ceil(system_ready / ((1 - overlap_factor) * fs * window_time));
system_ready_marker = zeros(length(alpha_epoch_avg), 1);
system_ready_marker(system_ready) = 1200;

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
alpha_det_plot(alpha_det_pos(alpha_det_pos > 0)) = 1200;

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
alpha_false_plot(alpha_false_pos(alpha_false_pos > 0)) = 1200;

time = 0 : overlap_time : overlap_time * (length(alpha_epoch_avg) - 1);
plot(time, alpha_epoch_avg); axis([0, overlap_time*length(alpha_epoch_avg), 0, 1200]);
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