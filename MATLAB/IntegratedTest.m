% IntegratedTest
%   Top level function to test the algorithm implementation

clear;

%TODO: Look at changing Kalman filter mid-stream - too much
%jerk,deceleration is killing momentum when it is obstructed.  Perhaps set
%jerk to 0

video = VideoReader('..\Test Files\Putt1.avi')
currAxes = axes;
currAxes.Visible = 'off';

%Cutoff used to determine foreground form background
%200 seemed to work well also, shadow on side of ball affects it though
COLOR_CHOP_CUTOFF = 140;

frameRate = 30;

Y_var = 1;
X_var = 2;

%%%%%% INITIAL BOUNDING BOX %%%%%%%%
 init_box_X = 650;
 init_box_W = 120;

 init_box_Y = 500;
 init_box_H = 120;
 
%  init_box_X = 680;
%  init_box_W = 40;
% 
%  init_box_Y = 240;
%  init_box_H = 40;


box_X = init_box_X;
box_Y = init_box_Y;
box_W = init_box_W;
box_H = init_box_H;


%%%%%% PROCESSING LOOP %%%%%%%%%%%
loopCount = 0;
blobSize = 0;
occlusion_state = OcclusionStates.INIT;

%DEBUG: Some history holders
targetHistory = [];
filtPositions = [];
filtSizes = [];
error = [];

%Initialize the Kalman filters
TIME_COEFF = 0.1;
x_center = Kalman(TIME_COEFF, [0.1, 5, 0.1, 0.1], 1 );
y_center = Kalman(TIME_COEFF, [0.1, 5, 0.1, 0.1], 1 );

width_filter = Kalman(TIME_COEFF, [10, 1, 0, 0], 100);
height_filter = Kalman(TIME_COEFF, [10, 1, 0, 0], 100);

movedDist = 0;
errorCnt = 0;
missingCnt = 0;

BOUNDING_MULTIPLER = 1.1;
BOUNDING_MINIMUM = 0;

