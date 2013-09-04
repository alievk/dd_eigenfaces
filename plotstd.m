base_dir = './equator/cav00532_e4/results';
fname = 'CAV00532_1_E4_0345.5_158.4_23CD78_00_00_200.std';
fid = fopen(fullfile(base_dir, fname));
thr = 0.4;
x = fread(fid, 'double');
hold on
bar(x', 'hist');
plot([1,size(x,1)], repmat(thr,1,2), 'r');
hold off
xlim([1 size(x,1)]);
ylim([0, 1.5]);