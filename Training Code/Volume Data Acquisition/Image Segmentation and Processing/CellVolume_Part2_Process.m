micronsPerPixel = 0.23;
load('DataOutput');
Data = DataOutput;
channelHeight = mean([input1, input2]);

CellArea = nan(length(Data)-2);
CellV = CellArea;

for i = 3:length(Data)
    if Data{i,5}
        DIC = Data{i,3}(:,:,1);
        Volume = Data{i,3}(:,:,2);
        CellMask = Data{i,4}(:,:,1);
        AnnulusInnerMask = Data{i,4}(:,:,2);
        VolumeMask = Data{i,4}(:,:,3);
        AnnulusOuterMask = Data{i,4}(:,:,4);
        
        CellArea(i-2) = sum(CellMask(:))*micronsPerPixel^2;
        
        AnnulusPoints = Volume.*(AnnulusOuterMask-AnnulusInnerMask);
        AnnulusPoints = AnnulusPoints(:);
        AnnulusPoints = AnnulusPoints(ne(0,AnnulusPoints));
        meanA = mean(AnnulusPoints);
        
        CellV(i-2) = sum((1-Volume(:)/meanA).*VolumeMask(:)*channelHeight)*micronsPerPixel^2;
    end
end

CellV = CellV(~isnan(CellV));
CellArea = CellArea(~isnan(CellArea));

Volume = CellV;
Area = CellArea;
save('Volume','Volume');
save('Area','Area');

plot(CellArea,CellV,'o','MarkerSize',10)
xlabel('Cell Area um^2')
ylabel('Cell Volume um^3')
title('HT1080 Control')
set(gca,'FontSize',18)

    
    
    