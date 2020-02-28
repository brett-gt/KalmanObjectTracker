count = 0;
%position = [10 10]; 
%box_color = 'red';
%video = VideoReader('Video/Golf.mov')
video = VideoReader('Putt1.avi')
currAxes = axes;
while hasFrame(video)
    
    vidFrame = readFrame(video);
    
    text_str = ['Frame: ' num2str(count)];

    
    image(vidFrame, 'Parent', currAxes);
    
    text(10, 10, text_str);
        
    currAxes.Visible = 'off';
    pause(1/video.FrameRate);
    count = count + 1;
end