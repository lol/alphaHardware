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


B = [0.004452370147772, 0.004793233634895, 0.004789208864513, 0.004374904045711, 0.003513441625887, 0.002203690069909,0.0004849670359367, -0.00156147606397, -0.003814640387892,-0.006119790084214,-0.008298102936972, -0.01015943071472,   -0.01151731376463, -0.01220512253132, -0.01209200841011, -0.01109726052046,  -0.009201698337839,-0.006454887425477,-0.002977240565214, 0.001043557813095,   0.005361917126328,  0.00968912249455,  0.01371267539821,   0.0171188969702,     0.0196171453217,  0.02096376722845,  0.02098382099618,  0.01958868584202,    0.01678791459981,  0.01269407771881, 0.007519860524967, 0.001567273947972,  -0.004790526010273, -0.01113369522464, -0.01702476879108, -0.02204023875569,   -0.02580226577704, -0.02800805751634, -0.02845455461849, -0.02705636863085,   -0.02385539503416, -0.01902114333171, -0.01284153684411,-0.005704680721792,   0.001927183091294, 0.009549680347188,  0.01665191883371,  0.02275304843217,    0.02743699768732,  0.03038273285569,  0.03138771333834,  0.03038273285569,    0.02743699768732,  0.02275304843217,  0.01665191883371, 0.009549680347188,   0.001927183091294,-0.005704680721792, -0.01284153684411, -0.01902114333171,   -0.02385539503416, -0.02705636863085, -0.02845455461849, -0.02800805751634,   -0.02580226577704, -0.02204023875569, -0.01702476879108, -0.01113369522464,  -0.004790526010273, 0.001567273947972, 0.007519860524967,  0.01269407771881,    0.01678791459981,  0.01958868584202,  0.02098382099618,  0.02096376722845,     0.0196171453217,   0.0171188969702,  0.01371267539821,  0.00968912249455,   0.005361917126328, 0.001043557813095,-0.002977240565214,-0.006454887425477,  -0.009201698337839, -0.01109726052046, -0.01209200841011, -0.01220512253132,   -0.01151731376463, -0.01015943071472,-0.008298102936972,-0.006119790084214,  -0.003814640387892, -0.00156147606397,0.0004849670359367, 0.002203690069909,   0.003513441625887, 0.004374904045711, 0.004789208864513, 0.004793233634895,   0.004452370147772];
A = 1;
alpha_signal = filter(B, A, s);

overlap_time = 0.1;
window_time = [2];
overlap_factor = 1 - (overlap_time / window_time);
alpha_epoch_avg = epoch(alpha_signal, window_time, fs, overlap_factor);


 
key_pressed = stim_sample_num(stim_id == 5);
key_pressed = ceil(key_pressed / ((1 - overlap_factor) * fs * window_time));
key_pressed_marker = zeros(length(alpha_epoch_avg), 1);
key_pressed_marker(key_pressed) = 1300;

alpha_detected = stim_sample_num(stim_id == 6);
alpha_detected = ceil(alpha_detected / ((1 - overlap_factor) * fs * window_time));
alpha_detected_marker = zeros(length(alpha_epoch_avg), 1);
alpha_detected_marker(alpha_detected) = 1300;

%verify = [alpha_detected, key_pressed];
detections = length(alpha_detected)
false_positives = length(stim_id(stim_id == 4))
activation_time = (alpha_detected - key_pressed)' * overlap_time
mean_activation_time = mean(activation_time(activation_time > 0))

 
plot(alpha_epoch_avg); axis([0 length(alpha_epoch_avg) 0 1300]);
hold on
grid;
hold on
stem(key_pressed_marker, 'g');
hold on
stem(alpha_detected_marker, 'r');
%saveas(1, file, 'png');
