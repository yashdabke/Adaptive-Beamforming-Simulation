clc;
close all;
clear all;
% INITIALIZATIONS
NumofAntenna = 4; % Number of antennas in the array
NumofSamples = 100; % Number of bits to be transmitted
SigmaSystem = 0.1; % System Noise Variance
theta_x = 35 * (pi/180); % direction of signal x
theta_n1 = 0 * (pi/180); % direction of noise source 1
theta_n2 = -20 * (pi/180); % direction of noise source 2
% TIME SETTINGS
theta = pi*[-1:0.005:1];
BitRate = 100;
SimFreq = 4*BitRate; % Simulation frequency
Ts = 1/SimFreq; % Simulation sample period
% GENERATE A COMPLEX MSK DATA TO BE TRANSMITTED
for k=1:NumofSamples
q=randperm(2);
Data(k)=-1^q(1);
end
Data = upsample(Data, SimFreq/BitRate); % Upsample data
t = Ts:Ts:(length(Data)/SimFreq); % Timeline
faz=(cumsum(Data))/8;
signal_x = cos(pi*faz)+j*sin(pi*faz); % The signal to be received
% GENERATE INTERFERER NOISE -> uniform phase (-pi,pi), gaussian amplitude
% distribution(magnitude 1)
signal_n1 = normrnd(0,1,1,length(t)).*exp (j*(unifrnd(-pi,pi,1,length(t))));
signal_n2 = normrnd(0,1,1,length(t)).*exp (j*(unifrnd(-pi,pi,1,length(t))));
% GENERATE SYSTEM NOISES for EACH ANTENNA -> uniform phase
% (-pi,pi),gaussian
% amplitude distribution(magnitude 1)
noise = zeros(NumofAntenna, length(t));
for i = 0:NumofAntenna-1,
noise(i+1,:) = normrnd(0,SigmaSystem,1,length(t)).*exp (j*(unifrnd(-pi,pi,1,length(t))));
end;
% ARRAY RESPONSES for DESIRED SIGNAL (X) and INTERFERER NOISES (N1and N2)
Kd = pi; % It is assumed that antennas are seperated by lambda/2.
response_x = zeros(1,NumofAntenna);
response_n1 = zeros(1,NumofAntenna);
response_n2 = zeros(1,NumofAntenna);
for k = 0:NumofAntenna-1,
response_x(k+1) = exp(j*k*Kd*sin(theta_x));
response_n1(k+1) = exp(j*k*Kd*sin(theta_n1));
response_n2(k+1) = exp(j*k*Kd*sin(theta_n2));
end;
% TOTAL RECEIVED SIGNAL (SUM of X.*Hx, N1.*Hn1 and N2.*Hn2)
x = zeros(NumofAntenna, length(t));
n1 = zeros(NumofAntenna, length(t));
n2 = zeros(NumofAntenna, length(t));
for i = 0:NumofAntenna-1,
x(i+1,:) = signal_x .* response_x(i+1); % received signal from signal source x
n1(i+1,:) = signal_n1 .* response_n1(i+1); % received signal from noise source n1
n2(i+1,:) = signal_n2 .* response_n2(i+1); % received signal from noise source n2
end;
signal_ns = (noise + n1+n2+x); % total received signal
% EVALUATUING WEIGHTs THOSE SATISFY BEAMFORMING at DESIRED DIRECTION
y = zeros(1,length(t)); % output
mu = 0.05; % gradient constant
e = zeros(1,length(t)); % error
method = input('Enter the type of beamforming algorithm (lms (1) or cm (2)): ');
switch method
case 1
w = zeros(1,NumofAntenna); % weights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%LMS Algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
for i=0:length(t)-1,
y(i+1) = w * signal_ns(:,i+1);
e(i+1) = signal_x(i+1)-y(i+1);
w = w + mu *e(i+1)*(signal_ns(:,i+1))';
end;
case 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%Constant Modulus Algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
w = zeros(1,NumofAntenna); w(1)=eps; % weights
for i=0:length(t)-1,
y(i+1) = w * signal_ns(:,i+1);
e(i+1) = y(i+1)/norm(y(i+1))-y(i+1);
w = w + mu *e(i+1)*(signal_ns(:,i+1))';
end;
otherwise
disp('Unknown method!')
end
% PLOTS
close all;
plot(phase(y),'r');
hold;
plot(phase(signal_x),'--b');
ylabel('phase(rad)');
xlabel('samples');
title('Desired Signal: 25 degrees & Interferers: 0 and -40 degrees')
legend('phase(d)','phase(y)')
hold off;
figure;
plot(abs(y),'r');
hold;
plot(abs(signal_x),'--b');
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
response(k+1,:) = exp(j*k*Kd*sin(theta));
end
% CALCULATE ARRAY RESPONSE
R = w*response;
plot((theta*180/pi), 20*log10(abs(R)));
title('Amplitude Response for given Antenne Array');
ylabel('Magnitude(dB)');
xlabel('Angle(Degrees)');
axis([-90,+90,-50,10]);