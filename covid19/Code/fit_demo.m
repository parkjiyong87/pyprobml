function fit_demo()

load('../Data/M.mat') %M(l,l,t)
load('../Data/pop.mat') % pop(l)
load('../Data/incidence.mat') % O(t,l)
obs_truth=incidence'; % obs(l,t)
fig_folder = '~/covid19/Figures';

input_data_test.M = M;
input_data_test.pop = pop;
output_data_test = obs_truth;

ntrain = 10;
input_data_train.M = M(:,:,1:ntrain);
input_data_train.pop = pop;
output_data_train = obs_truth(:, 1:ntrain);

%{
model = [];
model.params = set_params(1);
model.add_delay = true;
model.num_integration_steps = 1;
model.add_noise = false;
model.name = sprintf('paper-noise%d-nsteps%d', ...
    model.add_noise, model.num_integration_steps);
rng(42);
num_ens = 100;
model.loss_train = mc_objective(model, input_data_train, output_data_train, num_ens);
model.loss_test = mc_objective(model, input_data_test, output_data_test, num_ens);
model_paper = model;
samples = sample_data(model, input_data_test, num_ens);
plot_samples(samples, output_data_test);
suptitle(sprintf('%s mae-train=%5.3f mae-test=%5.3f', ...
    model.name, model.loss_train, model.loss_test));
fname = sprintf('%s/predictions-%s-%s', fig_folder, model.name);
print(fname, '-dpng');
%}


seeds = 3:10;
ntrials = length(seeds);
models = cell(1, ntrials);
loss_list = zeros(1, ntrials);
for i = 1:ntrials
    model = [];
    model.seed = seeds(i);
    rng(model.seed);
    num_ens = 100;
    model.max_iter = 20;
    %model.method = 'nelder-mead';
    model.method = 'lsqnonlin';
    model.params = initialize_params(1, true);
    model.add_noise = false;
    model.add_delay = true;
    model.num_integration_steps = 1;
    model.ntrain = ntrain;
    model.name = sprintf('%s-ntrain%d-seed%d-iter=%d-noise%d-nsteps%d', ...
        model.method, model.ntrain, model.seed, model.max_iter, model.add_noise, ...
        model.num_integration_steps);
        
    %[model, loss] = fit_model_nelder_mead(...
    %    model, input_data_train, output_data_train, num_ens, model.max_iter);
    [model, loss] = fit_model_lsqnonlin(...
        model, input_data_train, output_data_train, num_ens, model.max_iter);
    
    model.loss_train = loss;
    model.loss_test = mc_objective(model, input_data_test, output_data_test, num_ens);
    
    models{i} = model;
    loss_list(i) = loss;
end


[loss, ndx] = min(loss_list);
model = models{ndx}; % seed 3
rng(42);
num_ens = 100;
samples = sample_data(model, input_data_test, num_ens);
plot_samples(samples, output_data_test)
%loss_test = mc_objective(model, data_test,  num_ens);
suptitle(sprintf('%s mae-train=%5.3f mae-test=%5.3f', ...
    model.name, model.loss_train, model.loss_test));
fname = sprintf('%s/predictions-%s-%s', fig_folder, model.name);
print(fname, '-dpng');
    
keyboard
end



