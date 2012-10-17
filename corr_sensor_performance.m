% corr_sensor_performance('tcpdump.driving.highway.midnight.tcp.dat.throughput.3.txt', 'sensor.driving.highway.midnight.dat.sensor.3.txt')
function y = corr_sensor_performance(performance_file, sensor_file)

%%%%%
%% global variables
src_path = './PARSEDDATA';


%%%%%
%% main

%%%%%
%% reading sensor data
%%   $time, $xMag, $yMag, $zMag, $xAccel, $yAccel, $zAccel, $lat, $lng, $alt, $xRate, $yRate, $zRate, $roll, $pitch, $yaw
s_data = load([src_path '/' sensor_file]);
[s_row, s_col] = size(s_data);
display(['sensor row, col = ' int2str(s_row) ', ' int2str(s_col)])

%% reading performance data
p_data = load([src_path '/' performance_file]);
[p_row, p_col] = size(p_data);
display(['performance row, col = ' int2str(p_row) ', ' int2str(p_col)])

for col = 2:s_col
    R_throughput = corrcoef(p_data(:, 3), s_data(:, col));
    R_var = corrcoef(p_data(:, 4), s_data(:, col));

    display([int2str(col) ': throughput=' num2str(R_throughput(1,2)) ', variance=' num2str(R_var(1,2))])
end

x_throughput = s_data(:, 2:end)\p_data(:, 3);
predict_throughput = s_data(:, 2:end) * x_throughput;
diff_throughput = abs(p_data(:, 3) - predict_throughput) ./ p_data(:, 3);
x_throughput
mean(diff_throughput)

x_variance = s_data(:, 2:end)\p_data(:, 4);
predict_variance = s_data(:, 2:end) * x_variance;
diff_variance = abs(p_data(:, 4) - predict_variance)  ./ p_data(:, 4);
mean(diff_variance)


y = 0;

