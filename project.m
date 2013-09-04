function [ features ] = project( eigenvectors, vectors )
samples_num = size(vectors, 2);
groups_num = size(vectors, 3);
eivec_num = size(eigenvectors, 2);
features = zeros(eivec_num, samples_num, groups_num); 
for l = 1:groups_num
    features(:,:,l) = eigenvectors(:,:,l)' * vectors(:, :, l);
end