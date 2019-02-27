clear all %#ok<CLALL>
clc

dirstruct = dir('*.tif');

minsize = 1000;

stednum = 0.5;
rownum = 20;
colnum = 20;

movM = 3;

L = length(dirstruct);

tif1 = imread(dirstruct(1).name);
[R,C] = size(tif1);


[indiC,indiR] = meshgrid(linspace(1,C,C),linspace(1,R,R));

block = nan(R,C,L);
blockZ = block;
for i = 1:L
    block(:,:,i) = imread(dirstruct(i).name);
end

proj = squeeze(sum(block,3));
projM = gt(proj,mean(proj(:))-stednum*std(proj(:)));

projM = bwareaopen(projM,minsize);
projM = imfill(projM,'holes');
projM = imclose(projM,strel('disk',2));

Rred = floor(R/rownum);
Cred = floor(C/colnum);

redblock = nan(rownum,colnum,L);
NaNM = double(projM);
NaNM(NaNM == 0) = NaN;

for i = 1:L
    for j = 1:rownum
        for k = 1:colnum
            piece = NaNM((j-1)*Rred+1:j*Rred,(k-1)*Cred+1:k*Cred).*block((j-1)*Rred+1:j*Rred,(k-1)*Cred+1:k*Cred,i);
            redblock(j,k,i) = sum(piece(:));
        end
    end
end

heights = nan(1,rownum*colnum);
for i = 1:rownum
    for j = 1:colnum
        jerry = movmeanch(squeeze(redblock(i,j,:)),movM);
        dj = movmeanch(jerry(2:end)-jerry(1:end-1),movM);
        [~,top1] = min(dj);
        [~,bot1] = max(dj);
        ddj = movmeanch(dj(2:end)-dj(1:end-1),movM);
        [~,bot] = max(ddj(1:bot1));
        [~,top] = max(ddj(top1:end));
        top = top+top1-1;
        heights(20*(i-1)+j) = top-bot;
    end
end

heights = heights(gt(heights,0));

mHeight = mean(heights);
sHeight = std(heights);

save('mHeight','mHeight')
save('sHeight','sHeight')

display(mean(heights))
display(std(heights))

figure
subplot(1,2,1)
imagesc(projM)
subplot(1,2,2)
imagesc(squeeze(sum(redblock,3)))

