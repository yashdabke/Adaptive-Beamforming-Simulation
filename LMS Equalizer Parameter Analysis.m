% Parameters
N = 2000;               % Length of the sequence
M = 11;                 % Number of taps in the equalizer
sim_times = 200;        % Number of simulation times
tau = 7;                % Delay in the channel
mu = 0.075;             % Step size for LMS algorithm
W = 2.9;                % Channel parameter for the raised cosine channel

% Generate binary input signal
d = double(randn(sim_times, N) > 0);

% Extend input signal with zeros at the beginning (delay)
d_ext = [double(randn(sim_times, tau) > 0) d];

% Initialize variables for plotting
x = 1:1:N;
mse = zeros(sim_times, N);  % Mean squared error

% Raised cosine channel response
n = [1 2 3];
h_tmp = 1/2 * (1 + cos(2 * pi * (n - 2) / W));
h = [0 h_tmp];

% Simulation for Different W (Channel Parameter)
W_test = 2.9:0.2:3.5;
for k = 1:length(W_test)
    for j = 1:sim_times
        u_tmp = conv(d_ext(j, :), h);
        u = [zeros(1, M - tau - 1) u_tmp];
        w = randn(1, M);

        % LMS Algorithm
        for i = 1:N
            U = fliplr(u(i:i+M-1));
            y = U * transpose(w);
            e = d_ext(j, i) - y;
            w = w + mu * e * U;
            mse(j, i) = mse(j, i) + e^2;
        end
    end
end
mse = mse / sim_times;

% Plotting Learning Curve for Different W
figure, plot(x, mse(1, :));
set(gca, 'YScale', 'log');
xlabel('Number of adaptation cycles, n');
ylabel('Mean squared error');
title('Learning curve');

% Plotting Learning Curve for Different W (Multiple Curves)
figure, plot(x, mse(1,:), x, mse(2,:), x, mse(3,:), x, mse(4,:));
set(gca, 'YScale', 'log');
xlabel('Number of adaptation cycles, n');
ylabel('Mean squared error');
title('Learning curve for different W');
legend({'W = 2.9','W = 3.1', 'W = 3.3', 'W = 3.5'},'Location','northeast')

% Simulation for Different Step Sizes (mu)
mu_test = [0.0075 0.025 0.075 0.1 0.15];
mse_mu = zeros(length(mu_test), N); % Mean squared error

% Reusing the raised cosine channel response (h) from previous section

% Iterate over different step sizes
for k = 1:length(mu_test)
    for j = 1:sim_times
        u_tmp = conv(d_ext(j, :), h);
        u = [zeros(1, M - tau - 1) u_tmp];
        w = randn(1, M);

        % LMS Algorithm
        for i = 1:N
            U = fliplr(u(i:i+M-1));
            y = U * transpose(w);
            e = d_ext(j, i) - y;
            w = w + mu_test(k) * e * U;
            mse_mu(k, i) = mse_mu(k, i) + e^2;
        end
    end
end
mse_mu = mse_mu / sim_times;

% Plotting Learning Curve for Different Step Sizes (mu)
figure, plot(x, mse_mu(1,:), x, mse_mu(2,:), x, mse_mu(3,:), x, mse_mu(4,:), x, mse_mu(5,:));
set(gca, 'YScale', 'log');
xlabel('Number of adaptation cycles, n');
ylabel('Mean squared error');
title('Learning curve for different step size mu');
legend({'mu = 0.0075','mu = 0.025', 'mu = 0.075', 'mu = 0.1' , 'mu = 0.15'},'Location','northeast')

% Simulation for Different Delays (tau)
tau_test = [4 6 7 8 9];
mse_delay = zeros(length(tau_test), N); % Mean squared error

% Reusing the raised cosine channel response (h) from previous section

% Iterate over different delays
for k = 1:length(tau_test)
    d_test = [zeros(sim_times, tau_test(k)) d];
    for j = 1:sim_times
        u_tmp = conv(d_ext(j,:), h);
        u = [zeros(1, M - tau_test(k) - 1) u_tmp];
        w = randn(1, M);

        % LMS Algorithm
        for i = 1:N
            U = fliplr(u(i:i+M-1));
            y = U * transpose(w);
            e = d_test(j, i) - y;
            w = w + mu * e * U;
            mse_delay(k, i) = mse_delay(k, i) + e^2;
        end
    end
end
mse_delay = mse_delay / sim_times;

% Plotting Learning Curve for Different Delays (tau)
figure, plot(x, mse_delay(1,:), x, mse_delay(2,:), x, mse_delay(3,:), x, mse_delay(4,:), x, mse_delay(5,:));
set(gca, 'YScale', 'log');
xlabel('Number of adaptation cycles, n');
ylabel('Mean squared error');
title('Learning curve for different delay tau');
legend({'tau = 4','tau = 6', 'tau = 7', 'tau = 8' , 'tau = 9'},'Location','northeast')

% Simulation with Noise
mse_noise = zeros(length(W_test), N); % Mean squared error

% Reusing the raised cosine channel response (h) from previous section

% Iterate over different channel parameters
for k = 1:length(W_test)
    for j = 1:sim_times
        u_tmp = conv(d_ext(j,:), h);
        u = [zeros(1, M - tau - 1) u_tmp(1:N+tau)] + randn(1, M + N - 1) * sqrt(0.001);
        w = randn(1, M);

        % LMS Algorithm
        for i = 1:N
            U = fliplr(u(i:i+M-1));
            y = U * transpose(w);
            e = d_ext(j, i) - y;
            w = w + mu * e * U;
            mse_noise(k, i) = mse_noise(k, i) + e^2;
        end
    end
end
mse_noise = mse_noise / sim_times;

% Plotting Learning Curve for Different W with Noise
figure, plot(x, mse_noise(1,:), x, mse_noise(2,:),
