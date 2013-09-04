function [ tile_ht, tile_wd ] = checkgratio( oimg_ht, oimg_wd, ovr_zn, grd_rt )
grd_rt_bad = 1; % is grinding ratio bad? yes - for the first iteration!
while grd_rt_bad == 1 % check grinding ratio
    grd_rt_bad = 0; % presume now it's OK
    tile_ht = fix(oimg_ht / grd_rt); % block height
    tile_wd = fix(oimg_wd / grd_rt); % block width
    img_wd = tile_wd * grd_rt; % processed width
    img_ht = tile_ht * grd_rt; % processed height
    wdt_dd = oimg_wd - img_wd; % image's width deduction of grinding
    hgt_dd = oimg_ht - img_ht; % image's height -||-

    fprintf('\n---\n');
    fprintf('Grinding ratio %d\n', grd_rt);
    fprintf('Block width %d px\n', tile_wd);
    fprintf('Block height %d px\n', tile_ht);
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
        clear skd_px;
    end
    fprintf('\n');
end