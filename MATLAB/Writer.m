startFrame = 5700;
endFrame = 5850;
length = startFrame - endFrame;

videoIn = VideoReader('Video/Golf.mov')
videoFrames = read(videoIn,[startFrame endFrame]);

videoOut = VideoWriter('Putt4.avi','Motion JPEG AVI');
open(videoOut)
writeVideo(videoOut, videoFrames);

%for i = 0:length
%   writeVideo(videoOut, videoFrames(i));
%end

close(videoOut);

%https://www.mathworks.com/help/matlab/ref/videowriter.html