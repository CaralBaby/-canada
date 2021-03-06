%% clean and clear
clc;
clear;
%% 
syms x;
NOE = 0; % initialize NOE
dimension = 16; % the number of concerned dimension
dimension_array = 1:dimension;
lower_bound = repmat(-1,1,dimension);
upper_bound = repmat(1,1,dimension); % the feasible zone of variables
lower_bound_current = lower_bound;
upper_bound_current = upper_bound;
objective_function = @(x)loadfunc(6,x); % load the objective function
x_0 = repmat(0,1,dimension); % initialize const term x_0
f_0 = objective_function(x_0); % calculate f_0 at x_0
NOE = NOE + 1;
sample_point = cell(1,dimension); % initialize sample_point
sample_value = cell(1,dimension); % initialize sample_value
f = cell(2,1); % initialize member functions
ga_opts = gaoptimset('Display','off');
for j = 1:dimension
    [NOE,f{1,j},sample_point,sample_value] = construct_first_order(j,j,sample_point,sample_value,x_0,f_0,lower_bound_current,upper_bound_current,objective_function,NOE);
end
%     if i == 1
%         test_high_order_point = zeros(dimension,1)';
%         for j = 1:nchoose(i)
%             Xtemp = sample_point{i}{j};
%             Xtemp = Xtemp(randperm(numel(Xtemp)));
%             test_high_order_point(j) = Xtemp(1);
%         end
%         RBFtemp = f_0;
%         for j = 1:nchoose(i)
%             RBFtemp = RBFtemp + f{i,j}(test_high_order_point(j));
%         end
%         detector = detect(RBFtemp,objective_function(test_high_order_point));
%         if detector == 1
%             break;
%         else
%             continue;
%         end
%     end

%% function constructed in first-order optimazation
HDMR = @(x)HDMR_function(f,f_0,x,dimension);
x_0_old = x_0; f_0_old = f_0;
[x_0_new, f_0_predict] = ga(HDMR,dimension,[],[],[],[],lower_bound',upper_bound',[], ga_opts); % optimization
f_0_new = objective_function(x_0_new); % f_0_new
NOE = NOE + 1;

%% roulette wheel selection
K =  zeros(1,dimension);
% selected_dimension = select_dimension_func(); % select the first dimension to construct member function
[S,V] = sensitivityAnalyse(dimension, HDMR, lower_bound, upper_bound, K);
selected_dimension = roullete(S);
% selected_dimension = 3;
K(1) = selected_dimension
newbound = shrinkspace(f_0_old,f_0_new,f_0_predict,x_0_new,x_0_old,...
    lower_bound,upper_bound,lower_bound_current,upper_bound_current);
lower_bound_current = newbound(1,:);
upper_bound_current = newbound(2,:);

%% reset
sample_point = cell(1,dimension); sample_value = cell(1,dimension); f = cell(2,1); 
% reset sample point database and member functions
% x_0_old = x_0; f_0_old = f_0; % update old x_0 and f_0

%% first-loop roulette wheel member function construction
i = 1;j = 1; % first order && first dimension
x_0 = x_0_new; f_0 = f_0_new; % renew the zeroth order point and value
[NOE,f{i,j},sample_point,sample_value] = construct_first_order(j,K(1),sample_point,sample_value,x_0,f_0,lower_bound_current,upper_bound_current,objective_function,NOE);
% construct first-order member functions of first dimension

%% function constructed in first-dimension optimazation
HDMR =@(x)HDMR_function(f,f_0,x,1); % HDMR function
x_0_old = x_0_new; f_0_old = f_0_new; % update old x_0 and f_0
[x_0_dimension, f_0_predict] = ga(HDMR,1,[],[],[],[],lower_bound(K(1)),upper_bound(K(1)), [], ga_opts);  % optimize HDMR functions and get new x_0 and f_0
x_0_new(selected_dimension) = x_0_dimension; % update x_0_new
f_0_new = objective_function(x_0_new); % f_0_new
NOE = NOE + 1;
% what if f_0_new is bigger than f_0
newbound = shrinkspace(f_0_old,f_0_new,f_0_predict,x_0_new,x_0_old,...
    lower_bound,upper_bound,lower_bound_current,upper_bound_current);
