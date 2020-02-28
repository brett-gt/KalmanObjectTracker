classdef Kalman
    % Kalman filter implementation
    %   Allows creation of a constant velocity, accel, or jerk Kalman
    %   filter.  DoF are dependent on which Q_coef values are non-zero.
    %
    %   Currently not very dynamic of an implementation.  
    %
    %   Refrenced used can be found at the bottom of the file.

   properties
	  dT             %Delta time
      A              %State update matrix   
	  H              %Observation update matrix
	  Q              %Process noise
	  R              %Measurement noise
	  P              %Error covariance
 
	  Xk             %Current state
      Xp             %Filter prediction
      K              %Filter gain
      PP
   end
   
   methods
   
	  %--------------------------------------------------------------------
      function obj = Kalman(T_, Q_coef, R_coef)
		% Constructor for the Kalman filter.  
        %
        % Arguments
        %   T_ is the rate at which filter will be executed.
        %   Q_coef is an array of process noise coefficients.  The DoF of
        %       the model are derived from what Q values are non-zero.
        %   R_coef is the measurement noise (assumed only one input so this
        %       is a scalar value
         
        %TODO: Should be able to re-use SetA for this but was having
        %      error trying to do that.
        obj.dT = T_;
        T = T_;
        if Q_coef(2) == 0
            T = 0;
        end
		
        Tsq = (T_*T_)/2;
        if Q_coef(3) == 0 
            Tsq = 0;
        end
        
        Tcu = (T_*T_*T_)/6;
        if Q_coef(4) == 0 
            Tcu = 0;
        end
        
		obj.A = [1   T   Tsq  Tcu ;
			     0   1   T    Tsq ;
			     0   0   1    T   ;
			     0   0   0    1   ]; 
             
		%Measurement Update Matrix (m x n matrix)
		obj.H = [1 0 0 0];
  
        % Process noise matrix
        obj.Q = [Q_coef(1)   0         0         0  ;          %Bigger number here = slower to runaway
		         0           Q_coef(2) 0         0  ; 
		         0           0         Q_coef(3) 0  ;
                 0           0         0         Q_coef(4) ] * 1; 
             
		% Measurement noise matrix
		obj.R = [R_coef] * 1;                        
		
        % Error covariance matrix
		obj.P = eye(4);                         
		      
			     %pos  vel   acc  jerk 
		obj.Xk = [0    0     0    0    ]';
        
      end
      

      %--------------------------------------------------------------------
	  function obj = InitState(obj, x_)		
         % Intention is for this to be used while the object is stationary
         % and as it begins to move. Use this for a few frames after it begins
         % to move to get the velocity and acceleration good prior to letting 
         % the filter run with error calculations.     
          
         obj.Xk = [x_ 0 0 0]';
         
         obj.Xp = obj.A * obj.Xk;
      end
      
      %--------------------------------------------------------------------
      %TODO: Function to dynamically change the A matrix.  Should be able
      %      to call it from constructor too... but kept getting strange 
      %      'requires Model-Based Calibration Toolbox error when I tried
      %      that
      %--------------------------------------------------------------------
      function obj = SetA(obj, Q_coef)
        T = obj.dT;
        if Q_coef(2) == 0
            T = 0;
        end
		
        Tsq = (obj.dT*obj.dT)/2;
        if Q_coef(3) == 0 
            Tsq = 0;
        end
        
        Tcu = (obj.dT*obj.dT*obj.dT)/6;
        if Q_coef(4) == 0 
            Tcu = 0;
        end
        
		obj.A = [1   T   Tsq  Tcu ;
			     0   1   T    Tsq ;
			     0   0   1    T   ;
			     0   0   0    1   ]; 
             
        % Process noise matrix
        obj.Q = [Q_coef(1)   0         0         0  ;          %Bigger number here = slower to runaway
		         0           Q_coef(2) 0         0  ; 
		         0           0         Q_coef(3) 0  ;
                 0           0         0         Q_coef(4) ] * 1; 
      end
             
	  
      %--------------------------------------------------------------------
      function obj = Predict(obj)
         % Predicts the next Kalman filter state
         
         % Predict the state ahead (Ref 2: EQ 1.9)
		 obj.Xp = obj.A * obj.Xk;
		 
		 % Predict error covariance matrix (Ref 2: EQ 1.10)
		 obj.PP = obj.A * obj.P * obj.A' + obj.Q;   
		 
		 % measurement update (correct)
		 % Find the Kalman gain (Ref 2: EQ 1.8)
		 obj.K = obj.PP * obj.H' * inv(obj.H * obj.PP * obj.H' + obj.R);        
      end
      
      %--------------------------------------------------------------------
      function obj = NoMeasure(obj)
         % Update the Kalman filter state without a measurement.
         % Originally was just doing: obj.Xp = obj.A * obj.Xp;
          
		 % Sub in prediction as if it were a measurement
		 z=[obj.Xp(1)];
		 
		 % Apply the correction to the predicted data (Ref 2: EQ 1.7)
		 obj.Xk = obj.Xp + obj.K * (z - obj.H * obj.Xp);
		 %               innovation - difference between measurement and predicted measurement
		 
		 % No update to the covariance matrix, didn't make a measurement
         obj.P = zeros(4);       
      end
      
      %--------------------------------------------------------------------
      function obj = Measure(obj, x_)
         % Update the Kalman filter with a new measurement
         
		 % make the z measurement matrix from true data
		 z = [x_];
		 
		 % Updated state estimation: Apply the correction to the predicted data (Ref 2: EQ 1.7)
		 obj.Xk = obj.Xp + obj.K * (z - obj.H * obj.Xp);
		 %               innovation - difference between measurement and predicted measurement
		 
		 % Update estimate covariance: and update the error covariance (Ref 2: EQ 1.13)
		 obj.P = (eye(4) - obj.K * obj.H) * obj.PP;     
      end
      
      %--------------------------------------------------------------------
      function obj = SetMeasurementNoise(obj, R_coef)
          %Used to dynamically change the measurement noise (R)
          obj.R = R_coef * 1; 
      end
      
      %--------------------------------------------------------------------
      function pos = GetPos(obj)
          pos = obj.Xk(1); % Return the filtered value
      end
      
     %--------------------------------------------------------------------
      function pos = GetPred(obj)
          pos = obj.Xp(1); % Return the predicted value
      end
	  
   end
end

% Refrences
% Ref 1: https://www.cs.cmu.edu/~motionplanning/papers/sbp_papers/kalman/video_kalman.pdf
% Ref 2: http://www.cs.unc.edu/~welch/media/pdf/kalman_intro.pdf
% Ref 3: Adaptive Adjustment of Noise Covariance in Kalman Filter for
% Dynamic State Estimation (https://arxiv.org/abs/1702.00884)