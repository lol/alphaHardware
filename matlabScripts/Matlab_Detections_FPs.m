clear all;
x = load('charan.csv');
test = x(:, 3);
test = test';
test_final = test([1, diff(test)] ~= 0);
detections = test_final(test_final == 6);
false_positives = test_final(test_final == 4);