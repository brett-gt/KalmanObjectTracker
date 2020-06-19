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

So why wouldn't we just set Q as high as possible?  Noise.  The above example is free of noise.  What happens if we add noise?

Starting back with Q = [1 0][0 1] and plotting only position to get a better view (blue is true function, red is noise added):
![Ramp Noise 1 1](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Process_Noise_1_1_w_noise.JPG)]

For something called a Kalman "filter" we aren't getting much filtering of the noise.  We don't quite hit the peaks of the noise, but it clearly follows the noise.  What impact does increasing the velocity noise coefficient have?  Let us go back and try Q = [1 0][0 100]:
![Ramp Noise 1 100](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Process_Noise_1_100_w_noise.JPG)]

Slightly worse, but not much different.  We told the Kalman filter not to trust our internal state velocity as much, so it picks up velocity from the noise and hits peak noise slightly more.

What do we do?  What if we told the Kalman filter to trust our models position more?  We can do this by decreasing the position noise in the state matrix.  Trying Q = [0.1 0][0 1]:

![Ramp Noise p1 1](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Process_Noise_p1_1_w_noise.JPG)]

We can see notable filtering.  The noise still has an impact, but the effects are visibily muted.  Lets crank the velocity noise back up to make sure nothing bad happens.  Trying Q = [0.1 0][0 100]:

![Ramp Noise p1 100](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Process_Noise_p1_1_w_noise.JPG)]

Ouch... seems like we are back to where we started, not a whole lot of filtering going on.  The problem is that now the model is picking up on the velocity of the noise more and using it to predict the model position.  So even though we are trusting the model prediction more, the model prediction is now following the noise more closely.

### Intuition

What is going on?  The process noise tells the Kalman filter how much to trust the internal model versus new measurements.  We have a noise associated with each physical term we are modeling (position, velocity, acceleration if we were using it) that can be tweaked individually.

In the first set of experminents, we were trying to detect a change in velocity (underlying system state) as fast as possible.  If the process noise for velocity is set low, our model trust the velocity it already has more.  Because of this it is slow to learn the new velocity, which makes the Kalman filter predictions lag truth for an extended period of time.  Adding a lot of process noise for velocity causes the Kalman filter to trust its model velocity less, leading it to learn new velocity infromation faster.  

For detecting changes in the underlying system state, the position noise value does not matter as much.  Sure, we could set the position noise really high, which would minimize error because the Kalman filter would trust the measurements much more than its own position prediction, but the velocity prediction would still be off.  Also keep in mind, we haven't messed with measurement noise yet!

When we add noise, we want to Kalman filter to trust its state model more because this is what leads to filtering.  Now, position noise does matter more.  A high position noise in the process noise matrix tells the Kalman filter not to trust the  model, causing the Kalman filter to latch on and follow the noise.  Instead, we want a lower position noise value so that the Kalman filter trusts our model more than individual measurements.  However, if we set the velocity noise in the process noise matrix to high the Kalman filter state model starts following the noise.


## Varying State in the Kalman Filter

We can break our specific application down into a few distinct stages: acquisiton and following.

For acquisition, it makes sense to have increased noise in the process noise matrix.  After all, we don't need to model predictions yet because we haven't even found the object we want to model.  The increased noise allows the model to quickly learn the dynamics of the object once we do find it.  

For following, we want to decrease the noise in the process noise matrix.  Once we have matched the dynamics of the object, we want to trust our model in case the object becomes occluded.  

We may even consider a third state for what to do when we detect full or partial occlusion.


                   




# TODO:
Clean up formulas
