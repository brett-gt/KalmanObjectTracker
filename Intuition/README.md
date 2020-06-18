# Overview

This [article](https://www.bzarg.com/p/how-a-kalman-filter-works-in-pictures/) and associated video gives a good overview on how a Kalman filter works.

To maximize performance of the Kalman filter, there are several parameters that can be tuned.  This post documents tuning performed to first develop an intuition about tuning a Kalman filter and then to specificly tune to the object tracking use cast I am appliyng it to.


# General Intuition

## System Transition Matrix
The state transition matrix (usually denoted as "A" or "Fk" in literature) describes the dynamics of the system.  Applied to modeling motion, the state transition matrix encodes the kinematic equations that describe an object's motion.  Typically, one of two options are used: constant velocity or constant acceleration.

## Process Noise
Process noise describes uncertainty associated with the state model.  Uncertainty in the state model could be due changes in the system over time, unknown state variables not included in the model, and outside influences that aren't incorporated in the model.  

To get a feel for the impacts of process noise, lets apply the Kalman filter to a ramp function.  The function used increases at a rate of 100 units/second (for object tracking this would be an object moving across the screen at 100 pixels/second). In each of the following graphs, there are three positions.  The top is position (blue being truth and green being Kalman prediction), the middle is error (difference between our Kalman prediction and truth), and the bottom is velocity (blue being truth and green being Kalman prediction).  

In the first case, we use process noise Q = [1 0][0 1].  The result is shown below:
![Ramp 1 1](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Process_Noise_1_1.JPG)

If you only looked at position, it looks like the Kalman filter starts off lagging truth by one time step and is slowly catching up.  Digging in further we can look at the bottom graph and see the issue: the Kalman filter is very slowly learning the velocity.  Now think back to the process noise values we are using.  We are setting the position noise and velocity noise to 1 (a relatively small value considering we move from 0 - 200 in a few seconds). By setting the noise low, we are telling the Kalman filter to trust the model values they have which means don't change your mind (i.e. learn) very fast.  

Lets try increasing the velocity noise such that Q = [1 0][0 10].  The result is shown below:
![Ramp 1 10](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Process_Noise_1_10.JPG)]

Compared with the previous value, both error and velocity are converging to their expected value much faster.  By telling the Kalman filter that there is a lot of noise with the velocity part of the model, we tell it to trust new measurements faster and therefore learn the true velocity quicker.  

If we go even more extreme, we can set the velocity noise such that Q = [1 0][0 100].  The result is shown below:
![Ramp 1 100](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Process_Noise_1_100.JPG)]

As expected, both error and velocity converge even faster.  



                                            




# TODO:
Clean up formulas
