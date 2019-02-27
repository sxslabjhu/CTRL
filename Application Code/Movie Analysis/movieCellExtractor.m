clear
clc
close all

file = dir('*.tif');
numFiles = length(file);

totalframe = numFiles;
minframe = 1;
maxframe = 107;

DataSCMovie = cell(1,1);
f = 1;

pic = cell(3,1);
for i = minframe:1:maxframe
    pic{i,1} = imread(file(i).name);
end

for i = minframe:1:maxframe
    imagesc(pic{i,1})
    colormap gray
    colorbar
    title(int2str(i))

    [x,y] = ginput(2); %select cell
    x1 = floor(min(x));
    x2 = ceil(max(x));
    y1 = floor(min(y));
    y2 = ceil(max(y));
    if x2-x1 > 5
        cellthis = pic{i}(y1:y2,x1:x2);
        DataSCMovie{f,1} = double(cellthis);
        f = f + 1;
    end
    
end