%Loop through all video
while hasFrame(video)                                                      
    thisFrame = readFrame(video);
    imshow(thisFrame, 'Parent', currAxes);
	
    %-------------  STEP 1  --------------
    % After we get started, first step is to use the Kalman filters to
    % predict location of the object
	if(occlusion_state ~= OcclusionStates.INIT)
		x_center = x_center.Predict();
        y_center = y_center.Predict();
		PredCenter = [y_center.GetPred(), x_center.GetPred()];
        
        width_filter = width_filter.Predict();
        height_filter = height_filter.Predict();
        %PredSize = [width_filter.GetPred(), height_filter.GetPred()];
        PredSize = [height_filter.GetPred(), width_filter.GetPred()];
        
        %TODO: Trade space includes changing this definition depending on
        %occlusion state
        box_W = round(BOUNDING_MULTIPLER*PredSize(1) + BOUNDING_MINIMUM );
        box_X = round(PredCenter(X_var) - box_W/2);
            
        box_H = round(BOUNDING_MULTIPLER*PredSize(2)+ BOUNDING_MINIMUM);
        box_Y = round(PredCenter(Y_var) - box_H/2);
    end
    
    
    %-------------  STEP 3  --------------
    % Grab the target subframe to be used for object detection
    screenSize = size(thisFrame);
	
	%This returns [Y, X, endY, endX];
    subBox = LimitToScreen(box_X, box_Y, box_W, box_H, screenSize(X_var), screenSize(Y_var));   %Screen size is reversed (height x width)
	subX = subBox(X_var);
	subW = subBox(X_var + 2) - subBox(X_var);
	subY = subBox(Y_var);
	subH = subBox(Y_var + 2) - subBox(Y_var);
    
    subFrame = thisFrame(subY:subY + subH, subX:subX+subW, 1:3);  %Dimensions are height x width
    preFrame = colorChop(subFrame, COLOR_CHOP_CUTOFF);  
    
    %-------------  STEP 4  --------------
    % See if our object is dead center.  We keep trying that for a some frames
    % if it isn't found before we jump to a re-searching the box.
    %
    % TODO: This is where problems can come in.  If we lose the ball (fully
    % occluded) and we do a full search, can latch onto crap.  
    %
    not_found = false;
    
    %Look in middle of bounding box first, assume correct if it hits
    Blobs = pointIsObject(preFrame, round(box_W/2), round(box_H/2));     
    if(Blobs.Empty)  %Didn't find blob at ideal spot
        Blobs = ConnectedLabel(preFrame, box_X, box_Y);
        if(~isempty(Blobs)) 
            target = GetClosestBlob(Blobs, PredCenter, PredSize, 20);   
            if(isempty(target))
                not_found = true;
            end
        else
            not_found = true;
        end
    else %Was only one blob in this case, so can just set target equal to it
        target = Blobs.ToScreenCoord(box_X, box_Y);   
        missingCnt = 0;
    end
    
    if(~not_found)
        target = target.MakeSquare();
        target = target.FindCenterOfMass_Simple();
    end
    

    %-------------  STEP 5  --------------
    % State update using blob detection results
    
    %TODO: Find center of mass was messing up in some shading situations,
    %but also MakeSquare is goofy if other object get in the detection frame
    if(occlusion_state ~= OcclusionStates.INIT)
        if(not_found)
            %if(missingCnt < OcclusionStates.MISSING_FRAMEOUT)  %TODO: Somewhat redundant with Step 4
            %    occlusion_state = OcclusionStates.MISSING;
            %else
                occlusion_state = OcclusionStates.FULL;
            %end            
        else
            missingCnt = 0;
            if(target.Width == target.adjWidth && target.Height == target.adjHeight)  %This checks that it was roughtly square
               occlusion_state = OcclusionStates.LOCKED;
            else
               occlusion_state = OcclusionStates.PARTIAL; 
            end
        end
    end
    

    occlusion_state
   
    %-------------  STEP 6  --------------
    % Update Kalman filter position
    x_center = x_center.SetMeasurementNoise(1);
    y_center = y_center.SetMeasurementNoise(1);
    
    if(occlusion_state == OcclusionStates.INIT)
        x_center  = x_center.InitState(target.adjCenter(X_var));  %Height first order to make the indexes work
        y_center  = y_center.InitState(target.adjCenter(Y_var));
        PredCenter = [y_center.GetPred(), x_center.GetPred()];
        
        width_filter = width_filter.InitState(target.adjWidth);
        height_filter = height_filter.InitState(target.adjHeight);
        PredSize = [width_filter.GetPred(), height_filter.GetPred()];

        occlusion_state = OcclusionStates.LOCKED; %TODO

    %Locked: update size and position fitlers with measurement
    elseif(occlusion_state == OcclusionStates.LOCKED)        
        x_center = x_center.Measure(target.adjCenter(X_var));
        y_center = y_center.Measure(target.adjCenter(Y_var));
        width_filter = width_filter.Measure(target.adjWidth);
        height_filter = height_filter.Measure(target.adjHeight);
    
    %Partial: update position w/ measurement, predict size forward
    elseif (occlusion_state == OcclusionStates.PARTIAL)
        x_center = x_center.SetMeasurementNoise(5);
        y_center = y_center.SetMeasurementNoise(5);
        
        x_center = x_center.Measure(target.adjCenter(X_var));  
        y_center = y_center.Measure(target.adjCenter(Y_var)); 
        
        width_filter = width_filter.NoMeasure();
        height_filter = height_filter.NoMeasure();

    %Full: predict both size and position forward
    elseif (occlusion_state == OcclusionStates.FULL)
        x_center = x_center.NoMeasure();
        y_center = y_center.NoMeasure();
        
        width_filter = width_filter.NoMeasure();
        height_filter = height_filter.NoMeasure();
    end
        

    %% DEBUG: Draw box around blob
    % X, Y, W, H
    %BLACK IS THE BOX WE ARE DOING ANALYSIS IN
    rectangle('Position',[subX,subY,subW,subH],'Edgecolor', 'black','LineWidth', 1);  
    
    %BLUE IS THE BLOB DETECTED BOX
    if(~isempty(target))
        X = target.adjTL(X_var);
        Y = target.adjTL(Y_var);
        W = target.adjWidth;
        H = target.adjHeight;
        rectangle('Position',[X,Y,W,H],'Edgecolor', 'blue');  
        
        rectangle('Position',[target.adjCenter(X_var),target.adjCenter(Y_var),5,5],'Edgecolor', 'green','LineWidth', 1);  
    end

    %RED IS THE KALMAN PREDICTED POSITION
    X = round(PredCenter(X_var));
    Y = round(PredCenter(Y_var));
    W = 5; %target.adjWidth;
    H = 5; %target.adjHeight;
    rectangle('Position',[X,Y,W,H],'Edgecolor', 'red');  

    targetHistory = [targetHistory;target];
    filtPositions = [filtPositions;PredCenter];
    filtSizes = [filtSizes;PredSize];
        
    %rectangle('Position',[PredCenter(X_var),PredCenter(Y_var),5,5],'Edgecolor', 'b','LineWidth', 1);  
    %%END DEBUG%%

    loopCount = loopCount + 1;   %Completed a loop so set to 0, doing here so can use in several places

    
    %%DEBUG - Look at sub window
    figure(2)
    imshow(preFrame);
    
    if(~isempty(target))  
        X = target.TL(X_var) - box_X;
        Y = target.TL(Y_var) - box_Y;
        W = target.Width;
        H = target.Height;
        rectangle('Position',[X,Y,W,H],'Edgecolor', 'red');  
        
        X = target.adjCenter(X_var) - box_X;
        Y = target.adjCenter(Y_var) - box_Y;
        W = 5;
        H = 5;
        rectangle('Position',[X,Y,W,H],'Edgecolor', 'blue'); 
    end
    
    X = box_W/2;
    Y = box_H/2;
    W = 5;
    H = 5;
    rectangle('Position',[X,Y,W,H],'Edgecolor', 'green');  
    
