function [eigenvecs score evalues] = eidecompose(img_mt, eivec_num)
% calculate the ordered eigenvectors and eigenvalues
% each column containins coefficients for one principial component (ordered
% by decreasing component variance)
M = size(img_mt, 1);
L = size(img_mt, 3);
eigenvecs = zeros(M, M, L);
for l = 1:L
    [eigenvecs(:,:,l), score, evalues] = princomp(img_mt(:, :, l)');
    fprintf(' .');
end
% only retain the top 'num_ei' eigenvectors
eigenvecs = eigenvecs(:, 1:eivec_num, :);