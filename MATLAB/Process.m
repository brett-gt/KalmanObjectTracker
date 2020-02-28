count = 0;
video = VideoReader('Putt1.avi')
currAxes = axes;

frameRate = 30;

box_X = 650;
box_Y = 520;
box_W = 120;
box_H = 120;


vidFrame = readFrame(video);
prevFrame = vidFrame;

while hasFrame(video)
    
    vidFrame = readFrame(video);
    
    %%% Preprocessing Stage %%   
    %Experimenting: 120 - 150 seemed like good numbers
    subFrame = vidFrame(box_Y:box_Y+box_H, box_X:box_X+box_W,1:3);
    preFrame = colorChop(subFrame, 140);
     
    Blobs = ConnectedLabel(preFrame);
  
    %%% Rendering Stage %%%
    text_str = ['Frame: ' num2str(count)];
    
    imshow(vidFrame, 'Parent', currAxes);
    %rectangle('Position',[box_X,box_Y,box_W,box_H],'Edgecolor', 'r');
    
%     largest = 0;
%     X, Y, W, H = 0;
%     for m = 1:size(Blobs)
%         if(getArea(Blobs(m)) > largest)
%             X = Blobs(m).MinCol + box_X;
%             Y = Blobs(m).MinRow + box_Y;
%             W = Blobs(m).MaxCol - Blobs(m).MinCol;
%             H = Blobs(m).MaxRow - Blobs(m).MinRow;
%             largest = getArea(Blobs(m));
%         end
%     end
    largest = GetBiggestBlob(Blobs);
    X = largest.MinCol + box_X;
    Y = largest.MinRow + box_Y;
    W = largest.MaxCol - largest.MinCol;
    H = largest.MaxRow - largest.MinRow;
    rectangle('Position',[X,Y,W,H],'Edgecolor', 'r');  
    
    text(10, 10, text_str);
            
    currAxes.Visible = 'off';
    pause(1/video.FrameRate);
    count = count + 1;
end

    
    
    %%% Comparison Stage %%%
    % Subtracting the frames didn't seem to help much
    %compFrame = preFrame - prevFrame;
