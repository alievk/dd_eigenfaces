function [ score ] = fitfunc( feat1, feat2 )
% calculate irregularity score
M = size(feat2, 2);
L = size(feat2, 3);
score = zeros(M, L);
for l = 1:L % each group
    for m = 1:M % each tile
        % compare testing tile feat. with each tile feat. of the same group
        slr = arrayfun(@(f)(norm(feat1(:,f,l) - feat2(:,m,l))), 1:size(feat1,2)); 
        score(m,l) = min(slr);
    end
end