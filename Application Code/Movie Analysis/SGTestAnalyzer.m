SGTestNorm = SGTest;
for i = 1:size(SGTest,4)
    S = SGTestNorm(:,:,:,i);
    S = uint8(mat2gray(S)*255);
    SGTestNorm(:,:,:,i) = S;
end

%%
% watch SGTest

figure
framethis = 1;
minperframe = 5;
imagesc(SGTestNorm(:,:,:,framethis))
title(strcat(num2str(framethis/(60/minperframe)),' hours - No. ',int2str(framethis),' frame'))
colorbar
stop = 0;

while stop == 0
    w = waitforbuttonpress;
    if w
        if isequal(get(gcf, 'CurrentCharacter'),'1')
            if framethis == 1

            else
            imagesc(SGTestNorm(:,:,:,framethis - 1))
            colorbar
            framethis = framethis - 1;
            title(strcat(num2str(framethis/(60/minperframe)),' hours - No. ',int2str(framethis),' frame'))
            end
        end
        if isequal(get(gcf, 'CurrentCharacter'),'2')
            clf
            imagesc(SGTestNorm(:,:,:,framethis + 1))
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





%%

% generate volume curve 

TestEnt = SGTestNorm;
netEnt = netMARCC_reg_512_0t255_newloss_0116_2_850ep_850ep_850ep_850ep;

vol = zeros(size(TestEnt,4),2);
vol(:,1) = 1:length(vol)';
area(:,1) = vol(:,1);
act = cell(1,1);

for i = 1:size(TestEnt,4)
    if ~isnan(SGTestNorm(:,:,:,i))
        act{i,1} = activations(netEnt,imrotate(SGTestNorm(:,:,:,i),180),'conv'); % rotated/transposed because prism is backwards
        vol(i,2) = sum(act{i,1}(:))*0.23^2;
        
        % calculate cell area
        gaua = imgaussfilt(act{i,1},3);
        c = ceil(gaua/0.1);
        c(c<2) = 0;
        c(c>=2) = 1;
        area(i,2) = sum(c(:))*0.23^2;
        
        S = SGTestNorm(:,:,:,i);
        maxh(i) = max(S(:));
        minh(i) = min(S(:));
    else
        vol(i,2) = NaN;
        area(i,2) = NaN;
    end
end

outExcludeOp = 1;
if outExcludeOp
    outlierFrame = [70];
    for o = 1:length(outlierFrame)
        vol(outlierFrame(o),2) = NaN;
        area(outlierFrame(o),2) = NaN;
    end
end

divDiv2Op = 1;
if divDiv2Op
    divDiv2Op = [93:107];
    for o = 1:length(divDiv2Op)
        vol(divDiv2Op(o),2) = vol(divDiv2Op(o),2) / 2;
        area(divDiv2Op(o),2) = area(divDiv2Op(o),2) /2;
    end
end

close all
figure;
subplot(3,1,1)
idx = ~isnan(vol(:,2));
xv = vol(idx,1);
yv = vol(idx,2);
plot(xv,(yv),'o-');hold on
plot(xv,smooth(yv),'o-')
xlim([0,120])


subplot(3,1,2)
idx = ~isnan(area(:,2));
xa = area(idx,1);
ya = area(idx,2);
plot(xa,(ya),'o-');hold on
plot(xa,smooth(ya),'o-')
xlim([0,120])

subplot(3,1,3)
plot(xa,yv./ya,'o-')
xlim([0,120])