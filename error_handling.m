clc;
close all;
clear all;

% INITIALIZATIONS
NumofAntenna = 4;
NumofSamples = 100;
SigmaSystem = 0.1;
theta_x = 35 * (pi/180);
theta_n1 = 0 * (pi/180);
theta_n2 = -20 * (pi/180);

% Check if NumofAntenna is a positive integer
if ~isnumeric(NumofAntenna) || NumofAntenna <= 0 || rem(NumofAntenna, 1) ~= 0
    error('NumofAntenna must be a positive integer.');
end

% Check if NumofSamples is a positive integer
if ~isnumeric(NumofSamples) || NumofSamples <= 0 || rem(NumofSamples, 1) ~= 0
    error('NumofSamples must be a positive integer.');
end

% Check if SigmaSystem is non-negative
if ~isnumeric(SigmaSystem) || SigmaSystem < 0
    error('SigmaSystem must be a non-negative number.');
end

% Check if theta_x is within the valid range (-pi/2 to pi/2)
if ~isnumeric(theta_x) || theta_x < -pi/2 || theta_x > pi/2
    error('theta_x must be within the range of -90 degrees to 90 degrees.');
end

% Check if theta_n1 and theta_n2 are within the valid range (-pi/2 to pi/2)
if ~isnumeric(theta_n1) || theta_n1 < -pi/2 || theta_n1 > pi/2
    error('theta_n1 must be within the range of -90 degrees to 90 degrees.');
end

if ~isnumeric(theta_n2) || theta_n2 < -pi/2 || theta_n2 > pi/2
    error('theta_n2 must be within the range of -90 degrees to 90 degrees.');
end

% TIME SETTINGS
theta = pi * [-1:0.005:1];
BitRate = 100;
SimFreq = 4 * BitRate;
Ts = 1 / SimFreq;

% Generate random binary data
Data = 2 * randi([0, 1], 1, NumofSamples) - 1;

% Upsample data
Data = upsample(Data, SimFreq / BitRate);

% Timeline
t = Ts:Ts:(length(Data) / SimFreq);

% Generate the complex signal_x
faz = cumsum(Data) / 8;
signal_x = cos(pi * faz) + 1i * sin(pi * faz);

% Generate random noise with Gaussian distribution
signal_n1 = randn(1, length(t)) + 1i * randn(1, length(t));
signal_n2 = randn(1, length(t)) + 1i * randn(1, length(t));

% Generate system noises for each antenna
noise = zeros(NumofAntenna, length(t));
for i = 0:NumofAntenna-1
    noise(i+1,:) = normrnd(0, SigmaSystem, 1, length(t)) .* exp(j * (unifrnd(-pi, pi, 1, length(t))));
end

% Array Responses
Kd = pi;
response_x = zeros(1, NumofAntenna);
response_n1 = zeros(1, NumofAntenna);
response_n2 = zeros(1, NumofAntenna);
for k = 0:NumofAntenna-1
    response_x(k+1) = exp(j * k * Kd * sin(theta_x));
    response_n1(k+1) = exp(j * k * Kd * sin(theta_n1));
    response_n2(k+1) = exp(j * k * Kd * sin(theta_n2));
end

% Total Received Signal
x = zeros(NumofAntenna, length(t));
n1 = zeros(NumofAntenna, length(t));
n2 = zeros(NumofAntenna, length(t));
for i = 0:NumofAntenna-1
    x(i+1,:) = signal_x .* response_x(i+1);
    n1(i+1,:) = signal_n1 .* response_n1(i+1);
    n2(i+1,:) = signal_n2 .* response_n2(i+1);
end

signal_ns = (noise + n1 + n2 + x);

% EVALUATING WEIGHTS THOSE SATISFY BEAMFORMING at DESIRED DIRECTION
y = zeros(1, length(t));
e = zeros(1, length(t));
method = input('Enter the type of beamforming algorithm (LMS (1) or CM (2)): ');

switch method
    case 1
        % LMS Algorithm
        muLMS = 0.05;
        w = zeros(1, NumofAntenna);
        for i = 0:length(t)-1
            y(i+1) = w * signal_ns(:,i+1);
            e(i+1) = signal_x(i+1) - y(i+1);
            w = w + muLMS * e(i+1) * (signal_ns(:,i+1))';
        end
    case 2
        % Constant Modulus Algorithm
        muCM = 0.05;
        w = zeros(1, NumofAntenna);
        w(1) = eps;
        for i = 0:length(t)-1
            y(i+1) = w * signal_ns(:,i+1);
            e(i+1) = y(i+1) / norm(y(i+1)) - y(i+1);
            w = w + muCM * e(i+1) * (signal_ns(:,i+1))';
        end
    otherwise
        error('Unknown method. Please enter 1 for LMS or 2 for CM.');
end

% PLOTS
close all;
plot(phase(y), 'r');
hold;
plot(phase(signal_x), '--b');
ylabel('phase(rad)');
xlabel('samples');
title('Desired Signal: 25 degrees & Interferers: 0 and -40 degrees')
legend('phase(d)','phase(y)')
hold off;

figure;
plot(abs(y), 'r');
hold;
plot(abs(signal_x), '--b');
ylabel('amplitude');
xlabel('samples');
legend('magnitude(d)', 'magnitude(y)')
hold off;

figure;
plot(abs(e));
ylabel('amplitude');
xlabel('samples');

figure;
for k = 0:NumofAntenna-1
    response(k+1,:) = exp(j * k * Kd * sin(theta));
end

% CALCULATE ARRAY RESPONSE
R = w * response;
plot((theta * 180 / pi), 20 * log10(abs(R)));
title('Amplitude Response for given Antenna Array');
ylabel('Magnitude(dB)');
xlabel('Angle(Degrees)');
axis([-90, +90, -50, 10]);
