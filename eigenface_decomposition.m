%% load image
clc
clear
folder = ('./testsample');
f = fullfile(folder, 'Test4s.jpg');
oimg = imread(f);
%% cut image in squares
oimg_ht = size(oimg, 1); % original image height
oimg_wd = size(oimg, 2); % original image width
ovr_zn = 35; % *** overlapping zone ***
grd_rt = 20; % *** grinding ratio [1, min(img_ht, img_wd)] ***

grd_rt_bad = 1; % is grinding ratio bad? yes - for the first iteration!
while grd_rt_bad == 1 % check grinding ratio
    grd_rt_bad = 0; % presume now it's OK
    blk_ht = fix(oimg_ht / grd_rt); % block height
    blk_wd = fix(oimg_wd / grd_rt); % block width
    img_wd = blk_wd * grd_rt; % processed width
    img_ht = blk_ht * grd_rt; % processed height
    wdt_dd = oimg_wd - img_wd; % image's width deduction of grinding
    hgt_dd = oimg_ht - img_ht; % image's height -||-

    fprintf('Grinding ratio %d\n', grd_rt);
    fprintf('Block width %d px\n', blk_wd);
    fprintf('Block height %d px\n', blk_ht);
    fprintf('Width deduction %d px\n', wdt_dd);
    fprintf('Height deduction %d px\n', hgt_dd);
    if hgt_dd > ovr_zn
        skd_px = hgt_dd - ovr_zn; % skipped pixels
        fprintf('*** Achtung! Out of the overlapping zone for %d px.\n', skd_px);
        reply = lower(input('Try another ratio? y/n [n]: ', 's'));
        if reply == 'y'
            grd_rt = str2double(input('Grinding ratio: ', 's')); % MAKE RANGE CHECK HERE
            grd_rt_bad = 1; % now we have to recheck
        end
    end
    fprintf('\n');
end

% prepare the matrix with images
blk_dm = [blk_ht, blk_wd];
img_mt = zeros(prod(blk_dm), grd_rt, grd_rt);
for l = 1:grd_rt % group/latitude
    for m = 1:grd_rt % block/longitude
        lf = blk_wd * (l - 1) + 1;
        rt = lf + blk_wd - 1;
        tp = blk_ht * (m - 1) + 1;
        dw = tp + blk_ht - 1;
        gry_im = rgb2gray(oimg(tp:dw, lf:rt, :));
        img_mt(:, m, l) = gry_im(:);
    end
end

clear f folder grd_rt_bad skd_px hgt_dd wdt_dd img
%% training
% shift mean image
mea_fc = mean(img_mt, 2);
sht_mt = img_mt - repmat(mea_fc, 1, grd_rt);

% calculate the ordered eigenvectors and eigenvalues
% each column containins coefficients for one principial component (ordered
% by decreasing component variance)
smp_nm = 10;
smp_ix = 1:smp_nm; % 
eig_vc = zeros(prod(blk_dm), prod(blk_dm), grd_rt);
for l = 1:grd_rt
    [eig_vc(:,:,l), score, evalues] = princomp(img_mt(:, smp_ix, l)');
end

% only retain the top 'num_ei' eigenvectors
num_ei = 10;
eig_vc = eig_vc(:, 1:num_ei, :);

% project the images into the subspace to generate the feature vectors
ftr_vc = zeros(num_ei, smp_nm, grd_rt); 
for l = 1:grd_rt
    ftr_vc(:,:,l) = eig_vc(:,:,l)' * sht_mt(:,smp_ix,l);
end
%% compare squares with eigenfaces
% calculate the similarity of the input to each trainig image
ftr_in = zeros(num_ei, grd_rt, grd_rt);
for l = 1:grd_rt
    ftr_in(:,:,l) = eig_vc(:,:,l)' * sht_mt(:,:,l);
end

irr_sc = zeros(grd_rt, grd_rt); % irregularity score
for l = 1:grd_rt
    for m = 1:grd_rt
        slr = arrayfun(@(f)(norm(ftr_vc(:,f,l) - ftr_in(:,m,l))), 1:smp_nm);
        [mtc_sc, mtc_ix] = min(slr);
        irr_sc(m,l) = mtc_sc;
    end
end
irr_sc = irr_sc / max(max(irr_sc)); % is there more clever way to do this?
%% plot similarityscore and image with found irregularities
%t=(((mean(slr_sc(33:end))-slr_sc(33:end))/std(slr_sc(33:end)))); % ???
%plot(abs(t),'o','MarkerFaceColor','b'),grid on,xlabel('Image-Quadrant'),ylabel('Normalized Similarity Score')
%surf(slr_sc);
%% visualization of irregularities
figure;
% !!! I don't like this way making grayscale RGB... I think it could be
% easier
gry_im = double(rgb2gray(oimg)) ./ 255.0; % convert colour to grayscale and do [0-255] => [0-1]
rgb_im = repmat(gry_im, [1 1 3]); % make RGB image from grayscale

mrk_cl = [.5 .5 0.]; % color of the marker
mrk_pt = cat(3, mrk_cl(1)*ones(blk_dm), mrk_cl(2)*ones(blk_dm), mrk_cl(3)*ones(blk_dm)); % marker pattern
for l = 1:grd_rt % group/latitude
    for m = 1:grd_rt % block/longitude
        lf = blk_wd * (l - 1) + 1;
        rt = lf + blk_wd - 1;
        tp = blk_ht * (m - 1) + 1;
        dw = tp + blk_ht - 1;
        mrk_md = irr_sc(m, l) .* mrk_pt; % marker with modulated by 'similarity score' color
        rgb_im(tp:dw, lf:rt, :) = rgb_im(tp:dw, lf:rt, :) + mrk_md;
    end
end
h = imshow(rgb_im);
%% end of normal code
return
%% display the eigenvectors
figure;
l = 18;
for n = 1:num_ei
    subplot(2, ceil(num_ei/2), n);
    evector = reshape(eig_vc(:,n,l), blk_dm);
    imshow(imadjust(evector));
end
%% display the eigenvalues
normalised_evalues = evalues / sum(evalues);
figure, plot(cumsum(normalised_evalues));
xlabel('No. of eigenvectors'), ylabel('Variance accounted for');
xlim([1 30]), ylim([0 1]), grid on;
