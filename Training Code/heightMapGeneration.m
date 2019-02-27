load('DataOutput.mat')

% enter channel height
leftCH = input1;
rightCH = input2;
chHeight = mean([leftCH,rightCH]);
L = length(DataOutput);

% size requirements on images
imSizeMax = 511;
keepBigCells = 1;

% add a second round a qualitative assesment
qual2 = 1;

% pick fraction for training
trainF = 0.9;

% choose cells to keep (round1 in DataOutput)
qualKeep = nan(L-2,1);
for i = 3:L
    qualKeep(i-2) = isequal(DataOutput{i,5},1);
end

%In case qualitative assesment was not done prior to DataOutput
%construction
if isequal(sum(qualKeep),0)
    qualKeep = ones(L-2,1);
end

%label images by size threshold. Note after this step the big cells are
%cropped and replaced so if you want to examine the original DataOutput you
%will need to reload it to the workspace.
sizeKeep = nan(L-2,1);
for i = 3:L
    sizeKeep(i-2) = le(max(size(DataOutput{i,3})),imSizeMax);
    if ~sizeKeep(i-2)
        [s1,s2,~] = size(DataOutput{i,3});
        if gt(s1,imSizeMax)
            startPos = ceil((s1-imSizeMax)/2);
            DataOutput{i,3} = DataOutput{i,3}(startPos:startPos+imSizeMax-1,:,:); %#ok<SAGROW>
            DataOutput{i,4} = DataOutput{i,4}(startPos:startPos+imSizeMax-1,:,:); %#ok<SAGROW>
        end
        if gt(s2,imSizeMax)
            startPos = ceil((s2-imSizeMax)/2);
            DataOutput{i,3} = DataOutput{i,3}(:,startPos:startPos+imSizeMax-1,:); %#ok<SAGROW>
            DataOutput{i,4} = DataOutput{i,4}(:,startPos:startPos+imSizeMax-1,:); %#ok<SAGROW>
        end
    end
end

if ~keepBigCells
    keepIndi = find(logical(sizeKeep.*qualKeep))+2;
else
    keepIndi = find(qualKeep)+2;
end

L2 = length(keepIndi);
imCell = cell(L2,4);
for i = 1:L2
    imCell{i,1} = DataOutput{keepIndi(i),3};
    imCell{i,2} = DataOutput{keepIndi(i),4};
end

%normalize the DIC and volume images - find the best fit 2nd degree
%polynomial plane to the perimeter (outer 10 pixels) of each image. DIC is
%normalized to have a mean of 0 and Volume is normalized to yield the
%height matrix. No outlier removal (due to camera noise) is conducted as it
%seems to be sufficiently uncommon.
cr = cell(1,1);
for i = 1:L2
    DICchannel = imCell{i,1}(:,:,1);
    Vchannel = imCell{i,1}(:,:,2);
    sizeIm = size(DICchannel);
    [colN,rowN] = meshgrid(linspace(1,sizeIm(2),sizeIm(2)),linspace(1,sizeIm(1),sizeIm(1)));
    box = logical(gt(colN,max(colN(:))-10)+lt(colN,11)+gt(rowN,max(rowN(:))-10)+lt(rowN,11));
    planeDICfit = fit([colN(:),rowN(:)],DICchannel(:),'poly22','weights',box(:));
    planeVfit = fit([colN(:),rowN(:)],Vchannel(:),'poly22','weights',box(:));
    planeDIC = planeDICfit.p00 + planeDICfit.p10*colN+planeDICfit.p01*rowN+planeDICfit.p20*colN.^2+planeDICfit.p11*rowN.*colN+planeDICfit.p02*rowN.^2;
    planeV = planeVfit.p00 + planeVfit.p10*colN+planeVfit.p01*rowN+planeVfit.p20*colN.^2+planeVfit.p11*rowN.*colN+planeVfit.p02*rowN.^2;
    normDIC = DICchannel-planeDIC;
%     Bg = box.*normDIC;
%     Bgv = Bg(:);
%     Bgv(Bgv==0) = [];
%     sbg(i) = std(Bgv);
%     swhole(i) = std(normDIC(:));
%     normDIC2 = (normDIC - mean(Bgv))/std(Bgv);
    normDIC = mat2gray(normDIC);
    normV = chHeight*(1-Vchannel./planeV);
    imCell{i,3} = nan(sizeIm(1),sizeIm(2),2);
    imCell{i,3}(:,:,1) = normDIC;
    imCell{i,3}(:,:,2) = normV;
