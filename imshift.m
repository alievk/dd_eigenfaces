function [mean_im] = imshift(img_mt)
mean_column = mean(img_mt, 2);
mean_im = img_mt - repmat(mean_column, 1, size(img_mt, 2));