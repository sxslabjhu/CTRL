load('DataSCMovie.mat')

imSizeMax = 511;

DICWL = cell(1,1);

SGTest = zeros(imSizeMax+1,imSizeMax+1,1,1);

for i = 1:length(DataSCMovie)
    
    DICchannel = DataSCMovie{i};
    if size(DICchannel,1) <= imSizeMax+1 && size(DICchannel,2) <= imSizeMax+1 
        sizeIm = size(DICchannel);
        [colN,rowN] = meshgrid(linspace(1,sizeIm(2),sizeIm(2)),linspace(1,sizeIm(1),sizeIm(1)));
        box1 = logical(gt(colN,max(colN(:))-10)+lt(colN,11)+gt(rowN,max(rowN(:))-10)+lt(rowN,11));
        planeDICfit = fit([colN(:),rowN(:)],DICchannel(:),'poly22','weights',box1(:));
        planeDIC1 = planeDICfit.p00 + planeDICfit.p10*colN+planeDICfit.p01*rowN+planeDICfit.p20*colN.^2+planeDICfit.p11*rowN.*colN+planeDICfit.p02*rowN.^2;
        normDIC1 = DICchannel-planeDIC1;
        Bg = box1.*normDIC1;
        Bg1 = Bg(:);
        Bg1(Bg1==0) = [];
% 
%         normDIC1 = (normDIC1 - mean(Bg1)) / std(Bg1);
%         stdhaha(i) = std(Bg1);
%         imSizeMax = imSizeMax;
        DICchannel = normDIC1;

        muDIC = 0;
        stdDIC = 1;
        normcell = normrnd(mean(Bg1),std(Bg1),[imSizeMax+1,imSizeMax+1]);

        [s1,s2] = size(DICchannel);
        startRow = max(ceil((imSizeMax-s1)/2),1);
        startCol = max(ceil((imSizeMax-s2)/2),1);
        normcell(startRow:startRow+s1-1,startCol:startCol+s2-1) = DICchannel;

        DICWL{i,1} = normcell;
    else
        DICWL{i,1} = NaN;
        stdhaha(i) = NaN;
    end
end


for i = 1:length(DICWL)
    i
    figure
    if ~isnan(DICWL{i})
        imagesc(DICWL{i});
        colorbar
        w = waitforbuttonpress;
        keepI = get(gcf,'CurrentCharacter');
        if keepI == '1'
           SGTest(:,:,1,i) = DICWL{i};
        end    
    else
        SGTest(:,:,1,i) = NaN;
    end
    close all
end
% 
% 
% % Batch Assessment
% 
% idxcell = 1;
% numBatchIm = 40;
% numBatchRow = 5;
% numBatchCol = numBatchIm/numBatchRow;
% 
% for iB = 1:floor(length(DICWL)/numBatchIm)
%     iB
%     figure('units','normalized','outerposition',[0 0 1 1])
%     
%     for i = 1:numBatchIm
%         subplot(numBatchRow,numBatchCol,i)
%         imagesc(DICWL{(iB-1)*numBatchIm+i});
%     end
%     
%     for i = 1:numBatchIm
%         w = waitforbuttonpress;
%         if w
%             if isequal(get(gcf, 'CurrentCharacter'),'1')
%                 SGTest(:,:,1,idxcell) = DICWL{(iB-1)*numBatchIm+i};
%                 idxcell = idxcell + 1;
%             end
%         end
%     end
%         
%     close all
% end


% idxcell2 = 0;
% for i = 1:size(SGTest,4)
%     i
%     figure
%     imagesc(SGTest(:,:,:,i));
%     w = waitforbuttonpress;
%     keepI = get(gcf,'CurrentCharacter');
%     if keepI == '1'
%        idxcell2 = idxcell2 + 1;
%        SGTest2(:,:,1,idxcell2) = SGTest(:,:,:,i);
%     end    
%     close all
% end
    
% average-cell (population prism)
X = zeros(imSizeMax+1);
for i = 1:size(SGTest,4)
    X = X + SGTest(:,:,:,i);
end
X = X/size(SGTest,4);
imagesc(X);

% see X values
for i = 1:size(SGTest,4)
   A = SGTest(:,:,:,i); 
   maxX(i) = max(A(:));
   minX(i) = min(A(:));
end
max(maxX)
min(minX)
    