end

%pad the images
for i = 1:L2
    DICchannel = imCell{i,3}(:,:,1);
    Vchannel = imCell{i,3}(:,:,2);
    bckgndMask = ~imCell{i,2}(:,:,3);
    muDIC = mean(DICchannel(bckgndMask(:)));
    stdDIC = std(DICchannel(bckgndMask(:)));
    muV = mean(Vchannel(bckgndMask(:)));
    stdV = std(Vchannel(bckgndMask(:)));
    fillerDIC = normrnd(muDIC,stdDIC,[imSizeMax+1,imSizeMax+1]);
    fillerV = normrnd(muV,stdV,[imSizeMax+1,imSizeMax+1]);
    [s1,s2] = size(DICchannel);
    startRow = max(ceil((imSizeMax-s1)/2),1);
    startCol = max(ceil((imSizeMax-s2)/2),1);
    fillerDIC(startRow:startRow+s1-1,startCol:startCol+s2-1) = DICchannel;
    fillerV(startRow:startRow+s1-1,startCol:startCol+s2-1) = Vchannel;
    imCell{i,4} = nan(imSizeMax+1,imSizeMax+1,2);
    imCell{i,4}(:,:,1) = fillerDIC;
    imCell{i,4}(:,:,2) = fillerV;
end

% extract cell mask, offset volume image and (gaussian) smooth volume channel
for i = 1:L2
    cellMask = imCell{i,2}(:,:,2);
    [s1,s2] = size(cellMask);
    startRow = max(ceil((imSizeMax-s1)/2),1);
    startCol = max(ceil((imSizeMax-s2)/2),1);
    fillerMask = zeros(imSizeMax+1,imSizeMax+1);
    fillerMask(startRow:startRow+s1-1,startCol:startCol+s2-1) = cellMask;
    
    Vchannel = imCell{i,4}(:,:,2);
    
    % translate volume image up 15 pixel to make up for the offset
    temp = Vchannel;
    Vchannel(1:imSizeMax+1-10+1,:) = temp(10:imSizeMax+1,:);
    Vchannel(imSizeMax+1-10+2:imSizeMax+1,:) = 0;
    
    % extract the mask, clean the background
    Vchannel = fillerMask.*Vchannel;
    
    % gaussian filtration
    smV = imgaussfilt(Vchannel,6); % 6 is a important parameter that I chose
    smV(lt(smV,0)) = 0;
    
    imCell{i,4}(:,:,2) = smV;
    
    hol(i) = max(smV(:));
end

%Complete a round of qualitative inspection.
qualKeep2 = ones(L2,1);
if qual2
    for i = 1:L2
        figure('position',[100 100 1600 800]);
        subplot(1,2,1);
        imagesc(imCell{i,4}(:,:,1));
        subplot(1,2,2);
        imagesc(imCell{i,4}(:,:,2));
        w = waitforbuttonpress;
        keepI = get(gcf,'CurrentCharacter');
        qualKeep2(i) = isequal(str2double(get(gcf,'CurrentCharacter')),1);
        close all
    end
end

save('qualKeep2','qualKeep2');

L3 = sum(qualKeep2);
keepIndi = find(qualKeep2);

%generate training and validation set

nTrain = round(L3*trainF);
nVal = L3-nTrain;

XTrain = zeros(imSizeMax+1,imSizeMax+1,1,nTrain);
YTrain = XTrain;

XVal = zeros(imSizeMax+1,imSizeMax+1,1,nVal);
YVal = XVal;

for i = 1:nTrain
    XTrain(:,:,1,i) = uint8(imCell{keepIndi(i),4}(:,:,1)*255);
    YTrain(:,:,1,i) = imCell{keepIndi(i),4}(:,:,2);
    hm = YTrain(:,:,1,i);
end
for i = nTrain+1:L3
    XVal(:,:,1,i-nTrain) = uint8(imCell{keepIndi(i),4}(:,:,1)*255);
    YVal(:,:,1,i-nTrain) = imCell{keepIndi(i),4}(:,:,2);
    hm = YVal(:,:,1,i-nTrain);
end

save('XTrain','XTrain');
save('YTrain','YTrain');
save('XVal','XVal');
save('YVal','YVal');