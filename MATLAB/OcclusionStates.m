classdef OcclusionStates
    
    properties (Constant)
        %MISSING_FRAMEOUT - number of frames we can go without finding
        %object in our Kalman filter defined area before we determine
        %Kalman filter is no longer tracking it (or it is fully occluded)
        MISSING_FRAMEOUT = 20;
    end
    
    
    enumeration
        %INIT - first run through, use pre-selected position to find
        %target.  Transition to LOCKED
        INIT, 
        
        %LOCKED - use adjusted target values to update both size and
        %position kalman filters.
        LOCKED,
        
        %PARTIAL - use adjusted target values to update position ONLY.  Let
        %Kalman filter predict the new size.
        PARTIAL,
        
        %MISSING - implemented as an intermediate step for when an object
        %is not found but before we assume it is fully occluded.
        % TODO: Doesn't currently serve a purpose
        MISSING,
        
        %FULL - let Kalman filter predict both new position and size.
        FULL,
        
        

        
         
        
    end
end