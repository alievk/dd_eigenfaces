script
clc
clear
ok_msg = ' [OK]\n';
it_msg = '.';
%% load training images
base_dir = ('./equator/cav00532_e4');
%base_dir = ('./equator/cav00524_e3');
dir_list = dir(base_dir);
% trn_fnames =    ['CAV00524_1_E3_0230.4_008.0_23CD78_00_00_039.jpg';
%                 'CAV00524_1_E3_0230.4_012.0_23CD78_00_00_068.jpg';
%                 'CAV00524_1_E3_0230.4_016.0_23CD78_00_00_098.jpg';
%                 'CAV00524_1_E3_0230.4_024.0_23CD78_00_00_157.jpg';
%                 'CAV00524_1_E3_0230.4_028.0_23CD78_00_00_000.jpg';
%                 'CAV00524_1_E3_0230.4_040.0_23CD78_00_00_334.jpg'];
                

trn_fnames =     ['CAV00532_1_E4_0345.5_009.6_23CD78_00_00_100.jpg';  % *** training image ***
                 'CAV00532_1_E4_0345.5_019.2_23CD78_00_00_100.jpg';
                 'CAV00532_1_E4_0345.5_024.0_23CD78_00_00_100.jpg';
                 'CAV00532_1_E4_0345.5_033.6_23CD78_00_00_100.jpg';
                 'CAV00532_1_E4_0345.5_124.8_23CD78_00_00_200.jpg';
                 'CAV00532_1_E4_0345.5_129.6_23CD78_00_00_200.jpg';
                 'CAV00532_1_E4_0345.5_187.2_23CD78_00_00_200.jpg'];
trn_num = size(trn_fnames, 1); % number of training images
%% cut image in squares
ovr_zn = 35; % *** overlapping zone ***
grd_rt = 10; % *** grinding ratio [1, min(img_ht, img_wd)] ***

tile_ht = 0;
tile_wd = 0;
tile_dm = [0 0];
fprintf('Loading trainig images\n');
for i = 1:trn_num
    fname = trn_fnames(i, :);
    fprintf(fname);
    img = imread(fullfile(base_dir, fname));
    % cut off the sides from the welding seam
    sides_ix = [1:264 596:size(img, 2)];
    trn_img = img(:, sides_ix, 3); % use BLUE cannel
    % original image = not yet cut to squares 
    if i == 1
        oimg_ht = size(trn_img, 1); % original image height
        oimg_wd = size(trn_img, 2); % original image width
        [tile_ht tile_wd] = checkgratio(oimg_ht, oimg_wd, ovr_zn, grd_rt); % check that 'grinding' ratio
        tile_dm = [tile_ht tile_wd]; % tile dimensions
    end
    % convert image to matrix, tiles in columns, groups in layers
    om = imvectorize(trn_img, grd_rt, tile_dm);
    sm = imshift(om); % calculate mean-shift matrix
    if i == 1
        trn_om = om;
        trn_sm = sm;
    else
        trn_om = cat(2, trn_om, om);
        trn_sm = cat(2, trn_sm, sm);
    end
    fprintf(ok_msg);
end

clear temp_img grd_rt_bad wdt_dd hgt_dd;
%% train the algorithm
eig_num = 5; % number of eigenvectors that go on
fprintf('\nNumber of eigenvectors %d\n', eig_num);

fprintf('\nCalculating eigenvectors (it can take a long)');
[eig_vc scores eig_val] = eidecompose(om, eig_num); % do PCA on training image
fprintf('\nProjecting samples into eigenvectors space');
trn_fch = project(eig_vc, trn_sm); % features of the samples
fprintf(ok_msg);

%% process testing images
tst_num = size(dir_list, 1) - trn_num; % number of tested images
% create folder for images with marked irregularities
result_dir = fullfile(base_dir, 'results');
mkdir(result_dir);
% process each picture of the equator (save training ones)
for i = 1:tst_num
    if dir_list(i).isdir % skip directories
        continue;
    end
    fname = dir_list(i).name;
    is_trn = false;
    for j = 1:trn_num % check is it training image filename
        if strcmp(trn_fnames(j,:), fname)
            is_trn = true;
            break;
        end
    end
    if is_trn % is it a training image?
        continue;
    end
    % load an image
    fprintf('\n%d. Testing image %s', i, fname);
    img = imread(fullfile(base_dir, fname));
    
    % cut off the sides from the welding seam
    tst_im = img(:, sides_ix, 3); % use BLUE cannel
    
    % vectorize and mean-shift
    tst_om = imvectorize(tst_im, grd_rt, tile_dm); 
    tst_sm = imshift(tst_om);
    
    % calculate feature vectors
    tst_fch = project(eig_vc, tst_sm);
    
    % calculate irregularity scores
    irr_scr = fitfunc(trn_fch, tst_fch);
    
    % calculate normalized [0;1] standart deviation for each group
    std_dv = std(irr_scr);
    std_dv = std_dv ./ repmat(max(std_dv), 1, size(std_dv, 2));
    
    fid = fopen(fullfile(result_dir, strcat(fname(1,1:end-3), 'std')), 'w');
    fwrite(fid, std_dv, 'double');
    fclose(fid);
    
    % calculate normalized [0;1] irregularity score for each tile
    irr_scr = irr_scr - repmat(mean(irr_scr), size(irr_scr, 1), 1);
    irr_scr = irr_scr - repmat(min(irr_scr),  size(irr_scr, 1), 1);
    irr_scr = irr_scr./ repmat(max(irr_scr),  size(irr_scr, 1), 1);
    
    % mark irregularities on the testing image
    gry_im = double(tst_im) ./ 255.0; % convert colour to grayscale and do [0-255] => [0-1]
    rgb_im = repmat(gry_im, [1 1 3]); % make RGB image from grayscale

    mrk_cl = [.5 .5 0.]; % color of the marker
    mrk_pt = cat(3, mrk_cl(1)*ones(tile_dm), mrk_cl(2)*ones(tile_dm), mrk_cl(3)*ones(tile_dm)); % marker pattern
    for l = 1:grd_rt % group/latitude
        for m = 1:grd_rt % block/longitude
            if std_dv(l) < 0.4
                 continue
            end
            lf = tile_wd * (l - 1) + 1;
            rt = lf + tile_wd - 1;
            tp = tile_ht * (m - 1) + 1;
            dw = tp + tile_ht - 1;
            mrk_md = irr_scr(m, l) .* mrk_pt; % marker with modulated by 'similarity score' color
            rgb_im(tp:dw, lf:rt, :) = rgb_im(tp:dw, lf:rt, :) + mrk_md;
        end
    end
    
    % write marked image to a file
    imwrite(rgb_im, fullfile(result_dir, fname), 'Mode', 'lossy', 'Quality', 50);
    fprintf(ok_msg);
end