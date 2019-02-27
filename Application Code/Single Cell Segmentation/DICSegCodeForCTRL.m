rector = dir('*.tif');
R = length(rector)/1;

%%%   Initializing DataDIC
DataDIC = cell(1,5);
DataDICreadme = cell(1,5);
DataDICreadme{1,1} = 'Cell';
DataDICreadme{1,2} = 'Frame Index';
DataDICreadme{1,3} = 'Cell Index in Frame';
DataDICreadme{1,4} = 'Cell Processed for DL input';
DataDICreadme{1,5} = 'Qualitative Assessment';

ncell = 0;

%%%   Extracting single cells from DIC frames
for iframe = 1:R
    iframe
    
    DICthisframe = imread(rector((iframe-1)*1+1).name);
%   figure; imagesc(DICthisframe);

    e = edge(DICthisframe);
    gau = imgaussfilt(double(e),5);
    gaudenoise = bwareaopen(gau,3000);
    gauclose = imclose(gaudenoise,strel('disk',50));
    gaufilledholes = imfill(gauclose,'holes');
    gauclearborder = imclearborder(gaufilledholes);

%   figure; imagesc(gauclearborder);

    imgseg = gauclearborder;
    Label = bwlabel(imgseg);
    LabelCount = max(Label(:));

    
    for icell = 1:LabelCount
        ncell = ncell + 1;
        
        cellthis = Label == icell;
        bb = regionprops(cellthis,'boundingbox');
        bb = bb.BoundingBox;
        
        DataDIC{ncell,1} = DICthisframe(floor(bb(2)):ceil(bb(2)+bb(4)), ...
            floor(bb(1)):ceil(bb(1)+bb(3)));
        DataDIC{ncell,2} = iframe;
        DataDIC{ncell,3} = icell;
    end
    
end

%%%   Padding single cells and normlizing for DL input
imSizeMax = 512;
for i = 1 : size(DataDIC,1)
    cellthis = double(DataDIC{i,1});
    if size(cellthis,1) <= imSizeMax && size(cellthis,2) <= imSizeMax
        sizeIm = size(cellthis);
        
        % subtract background intensity skew, norm image by making bgbox a
        % n(0,1) distribution
        [colN,rowN] = meshgrid(linspace(1,sizeIm(2),sizeIm(2)),linspace(1,sizeIm(1),sizeIm(1)));
        box1 = logical(gt(colN,max(colN(:))-10)+lt(colN,11)+gt(rowN,max(rowN(:))-10)+lt(rowN,11));
        planeDICfit = fit([colN(:),rowN(:)],cellthis(:),'poly22','weights',box1(:));
        planeDIC = planeDICfit.p00 + planeDICfit.p10*colN+planeDICfit.p01*rowN+planeDICfit.p20*colN.^2+planeDICfit.p11*rowN.*colN+planeDICfit.p02*rowN.^2;
        normDIC = cellthis - planeDIC;
        Bgbox = box1.*normDIC;
        Bgbox = Bgbox(:);
        Bgbox(Bgbox==0) = [];
        normDIC = (normDIC - mean(Bgbox)) / std(Bgbox);
        
        % padding
        muDIC = 0;
        stdDIC = 1;
        normcell = normrnd(muDIC,stdDIC,[imSizeMax,imSizeMax]);
        [s1,s2] = size(cellthis);
        startRow = max(ceil((imSizeMax-1-s1)/2),1);
        startCol = max(ceil((imSizeMax-1-s2)/2),1);
        normcell(startRow:startRow+s1-1,startCol:startCol+s2-1) = normDIC;
        normcell = uint8(mat2gray(normcell)*255);
        
        % save processed (padded, normalized) image to 
        DataDIC{i,4} = normcell;
    end
end

%%%   (GUI-based) Qualitatively assessing which cells are good single cells
GroupSize = 15;
numGroup = ceil(size(DataDIC,1)/15);
for i = 1 : numGroup
    
    f = figure('Visible','on','Position',[-1700,100,1500,800]);
    if i < numGroup
        h.checkbox = cell(GroupSize,1);
    end
    if i == numGroup
        h.checkbox = cell(size(DataDIC,1)-(numGroup-1)*GroupSize,1);
    end
    for ii = 1:GroupSize
        if (i-1)*GroupSize+ii <= size(DataDIC,1)
            cellthis = DataDIC{(i-1)*GroupSize+ii,4};
            cellthis = double(cellthis);
            h.checkbox{ii} = uicontrol(f,'Style','checkbox','Value',1, ... 
                'Position',[25+250*(rem(ii,5)+(1-(rem(ii,5)>0))*5),775-250*(ceil(ii/5)),20,20]);
            subplot(3,5,ii)
            imagesc(cellthis)
        end
    end
    
    hcont = uicontrol(f,'Position',[20 20 200 40],'String','Continue',...
                  'Callback','uiresume(gcbf)');
    uiwait(gcf); 
    
    for ii = 1:GroupSize
        if (i-1)*GroupSize+ii <= size(DataDIC,1)
            DataDIC{(i-1)*GroupSize+ii,5} = get(h.checkbox{ii}, 'Value');
        end
    end
    
    close 
end

%%%   Saving them to a new XTest or XTrain (X for DL)
XExp = zeros(imSizeMax,imSizeMax,1);
idxcell = 0;
for i = 1:length(DataDIC)
    if DataDIC{i,5} == 1
        idxcell = idxcell + 1;
        XExp(:,:,idxcell) = DataDIC{i,4};
    end
end

%%%   Saving everything
save('XExp','XExp');
save('DataDIC','DataDIC');
save('DataDICreadme','DataDICreadme');