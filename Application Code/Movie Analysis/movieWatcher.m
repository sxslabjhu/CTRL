clear
clc
close all

file = dir('*.tif');
numFiles = length(file);
minperframe = 5;

framethis = 1;

figure
imagesc(double(imread(file(framethis).name)))
title(strcat(num2str(framethis/(60/minperframe)),' hours - No. ',int2str(framethis),' frame'))
colorbar
stop = 0;

while stop == 0
    w = waitforbuttonpress;
    if w
        if isequal(get(gcf, 'CurrentCharacter'),'1')
            if framethis == 1

            else
            imagesc((double(imread(file(framethis-1).name))))
            colorbar
            framethis = framethis - 1;
            title(strcat(num2str(framethis/(60/minperframe)),' hours - No. ',int2str(framethis),' frame'))
            end
        end
        if isequal(get(gcf, 'CurrentCharacter'),'2')
            clf
            imagesc((double(imread(file(framethis+1).name))))
            colorbar
            framethis = framethis + 1;
            title(strcat(num2str(framethis/(60/minperframe)),' hours - No. ',int2str(framethis),' frame'))
        end
        if isequal(get(gcf, 'CurrentCharacter'),'0')
            close all
            stop = 1;
        end
    end
end

