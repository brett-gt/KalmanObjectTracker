classdef Blob
    %   Blob Class - hold properties and methods associated with defining
    %   a blob (size, position, 
    %

   properties
      MinRow     % Smallest row (y) that contains a point of the blob
	  MaxRow     % Larget row (y) that contains a point of the blob
	  MinCol     % Smallest column (x) that contains a point of the blob
	  MaxCol     % Largest column (x) that contains a point of the blob
	  Points     % Array of the individual (x,y) points in the blob
      numPoints  % Total count of points in the blob
      sumX       % Sum of the column values, potentially used for center of mass calculations
      sumY       % Sum of the row values, potentially used for center of mass calculations
	  
	  TL         % Top left corner 
	  TR         % Top right corner
	  BL         % Bottom left corner
	  BR         % Bottom right corner
	  Center
      Width
      Height
      
      OffsetX    % Stores the offset that converts internal blob values to 
      OffsetY    % screen coordinates
      
      % The adjusted values attempt to account for partial occlusion
      adjTL      
      adjTR
      adjBL
      adjBR
      adjCenter
      adjWidth
      adjHeight
      
      Empty
   end
   
   methods
   
      %--------------------------------------------------------------------
      function obj = Blob()
         % Initializer - sets default values
         obj.MinRow = 100000;
		 obj.MaxRow = 0;
		 obj.MinCol = 100000;
		 obj.MaxCol = 0;
		 obj.Points = [];
         obj.Empty = 1;
         obj.numPoints = 0;
         obj.sumX = 0;
         obj.sumY = 0;
      end
      
      %--------------------------------------------------------------------
      function obj = AddPoint(obj, row_, col_)
        % Adds a point to the blob. Adjusts blob level values (min/max,
        % size, etc) as appropriate.
        
        % NOTE: Some parmaters will be in the space passed in by row_, col_
        % (screen space vs a subset).  Need to watch for issues here.
        obj.Empty = 0;
	    if(row_ < obj.MinRow)
			obj.MinRow = row_;
        end
        if(row_ > obj.MaxRow)
			obj.MaxRow = row_;
        end
		 
		if(col_ < obj.MinCol)
			obj.MinCol = col_;
        end
        if(col_ > obj.MaxCol)
			obj.MaxCol = col_;
        end
		
		%Add to list of points
        point = [row_, col_];
	    obj.Points = [obj.Points; point];
        
        obj.numPoints = obj.numPoints + 1;
        obj.sumX = obj.sumX + col_;
        obj.sumY = obj.sumY + row_;
      end
	  
      
      %--------------------------------------------------------------------
	  function obj = ToScreenCoord(obj, offsetX, offsetY)
        % Calculates/translates bounding parameters in screen space.
        % Should be called after blob is complete but before used.
          
        obj.OffsetX = offsetX;
        obj.OffsetY = offsetY;
        
		obj.TL = [obj.MinRow + offsetY, obj.MinCol + offsetX];
		obj.TR = [obj.MinRow + offsetY, obj.MaxCol + offsetX];
		obj.BR = [obj.MaxRow + offsetY, obj.MaxCol + offsetX];
		obj.BL = [obj.MaxRow + offsetY, obj.MinCol + offsetX];
		
		obj.Center = [(obj.MinRow + round((obj.MaxRow - obj.MinRow)/2)) + offsetY, ...
                      (obj.MinCol+ round((obj.MaxCol - obj.MinCol)/2)) + offsetX];
                  
        obj.Width = 1 + obj.MaxCol - obj.MinCol;  %Add one because if only one pixel in size
        obj.Height = 1 + obj.MaxRow - obj.MinRow;
      end
                 
      %--------------------------------------------------------------------
      function obj = MakeSquare(obj)
        %This function looks for the side most likely to be truth and 
        %extrapolates out the boundin box from there
        
        SQUARE_FACTOR = 0.1;
          
	    anchorSide = 0; % 0 = none, 1 = top, 2 = bottom, 3 = right, 4 = left
		
        %Algorithm
		% 1. Compare length and width to see if box is roughly square, if
		%    close assume see entire thing and nothing needs to be done.
		% 2. If not square, find longest dimension (length or width).  Will
		%    assume it is correct and make the other dimension the same.
        % 3. Now hard part: need to figure out where corners should be.  We
        %    arbitrarily extended a dimension but should that move left or
        %    right/up or down?
		% 4. Since object is circular, a top/bottom or left/right side
		%    should have only a few pixels.  So we will look for side with
		%    fewest pixels and assume it is an edge.
        % 5. Find the "hidden edge" by moving from the anchored edge by the
        %    guessed dimension size.  
        %
        % Remember screen coordinates have (0,0) at top left
        
        %If not square, use the 
        maxDim = max(obj.Width , obj.Height);	
        
        %If not square, we pick a side to anchor to
		if(abs(obj.Width - obj.Height) > SQUARE_FACTOR * maxDim)

            %Width is less than height, 
			if(obj.Width < obj.Height)
                obj.adjWidth = obj.Height;
                obj.adjHeight = obj.Height;
                				
                %If we have more pixels on a side, this is the occluded
                %side, so use the other side
                max_count = sum(obj.Points(:,1) == obj.MaxRow)
                min_count = sum(obj.Points(:,1) == obj.MinRow)
				if(max_count > min_count)
					anchorSide = 3;  %Min side is good (left)
				else
					anchorSide = 4;
                end
                
            else
                obj.adjWidth = obj.Width;
                obj.adjHeight = obj.Width;

                max_count = sum(obj.Points(:,2) == obj.MaxCol)
                min_count = sum(obj.Points(:,2) == obj.MinCol)
				if(max_count > min_count)
					anchorSide = 1;   %Min smallest, anchor to top
				else
					anchorSide = 2;   %Max smallest, anchor to bottom
				end	
			end
        end

        obj.adjTL = obj.TL;
        obj.adjTR = obj.TR;
        obj.adjBL = obj.BL;
        obj.adjBR = obj.BR;
        
        %TODO: Have to adjust these so add width/height to only one
        %variable
        %Remember, top right corner is 0,0 of image
        switch(anchorSide)
            case 1  %Top - create a new bottom 
                obj.adjBL(1) = obj.adjTL(1) + obj.adjHeight;
                obj.adjBR(1) = obj.adjTR(1) + obj.adjHeight;
                obj.adjCenter = [(obj.TL(1) + round(obj.adjHeight/2)), ...
                                 (obj.TL(2) + round(obj.adjHeight/2))];
                
            case 2  %Bottom - create a new top
                obj.adjTL(1) = obj.adjBL(1) - obj.adjHeight;
                obj.adjTR(1) = obj.adjBR(1) - obj.adjHeight;
                obj.adjCenter = [(obj.BR(1) - round(obj.adjHeight/2)), ...
                                 (obj.BR(2) - round(obj.adjHeight/2))];   
                             
            case 3  %Right - create a new left
                obj.adjTL(2) = obj.adjTR(2) - obj.adjWidth;
                obj.adjBL(2) = obj.adjBR(2) - obj.adjWidth;
                obj.adjCenter = [(obj.adjBR(1) - round(obj.adjWidth/2)), ...
                                 (obj.adjBR(2) - round(obj.adjWidth/2))];  
                             
            case 4  %Left - create a new right
                obj.adjTR(2) = obj.adjTL(2) + obj.adjWidth;
                obj.adjBR(2) = obj.adjBL(2) + obj.adjWidth;
                obj.adjCenter = [(obj.adjTL(1) + round(obj.adjWidth/2)), ...
                                 (obj.adjTL(2) + round(obj.adjWidth/2))];
                             
            otherwise %Already square - don't do anything
                obj.adjCenter = obj.Center;
                obj.adjWidth = obj.Width;
                obj.adjHeight = obj.Height;
        end
      end
	  
      %--------------------------------------------------------------------
      function obj = FindCenterOfMass_Simple(obj)
        % Calculate center of mass pased on average X, Y value
        obj.adjCenter = [obj.OffsetY + round(obj.sumY/obj.numPoints), ... 
                         obj.OffsetX + round(obj.sumX/obj.numPoints)];
      end
      
      %--------------------------------------------------------------------
      function obj = FindCenterOfMass_Complex(obj)
        % Purpose is to be more accurate in occlusion cases.  Puts the 
        % center of mass at the center of the longest line.  
        % Problem I am seeing with it is if mutliple blobs run together this 
        % can really skew the center point
		firstCol = obj.Points(:,1);
		uniqFirstCol = unique(firstCol);
		
		edges = [];
		[M, N] = size(obj.Points);
		
		for i = 1:length(uniqFirstCol)
			min = 100000;
			max = 0;
			
			for j = 1:M
				point = obj.Points(j,:);
				if(point(1) == uniqFirstCol(i))
					if(point(2) < min)
						min = point(2);
					end
					if(point(2) > max)
						max = point(2);
					end
                end
            end
            edges = [edges;[uniqFirstCol(i), min];[uniqFirstCol(i), max]];
		end
		
		longA = obj.Points(1,:);
        longB = obj.Points(1,:);
		distance = 0;
        
		for i = 1:length(edges)
			edgeA = edges(i,:);
			for j = i+1:length(edges)
				edgeB = edges(j,:);
				temp = sqrt((edgeA(1) - edgeB(1))^2 + (edgeA(2) - edgeB(2))^2);
				if(temp > distance)
					longA = edgeA;
                    longB = edgeB; 
					distance = temp;
				end
			end
        end
        
        angle = atan2(longB(1) - longA(1), longB(2) - longA(2));
 
        obj.adjCenter = [obj.OffsetY + longA(1) + (sin(angle)*distance)/2,...
                         obj.OffsetX + longA(2) + (cos(angle)*distance)/2];
	  end
	  
      
%       function r = getCorners(obj, offsetX, offsetY) 
%          r = [[obj.MinRow + offsetY, obj.MinCol + offsetX]; ...
%               [obj.MinRow + offsetY, obj.MaxCol + offsetX]; ...
%               [obj.MaxRow + offsetY, obj.MinCol + offsetX]; ...
%               [obj.MaxRow + offsetY, obj.MaxCol + offsetX]];
%       end
      
      function r = getCenter(obj, offsetX, offsetY)
         r = [(obj.MinRow + round((obj.MaxRow - obj.MinRow)/2)) + offsetY, ...
              (obj.MinCol+ round((obj.MaxCol - obj.MinCol)/2)) + offsetX];
          
      end
      
      function r = getArea(obj)
          r = (obj.MaxRow - obj.MinRow) * (obj.MaxCol - obj.MinCol);
      end
	  
	  function r = getRatio(obj)
		if(obj.MaxCol - obj.MinCol ~= 0)
			r = (obj.MaxRow - obj.MinRow) / (obj.MaxCol - obj.MinCol);
		else
		    r = 0;
		end
	  end
	  

   end
end