lower_bound_current = newbound(1,:);
upper_bound_current = newbound(2,:);
f_0_new
if detect(f_0_old,f_0_new) == 1
    pause; 
end

%% construct remained member functions
dimension_number = 1;
second_order_count = 0;
choose = zeros(nchoosek(dimension,2),2); % initialize choose array, each row represents the current two dimension need to be chosen
while dimension_number < dimension && dimension_number < 5 %detect(f_0_new,f_0_old) == 1
    %% 
    dimension_number = dimension_number + 1; % consider which number of dimension
    
    %% roulette wheel selection
%     selected_dimension = select_dimension_func(); % select the first dimension to construct member function
%     if dimension_number == 2
%         selected_dimension = 1;
%         K(dimension_number)  = selected_dimension;
%     else
%         selected_dimension = 2;
%         K(dimension_number)  = selected_dimension;
%     end
    [S,V] = sensitivityAnalyse(dimension, HDMR, lower_bound, upper_bound, K);
    selected_dimension = roullete(S);
    K(dimension_number) = selected_dimension
    
    %% first-order member function construction
    i = 1;j = dimension_number; % first order && first dimension
    x_0 = x_0_new; f_0 = f_0_new; % renew the zeroth order point and value
    [NOE,f{i,j},sample_point,sample_value] = construct_first_order(j,K(dimension_number),sample_point,sample_value,x_0,f_0,lower_bound_current,upper_bound_current,objective_function,NOE);
    % construct first-order member functions of first dimension
    
    %% second-order member function construction
    i = 2; % second-order function to be biuld
    for j = 1:(dimension_number - 1)
        second_order_count = second_order_count + 1;
        choose(second_order_count,:) = [j dimension_number];
        [NOE,f{i,second_order_count}] = construct_second_order(f,[j dimension_number],sample_point,sample_value,x_0,f_0,objective_function,NOE,K,lower_bound_current, upper_bound_current);
    end
    
    %% function constructed in first-dimension optimazation
    HDMR = @(x)HDMR_function_2(f,f_0,x,dimension_number,second_order_count,choose); % HDMR function
    x_0_old = x_0_new; f_0_old = f_0_new; % update old x_0 and f_0
    [x_0_dimension, f_0_predict] = ga(HDMR,dimension_number,[],[],[],[],lower_bound(K(1:dimension_number)),upper_bound(K(1:dimension_number)), [], ga_opts);  % optimize HDMR functions and get new x_0 and f_0
    for i = 1:dimension_number
        x_0_new(K(i)) = x_0_dimension(i); % update x_0_new
    end
    f_0_new = objective_function(x_0_new); % f_0_new
    NOE = NOE + 1;
    newbound = shrinkspace(f_0_old,f_0_new,f_0_predict,x_0_new,x_0_old,...
        lower_bound,upper_bound,lower_bound_current,upper_bound_current);
    lower_bound_current = newbound(1,:);
    upper_bound_current = newbound(2,:);
    if detect(f_0_old,f_0_new) == 1
        pause; 
    end
    f_0_new
end
f_0_new
NOE


%% evaluate HDMR functions' performance
% which is not useful now
% S = lhsdesign(100,dimension);
% S = S.*repmat(upper_bound - lower_bound,100,1) + repmat(lower_bound,100,1);
% for i = 1:100
%     point_temp = S(i,:);
%     point_HDMR = point_temp(K);
%     obj_value(i) =  objective_function(S(i,:));
%     HDMR_value(i) = HDMR(point_HDMR); 
% end
% mean = sum(obj_value)/100;
% temp1 = 0;temp2 = 0;
% for i = 1:100
%     temp1 = temp1 + (obj_value(i) - HDMR_value(i)).^2;
% end
% for i = 1:100
%     temp2 = temp2 + (obj_value(i) - mean).^2;
% end
% R_squre = 1 - temp1/temp2;
% 
% 
% STD = std(obj_value);
% temp1 = 0;
% for i = 1:100
%     temp1 = temp1 + norm(obj_value(i) - HDMR_value(i));
% end
% RAAE = temp1/100/STD;
% 
% RMAE = max(abs(obj_value - HDMR_value))/STD;
% NOE;
