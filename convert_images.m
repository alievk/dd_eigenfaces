script
clear

%% parameters
%base_dir = '/afs/desy.de/group/fla/cavity/eigenface/CAV532';
base_dir = '/pnfs/desy.de/fla/cavity/disk';
output_dir = './equator/';
cavity = 'CAV00532_1'; % !!! test# now is the cavity name
test = '1';
zone = 'E';
% convertion parameters
mode = 'lossy';
quality = 100;
scale = 0.25; % resize
%% convertion
%cavity_dir = strcat(base_dir, '/');
cavity_dir = strcat(base_dir, '/', cavity);
%sample = strcat(cavity, '_', num2str(test), '_', zone, '*');  
sample = strcat(cavity, '_', zone, '*'); % template for the input files
dir_list = dir(fullfile(cavity_dir, sample)); % list all the files in the input directory
for i = 1:size(dir_list, 1)
    input_file = dir_list(i).name;
    if isempty(regexp(input_file, 'png', 'once'))  % skip non-images
        continue;
    end
    oimg = imread(fullfile(cavity_dir, input_file)); % read the original
    output_file = [input_file(1:end-3) 'jpg']; % name of the new file
    rimg = imresize(oimg, scale); % resizing
    imwrite(rimg, fullfile(output_dir, output_file), 'Mode', mode, 'Quality', quality); % write compressed/resized image
end