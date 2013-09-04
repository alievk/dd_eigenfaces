function [img_mt] = imvectorize(img, grd_rt, tile_dm) % converts image to matrix, where columns are tiles of the image
img_mt = zeros(prod(tile_dm), grd_rt, grd_rt);
for l = 1:grd_rt % group/latitude
    for m = 1:grd_rt % block/longitude
        lf = tile_dm(2) * (l - 1) + 1;
        rt = lf + tile_dm(2) - 1;
        tp = tile_dm(1) * (m - 1) + 1;
        dw = tp + tile_dm(1) - 1;
        gry_im = img(tp:dw, lf:rt); %rgb2gray(img(tp:dw, lf:rt, :)); % x = 0.2989 * R + 0.5870 * G + 0.1140 * B 
        img_mt(:, m, l) = gry_im(:);
    end
end