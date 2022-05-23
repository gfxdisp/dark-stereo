clear all
close all
global compute_beta lb ub sigma_square;

% Quadratic model for STEREO CONSTANCY (Eq3)
compute_beta = @(pars, L, C)(pars(1).*log10(L)+pars(2).*C+pars(3).*(log10(L).^2)+pars(4).*C.^2+pars(5));
x0 = [.000 0.000 -0.0015 0.3 0.000];
lb = [-1 -1 -1 -1 -1];
ub = [1 1 1 1 1];
sigma_square = 0.001;

% Load and process data
D = dataset( 'File', '../../data/data_3d_shape_perception.csv', 'Delimiter', ',' );
D.contrast = D.contrast*0.01;
log_contrast = unique( D.contrast);
% Conversion from Webber to log
D.contrast = 0.5*log10((D.contrast/2+1)./(1-D.contrast/2));

OBs = unique( D.observer );
global AGs Ls Cs
AGs = unique( D.angle );
Ls = unique( D.adapt_lum);
Cs = unique( D.contrast);

T = table([],[],[],[],{},'VariableNames',{'L','C','beta','thr','obs'});
pars_table = table([],{},'VariableNames',{'pars','obs'});

% Compute the optimal paramters using MAP (Eq5)
D_oo = D;
opt_pars =  compute_pars(compute_beta, x0, D_oo);
pars_table = [pars_table; table(opt_pars,{'Average'},'VariableNames',{'pars','obs'})];

% Compute Beta for each experiment condition after fitting the model
for ll = 1:length(Ls)
    D_ll = D_oo(D_oo.adapt_lum == Ls(ll), :);
    for cc = 1:length(Cs)
        D_ll_cc = D_ll(D_ll.contrast == Cs(cc), :);
        pars_obs = pars_table(strcmp(pars_table.obs, 'Average'),:);
        beta = compute_beta(pars_obs.pars, Ls(ll), Cs(cc));
        T1 = table(Ls(ll),Cs(cc),beta,90,{'Average'},'VariableNames',{'L','C','beta','thr','obs'});
        T = [T ; T1];
    end
end

% Store model parameters
writetable(T,'fitted_threshold_beta.csv','Delimiter',',')
writetable(pars_table,'fitted_model.csv','Delimiter',',')

% Plot the fitted model per condition (Fig 4)
pp = 1;
D_oo = D;
T_oo = T(strcmp(T.obs, 'Average'), :);
for ll = 1:length(Ls)
    D_ll = D_oo(D_oo.adapt_lum == Ls(ll), :);
    T_ll = T_oo(T_oo.L == Ls(ll), :);
    for cc = 1:length(Cs)
        subplot(size(Ls,1),size(Cs,1),pp);
        pp=pp+1;
        if (ll == 1 && cc==1)
            continue
        end
        D_ll_cc = D_ll(D_ll.contrast == Cs(cc), :);
        T_ll_cc = T_ll(T_ll.C == Cs(cc), :);
        mm = [];
        ci_neg = [];
        ci_pos = [];
        ww_steps = linspace(65,115,1000);
        ww = 1-exp(log(0.5)*(10.^(ww_steps - T_ll_cc.thr)).^T_ll_cc.beta);
        for aa=1:length(AGs)
            D2 = D_ll_cc(D_ll_cc.angle == AGs(aa), :);
            [phat,pci] = binofit(sum(D2.answer), size(D2.answer,1), 0.01);
            mm(aa) = phat;
            ci_neg(aa) = phat - pci(1);
            ci_pos(aa) = pci(2) - phat;
        end
        errorbar(AGs,mm,ci_neg,ci_pos,'r*');
        hold on;
        if ll==1 && cc==1
            plot(ww_steps,ones(size(ww_steps))*0.5);
        else
            plot(ww_steps,ww);
        end
        title(['C=',num2str(log_contrast(cc)), ', L=', num2str(Ls(ll))]);
        str = {'{\beta} = ' + string(round(T_ll_cc.beta, 3))};
        text(65,0.9,str);
        hold off;
        grid on;
        xlabel('Angle');
        if cc==1 && ll==3
            ylabel('Pct of selecting "obtuse"');
        else
            ylabel('');
        end
        yticks(0.1:0.2:0.9);
        yticklabels({'10%','30%','50%','70%','90%'});
        ylim([-0.02,1.02]);
        xticks(AGs);
    end
end

set(gcf,'PaperSize',[20 60/5]/1.4);
print(gcf, 'beta_per_condition.pdf', '-dpdf', '-fillpage');

% Plot the equivalent-beta lines in log scale
plot_equiv_beta_contrast_log

function pars = compute_pars(compute_beta, x0, D_oo)

global lb ub sigma_square

Loss = @(pars)( -log(product_likelihood(pars, D_oo, compute_beta))...
    +1/(2*sigma_square)*(pars(4)-0.4)^2+1/(2*sigma_square)*(pars(3)+0.4)^2);
pars = patternsearch( Loss, x0, [],[],[],[], lb, ub);

end

function L = product_likelihood(pars, D_oo, compute_beta)

global AGs Ls Cs
likelihood = @(p, n, k)((nchoosek(n,k).*p.^k).*(1-p).^(n-k));
compute_p = @(angle, beta) (1-exp(log(0.5)*(10.^((angle - 90).*beta))));

L=1;
for ll = 1:length(Ls)
    D_ll = D_oo(D_oo.adapt_lum == Ls(ll), :);
    for cc = 1:length(Cs)
        D_ll_cc = D_ll(D_ll.contrast == Cs(cc), :);
        for aa = 1:length(AGs)
            D_ag = D_ll_cc(D_ll_cc.angle == AGs(aa), :);
            if isempty(D_ag)
                break
            end
            n = length(D_ag);
            k = sum(D_ag.answer==1);
            p = compute_p(AGs(aa), compute_beta(pars, Ls(ll), Cs(cc)));
            L=L.*likelihood(p,n,k);
        end
    end
end
end