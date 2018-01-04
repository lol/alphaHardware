function sig = bandfilter(signal, fs, order, lowBand, highBand)

%lowFreq = lowBand * (2/fs);
%highFreq = highBand * (2/fs);

B = [0.004452370147772, 0.004793233634895, 0.004789208864513, 0.004374904045711, 0.003513441625887, 0.002203690069909,0.0004849670359367, -0.00156147606397, -0.003814640387892,-0.006119790084214,-0.008298102936972, -0.01015943071472,   -0.01151731376463, -0.01220512253132, -0.01209200841011, -0.01109726052046,  -0.009201698337839,-0.006454887425477,-0.002977240565214, 0.001043557813095,   0.005361917126328,  0.00968912249455,  0.01371267539821,   0.0171188969702,     0.0196171453217,  0.02096376722845,  0.02098382099618,  0.01958868584202,    0.01678791459981,  0.01269407771881, 0.007519860524967, 0.001567273947972,  -0.004790526010273, -0.01113369522464, -0.01702476879108, -0.02204023875569,   -0.02580226577704, -0.02800805751634, -0.02845455461849, -0.02705636863085,   -0.02385539503416, -0.01902114333171, -0.01284153684411,-0.005704680721792,   0.001927183091294, 0.009549680347188,  0.01665191883371,  0.02275304843217,    0.02743699768732,  0.03038273285569,  0.03138771333834,  0.03038273285569,    0.02743699768732,  0.02275304843217,  0.01665191883371, 0.009549680347188,   0.001927183091294,-0.005704680721792, -0.01284153684411, -0.01902114333171,   -0.02385539503416, -0.02705636863085, -0.02845455461849, -0.02800805751634,   -0.02580226577704, -0.02204023875569, -0.01702476879108, -0.01113369522464,  -0.004790526010273, 0.001567273947972, 0.007519860524967,  0.01269407771881,    0.01678791459981,  0.01958868584202,  0.02098382099618,  0.02096376722845,     0.0196171453217,   0.0171188969702,  0.01371267539821,  0.00968912249455,   0.005361917126328, 0.001043557813095,-0.002977240565214,-0.006454887425477,  -0.009201698337839, -0.01109726052046, -0.01209200841011, -0.01220512253132,   -0.01151731376463, -0.01015943071472,-0.008298102936972,-0.006119790084214,  -0.003814640387892, -0.00156147606397,0.0004849670359367, 0.002203690069909,   0.003513441625887, 0.004374904045711, 0.004789208864513, 0.004793233634895,   0.004452370147772];

A = 1;

sig = filter(B, A, signal);

end