
function result = colorChop(frame, cutoff)
% colorChop
%   Goal of the function is to convert the RGB image into a binary image
%   (pure black/white) where our desired object and as little else is
%   white.  Will run object detection algorithm on the result to identify
%   and frame our specific object.
%
%   Since we are targetting a golf ball (already white object), the current
%   implementation is a simple pass/fail for white objects where everything
%   else is set to black.
%
%   TODO: Current implementation uses a single cutoff applied equally to
%   R,G,B.  Possible better results if used unique cutoffs for each color.
%
%   Arguments
%       frame - frame to act on
%       cutoff - cutoff value, objects below cutoff are "white", above are
%       "black"
   

    [rows, cols, colors] = size(frame);
    temp = zeros(rows,cols); %,'uint8');
    
    for i = 1:rows
       for j = 1:cols         
          if( (frame(i,j,1) < cutoff) || ...
              (frame(i,j,2) < cutoff) || ...
              (frame(i,j,3) < cutoff))
                  frame(i,j,1) =0;
                  frame(i,j,2) =0;
                  frame(i,j,3) =0;
                  temp(i,j) = 0;
          else
              temp(i,j) = 1; %max(frame(i,j,:));   
          end
          
       end
    end
    
    result = temp;
end