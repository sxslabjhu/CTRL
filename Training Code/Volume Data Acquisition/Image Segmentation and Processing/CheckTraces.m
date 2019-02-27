load('DataOutput.mat');

DataOutput{2,5} = 'Keep';

for i = 3:length(DataOutput)
    if ~isempty(DataOutput{i,1})
        CellB = bwboundaries(DataOutput{i,4}(:,:,1));
        VB = bwboundaries(DataOutput{i,4}(:,:,3));
        figure
        subplot(1,2,1)
        imagesc(DataOutput{i,3}(:,:,1))
        hold on
        for j = 1:length(CellB)
            b = CellB{j};
            plot(b(:,2),b(:,1),'b')
        end
        subplot(1,2,2)
        imagesc(DataOutput{i,3}(:,:,2))
        hold on
        for j = 1:length(VB)
            b = VB{j};
            plot(b(:,2),b(:,1),'b')
        end
        w = waitforbuttonpress;
        if w
            DataOutput{i,5} = isequal(str2double(get(gcf,'CurrentCharacter')),1);
        end
        close all
    else
        DataOutput{i,5} = 0;
    end
end

save('DataOutput','DataOutput');