%     figure(3)
%     plot(filtSizes)
    
    figure(1)

    pause(0.1);
    
end %End of processing loop

figure(2)
plot(error);
avgError = mean(error)


    %END DEBUG    
  
%     for m = 1:size(Blobs)
%         X = Blobs(m).TL(X_var);
%         Y = Blobs(m).TL(Y_var);
%         W = Blobs(m).Width;
%         H = Blobs(m).Height;
%         rectangle('Position',[X,Y,W,H],'Edgecolor', 'green');    
%     end


%     elseif(occlusion_state == OcclusionStates.STATIC)
%         movedDist = Distance(target.adjCenter,prevPos);
%         Cfilt  = Cfilt.Measure(target.adjCenter(Y_var), target.adjCenter(X_var));   
%         
%         SizeFilt = SizeFilt.Measure(target.adjWidth, target.adjHeight);
%         
%         if(movedDist > 10)
%             occlusion_state = OcclusionStates.MOVING
%         end        
    
%     elseif(occlusion_state == OcclusionStates.MOVING)  %Use actual measurement
%         errorDist = Distance(target.adjCenter, PredCenter)
%         
%         if(errorDist < 10)
%             errorCnt = errorCnt + 1
%         end
%         
%         Cfilt = Cfilt.Measure(target.adjCenter(Y_var), target.adjCenter(X_var));   
%         SizeFilt = SizeFilt.Measure(target.adjWidth, target.adjHeight);
%         
%         if(errorCnt > 5)
%             occlusion_state = OcclusionStates.LOCKED
%         end
        

    %INVESTIGATE: Do we change filter parmaters based on occlusion state
    %(can adjust how fast it changes acceleration/velocity)
%     %%Set State Mode
%     if(occlusion_state == OcclusionStates.FULL || occlusion_state == OcclusionStates.MISSING)
%         Cfilt = Cfilt.SetA(1);
%     else
%         Cfilt = Cfilt.SetA(0);
%     end
    
