function  [DataOutput] = CellVolume_SegmentationFunc(experiment_name,experiment_date) %#ok<*NOSEL> - this comment supresses MATLAB generated comments
%regardig unnecessary seimcolons.

%This function returns the segmented images for all cells in the tif files
%stored within the parent directory. Note the DIC channel is used only for
%improving the outer boundary of the cell. The majority of the mask is
%retrieved from the cell volume channel.

%Parameters for Conditioning the image

Tstd = 15;          %Number of std's for removing camera shot noise

%Parameters for Masks

volumefilt = 3;%smooth volume channel for processing
DICfilt = 5;%remove DIC background (liberally)
DICopen = 5;%remove small spots from DIC
DICclose = 5;%smear together spots in DIC
DICerode = 5;%clear boundary of smeared DIC
DICopen2 = 100;%removes larger spots from DIC

Vstd = 1;%std threshold below mean for points sent to mean from volume channel for fitting background plane
VBstd = .5 ;%std threshold below mean for points to be included in the volume mask
% pick 22 for volume dilation
% pick 17 and 33 for the annulus calculation
dilatesizes = floor([17,22,33]);    %Number of pixels moved away from DIC boundary for volume integration and the outer boundary for the definition of the background annulus

%initialize files in the directory

file = dir('*.tif');

Span = length(file);
DataOutput = cell(2,4);%Initialize storage
DataOutput{1,1} = experiment_name;
DataOutput{1,2} = experiment_date;
DataOutput{2,1} = 'FrameNumber';
DataOutput{2,2} = 'CellNumber';
DataOutput{2,3} = 'CroppedImages: DIC, Volume';
DataOutput{2,4} = 'Masks: Cell, InnerAnnulus, Volume, OuterAnnulus';
CellNum = 0;
for i = 1:Span/2;%Here we have 2 channels DIC and Epi
    %Read Filenames
    DICName = file(2*i-1).name;
    GreenName = file(2*i).name;
    if isequal(exist(DICName,'file'),exist(GreenName,'file'));%MATLAB returns the value 2 for exist(tif)
        
        %Import images
        GreenOld = imread(GreenName);
        DICNameOld = imread(DICName);
        DICNameOld = double(DICNameOld);
        
        %select cells in each frame
        flag_redo = 1;
        while isequal(flag_redo,1);%while there are more cells in the frame to select
            CellNum = CellNum + 1;
            Total = double(GreenOld);%volume channel
            DICName = double(DICNameOld(:,:,1));
            figure(1000);
            subplot(1,2,2);
            imshow(Total,[])
            subplot(1,2,1)
            imshow(DICName,[]);
            set(gcf,'units','normalized','outerposition',[0 0 1 1])
            [x,y] = ginput(2);%select cell
            x1 = floor(min(x));
            x2 = ceil(max(x));
            y1 = floor(min(y));
            y2 = ceil(max(y));
            clear x y
            Total = Total(y1:y2,x1:x2);
            DICName = DICName(y1:y2,x1:x2);
            clear x1 x2 y1 y2; close 1000;
            if lt(length(Total(:,1)),50);%if you select a very small box you skip this frame entirely
                %(use this if there are no cells you want in the frame)
                flag_redo = 0;
            else
                ThreshPlus = mean(Total(:)) + Tstd.*std(Total(:)); %Calculate the std from the mean
                ThreshNeg = mean(Total(:)) - Tstd.*std(Total(:)); %Calculate the std from the mean
                
                Total(Total >= ThreshPlus) = mean(Total(:));%remove camera shot noise
                Total(Total <= ThreshNeg) = mean(Total(:));

                %Get binary image for cell mask
                
                %Get bulk of cell from volume channel
                Vs = imgaussfilt(Total,volumefilt);
                VsPlane = Vs;
                VsPlane(lt(Vs,mean(Vs(:))-Vstd*std(Vs(:)))) = mean(Vs(:));
                [R,C] = size(Vs);
                [Cg,Rg] = meshgrid(linspace(1,C,C),linspace(1,R,R));
                sf = fit([Cg(:),Rg(:)],VsPlane(:),'poly11');
                coeffs = coeffvalues(sf);
                planeZline = coeffs(1)+coeffs(2)*Cg(:)+coeffs(3)*Rg(:);
                planeZ = reshape(planeZline,R,C);
                Vsub = Vs-planeZ;
                Vbinary = lt(Vsub,-VBstd*std(Vsub(:)));
                LV = bwlabel(Vbinary);
                blobsV = unique(LV(:));
                blobsVsz = nan(1,length(blobsV)-1);
                for j = 2:length(blobsV)
                    littlLV = LV==blobsV(j);
                    blobsVsz(j-1) = sum(littlLV(:));
                end
                [~,mindiV] = max(blobsVsz);%pick largest blob - works assuming only one cell in selection
                bwkeepV = LV == blobsV(mindiV+1);
                
                %Get added details of the borders from DIC
                SubMat = imgaussfilt(DICName,DICfilt);
                ContMat = DICName-SubMat;
                bw = lt(ContMat,0);
                dist = bwdist(bw)+bwdist(~bw);
                bw2 = gt(dist,1);
                
                %add DIC and volume masks together for combined cell region
                bw2 = logical(bw2+bwkeepV);
                bw3 = bwareaopen(bw2,DICopen);
                bw4 = imclose(bw3,strel('disk',DICclose));
                bw5 = bwareaopen(bw4,DICopen2);
                bw6 = imfill(bw5,'holes');
                bw7 = imerode(bw6,strel('disk',DICerode));
                L = bwlabel(bw7);
                blobls = unique(L(:));
                blobsz = nan(1,length(blobls)-1);
                for j = 2:length(blobls)
                    littlL = L==blobls(j);
                    blobsz(j-1) = sum(littlL(:));
                end
                [~,mindi] = max(blobsz);%pick largest blob - works assuming only one cell in selection
                bwkeep = L==blobls(mindi+1);
                
                DICFrame = DICName-mean(DICName(:));
                Mask = bwkeep;
                MaskNewA1 = imdilate(Mask,strel('disk',dilatesizes(1)));
                MaskNewV = imdilate(Mask,strel('disk',dilatesizes(2)));
                MaskNewA2 = imdilate(Mask,strel('disk',dilatesizes(3)));
                
                Sz = size(DICFrame);
                ChannelBlock = nan(Sz(1),Sz(2),2);
                MaskBlock = nan(Sz(1),Sz(2),4);
                
                ChannelBlock(:,:,1) = DICFrame;
                ChannelBlock(:,:,2) = Total;
                
                MaskBlock(:,:,1) = Mask;%Cell Mask
                MaskBlock(:,:,2) = MaskNewA1;%Inner boundary of Annulus
                MaskBlock(:,:,3) = MaskNewV;%Boundary for Volume integration
                MaskBlock(:,:,4) = MaskNewA2;%Outer boundary of Annulus
                
                DataOutput{CellNum+2,1} = i;
                DataOutput{CellNum+2,2} = CellNum;
                DataOutput{CellNum+2,3} = ChannelBlock;
                DataOutput{CellNum+2,4} = MaskBlock;
                w = waitforbuttonpress;
                if w;
                    flag_redo = str2double(get(gcf,'CurrentCharacter'));
                end
            end
        end
    end
end




