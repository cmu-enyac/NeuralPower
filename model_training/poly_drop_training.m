clear all;
% result = dlmread('cnn_mnist_results.txt');
% input_feature = dlmread('cnn_mnist_features.txt');
% data = dlmread('fc_random.txt');
% data = dlmread('fc_famous_other.txt');
data_raw = dlmread('res_drop.txt');
% data_raw = dlmread('fc_famous.txt');
% data = [];
data = data_raw;
threshold = 2;
% for i = 1:size(data_raw, 1)
%     if data_raw(i, 4) > threshold
%        data = [data; data_raw(i, :)];
%     end
% end

% data = dlmread('fc_famous_first.txt');
% data = dlmread('fc_random_fc1.txt');
% data = dlmread('fc_random_fc_others.txt');
% data = dlmread('conv_data.txt');
result = data(:,end - 1: end);
ipt_all = data(:,1: end - 2);
%% construct X
% conv1_size conv2_size conv3_size kernel1_size kernel2_size kernel3_size po1_size po2_size po3_size fc1_size fc2_size 

[row, col] = size(ipt_all);

%log scal
% input_feature(:,1:3) = log2(input_feature(:,1:3) + 1);
% input_feature(:,10:11) = log2(input_feature(:,10:11) + 1);

X = [];
for i = 1:row
    ipf = (ipt_all(i, :));
    % linear
%     tmp1 = [ipf, log(ipf)];
    tmp1 = [ipf];
    % quadratic 
    tmp2 = [];
    for j  = 1:length(tmp1)
        for k = j: length(tmp1)
            tmp2 = [tmp2, tmp1(j)*tmp1(k)];
        end
    end
    % cubic
    tmp3 = [];
    for j  = 1:length(tmp1)
        for k = j: length(tmp1)
            for l = k: length(tmp1)
                tmp3 = [tmp3, tmp1(j)*tmp1(k)*tmp1(l)];
            end
        end
    end     
%     tmp = [tmp1];
    tmp = [tmp1];
%     tmp = [tmp, ipf(13)*ipf(2)*ipf(3)*ipf(4)*ipf(5)*ipf(6)*ipf(7)]; %output pixels * # of operations per pixel
%     tmp = [tmp, ipf(13)*ipf(2)*ipf(3)*ipf(5)*ipf(6)*ipf(7)]; %output pixels * # of operations per pixel
    tmp = [tmp, ipf(1)*ipf(2)*ipf(3)*ipf(4)*ipf(5)]; %operations data
    tmp = [tmp, ipf(2)*ipf(3)*ipf(4)*ipf(5)]; %output data
%     tmp = [tmp, ipf(5)*ipf(6)*ipf(7)*ipf(8)]; %filter data
%     tmp = [tmp, ipf(1)*ipf(9)*ipf(10)*ipf(4)]; %input data
%     tmp = [tmp, ipf(13)*ipf(15)*ipf(16)]; %input data (padding)
%     tmp = [tmp, ipf(13)*ipf(14)*ipf(16)]; %input data (padding)

    X = [X; tmp];
end

% %% add log & exponential terms
% for i = 1:size(X,2)
%     tmp = X(:,i);
%     X = [X, log(tmp)];
% %     X = [X, log(tmp + 1), exp(tmp)];
% end

% %% normalize
% X_norm = [];
% Y_norm = [];
% for i = 1:size(X,2)
%     tmp = X(:,i);
%     X_norm = [X_norm, tmp/max(tmp)];
% %     if (max(tmp) == min(tmp))
% %         X_norm = [X_norm, tmp];
% %     else
% %         X_norm = [X_norm, (tmp - min(tmp))/(max(tmp) - min(tmp))];
% %     end
% end
% X = X_norm;

runtime = result(:,1); % runtime
power = result(:,2);
rmse = [];
% % X = dlmread('cnn_mnist_features.txt');
% for i = 1:1
% [p,S] = polyfit(X,y,i);
% 
% y_poly = polyval(p,X);
% % rmse = [rmse, sqrt(mean(((y_poly - y)) .^ 2))];
%  rmse = [rmse, sqrt(mean(((y_poly - y)./y) .^ 2))];
% end

%% lasso
y1 = runtime;
[B1,FitInfo1] = lasso(X, y1, 'CV', 10);

y_runtime = X * B1(:,FitInfo1.IndexMinMSE) + FitInfo1.Intercept(FitInfo1.IndexMinMSE);
mse_runtime = sqrt(mean(((y_runtime - y1)./y1) .^ 2));
% mse_runtime = sqrt(mean(((y_runtime - y1)) .^ 2));
disp(mse_runtime);

y2 = power;
[B2,FitInfo2] = lasso(X, y2, 'CV', 10);

y_power = X * B2(:,FitInfo2.IndexMinMSE) + FitInfo2.Intercept(FitInfo2.IndexMinMSE);
mse_power = sqrt(mean(((y_power - y2)./y2) .^ 2));
% mse_power = sqrt(mean(((y_power - y2)) .^ 2));
disp(mse_power);

coeffi_runtime =  [B1(:,FitInfo1.IndexMinMSE)', FitInfo1.Intercept(FitInfo1.IndexMinMSE)];
coeffi_power =  [B2(:,FitInfo2.IndexMinMSE)', FitInfo2.Intercept(FitInfo2.IndexMinMSE)];

csvwrite('coeff_drop.txt', [coeffi_runtime; coeffi_power]);

% y3 = runtime.*power;
% [B3,FitInfo3] = lasso(X, y3, 'CV', 10);
% y_energy = X * B3(:,FitInfo3.IndexMinMSE) + FitInfo3.Intercept(FitInfo3.IndexMinMSE);
% mse_energy = sqrt(mean(((y_energy - y3)./y3).^2));
% % mse_energy = sqrt(mean(((y_energy - y3)).^2));
% % mse_energy = sqrt(mean(((y_power.*y_runtime - y3)./y3).^2));
% disp(mse_energy);

fprintf('%.4f\n%.4f\n%.4f\n', mse_runtime, mse_power, mse_energy)
fprintf('%.4f \t%.4f \t%.4f \t%.4f\n', min(runtime),max(runtime), mean(runtime), median(runtime))
fprintf('%.4f \t%.4f \t%.4f \t%.4f\n', min(power),max(power), mean(power), median(power))

figure(1)
subplot(1,3,1)
scatter(y1, y_runtime,'b');
hold on;
scatter(y1, y1,'k');
hold off;
subplot(1,3,2)
scatter(y2, y_power,'b');
hold on;
scatter(y2, y2,'k');
hold off;
subplot(1,3,3)
scatter(y3, y_energy,'b');
hold on;
scatter(y3, y3,'k');
hold off;
% %% linfit
% % y = runtime;
% B = X\y;
% mse = sqrt(mean(((X*B - y)./y).^2))
% 
% 
% X(:,1:3) = log2(X(:,1:3) + 1);
% X(:,10:11) = log2(X(:,10:11) + 1);
% [B,FitInfo] = lasso(X, y, 'CV', 10);
% y_ls = X * B(:,FitInfo.IndexMinMSE) + FitInfo.Intercept(FitInfo.IndexMinMSE);
% mse_ls = sqrt(mean(((y_ls - y)./y) .^ 2));
% disp(mse_ls);