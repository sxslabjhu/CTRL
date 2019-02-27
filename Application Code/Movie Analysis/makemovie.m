workingDir = cd;

imageNames = dir(fullfile(workingDir,'*.tif'));
imageNames = {imageNames.name}';

outputVideo = VideoWriter(fullfile(workingDir,'m.avi'));
open(outputVideo)

slowRate = 1/5;
for ii = 1:length(imageNames)/slowRate
   img = double(imread(fullfile(workingDir,imageNames{ceil(ii*slowRate)})));
   img = mat2gray(img)*255;
   img = uint8(img);
   writeVideo(outputVideo,img);
end

close(outputVideo)

mAvi = VideoReader(fullfile(workingDir,'m.avi'));
ii = 1;
while hasFrame(mAvi)
   mov(ii) = im2frame(readFrame(mAvi));
   ii = ii+1;
end
figure 
imshow(mov(1).cdata, 'Border', 'tight')