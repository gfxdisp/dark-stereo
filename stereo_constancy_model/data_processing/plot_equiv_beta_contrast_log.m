global pars;
global L_samples;

if exist('pars_table')
    pars_average = pars_table(strcmp(pars_table.obs, 'Average'),:);
    pars = pars_average.pars;
end
L_samples = logspace(-2,3,60);

% plot equiv beta curves
figure()
beta = linspace(0.035,0.055,3);
for n=1:size(beta,2)
    plot(L_samples, compute_contrast(beta(n)));
    hold on
end

xlim(10.^[-2,3])
ylim([0,0.2])
xlabel('Luminance')
ylabel('Logarithmic contrast')
lgd = 'beta = ' + string(beta);
lgd = [lgd 'cpd = 2' '' '' ];
lgd = [lgd 'cpd = 4' '' '' ];
lgd = [lgd 'cpd = 8' '' '' ];

legend(lgd,'Location','northeastoutside')
grid on
set(gca, 'XScale', 'log')
xticklabels(logspace(-2,3,6));
set(gcf,'PaperSize',[7 4]);
print(gcf, 'beta_contrast_equiv_curve.pdf', '-dpdf', '-fillpage');

function C_out = compute_contrast(beta)
    global pars;
    global L_samples;
    for ll=1:size(L_samples,2)
        C_out(ll) = find_C(beta,pars,L_samples(ll));
    end
end

function C = find_C(beta,pars,L)
    A = pars(4);
    B = pars(2);
    K = pars(1).*log10(L)+pars(3).*(log10(L).^2)+pars(5)-beta;
    C = (-B+sqrt(B^2-4*A*K))/(2*A);
end