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

![Ramp Noise p1 100](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Process_Noise_p1_100_w_noise.JPG)]

Ouch... seems like we are back to where we started, not a whole lot of filtering going on.  The problem is that now the model is picking up on the velocity of the noise more and using it to predict the model position.  So even though we are trusting the model prediction more, the model prediction is now following the noise more closely.

### Intuition

What is going on?  The process noise tells the Kalman filter how much to trust the internal model versus new measurements.  We have a noise associated with each physical term we are modeling (position, velocity, acceleration if we were using it) that can be tweaked individually.

In the first set of experminents, we were trying to detect a change in velocity (underlying system state) as fast as possible.  If the process noise for velocity is set low, our model trust the velocity it already has more.  Because of this it is slow to learn the new velocity, which makes the Kalman filter predictions lag truth for an extended period of time.  Adding a lot of process noise for velocity causes the Kalman filter to trust its model velocity less, leading it to learn new velocity infromation faster.  

For detecting changes in the underlying system state, the position noise value does not matter as much.  Sure, we could set the position noise really high, which would minimize error because the Kalman filter would trust the measurements much more than its own position prediction, but the velocity prediction would still be off.  Also keep in mind, we haven't messed with measurement noise yet!

When we add noise, we want to Kalman filter to trust its state model more because this is what leads to filtering.  Now, position noise does matter more.  A high position noise in the process noise matrix tells the Kalman filter not to trust the  model, causing the Kalman filter to latch on and follow the noise.  Instead, we want a lower position noise value so that the Kalman filter trusts our model more than individual measurements.  However, if we set the velocity noise in the process noise matrix to high the Kalman filter state model starts following the noise.


## Measurement Noise
The other parameter we can vary is measurement noise (R).  Typically, this value is known or estimatable prior to implementation.  For example, if we were implementing a guidance system we would know the accuracy and drift associates with GPS, intertial sensors, accelerometers.  Without the presence of noise, measurement noise does not have that much effect.  Below is a capture of Q = [1 0][0 100] with R = [1] (same as a previous example) and then the same Q with R = [100].

![Meas Noise 1](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Meas_Noise_1.JPG)]

![Meas Noise 100](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Meas_Noise_100.JPG)]

You can see in the case of increased measurement noise that we are stretching back out the time it takes to learn the velocity.  By increasing measurement noise, we are telling the Kalman filter to trust the measurements less leading it to learn the state slower.  


## Occlusion

For the object tracking application, our primary interest in an accurate state model is in the case that we lose sight of the tracked object for a period of time.  In this case, we want to use the Kalman filter to predict where the object will be when it reappears.  Another application for object tracking is for tagging multiple objects that interesect each other.  We can use the Kalman filter predictiosn to maintain the tagging through the intersection.  The way accomplish this by allowing Kalman filter to continue making predictions and then use those predicitons as if they were measurements (allowing the filter to keep propograting into the future).

A few captures with Q = [1 0][0 100] and R = [1].  In these captures, occlusion starts at time 2 and goes until time 3.  

![Occlusion Down](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Occlusion_Down.jpg)]

![Occlusion Up](https://github.com/brett-gt/KalmanObjectTracker/blob/master/Intuition/Images/Occlusion_Up.jpg)]

What do we notice?  The first thing is that at that when occlusion starts, the noise goes away in the prediction.  This makes sense, because the Kalman filter is simply using its guess at velocity to propograte position into the future.  

The second thing is that in one capture our prediction undershoots truth and on the other capture our prediction overshoots truth.  Why is that?  Look at how noise was impacting velocity in the two captures.  In the undershoot case, the noise was causing truth to seem to "decrease" right before time 2 when occlusion started.  In the overshoot case, the noise was causing truth to seem to "increase" right before time 2 when occlusion started.  Since we have the velocity noise in our state model set high, the Kalman filter trusts the last measurement it saw before occlusion more than it should.  Since there was noise on that measurement, the noise affected our ability to accurately predict into the future.  Since the noise is random, we can't predict exactly what affect it might have.  


## Varying State in the Kalman Filter

We can break our specific application down into a few distinct stages: acquisiton and following.

For acquisition, it makes sense to have increased noise in the process noise matrix.  After all, we don't need to model predictions yet because we haven't even found the object we want to model.  The increased noise allows the model to quickly learn the dynamics of the object once we do find it.  

For following, we want to decrease the noise in the process noise matrix.  Once we have matched the dynamics of the object, we want to trust our model in case the object becomes occluded.  

We may even consider a third state for what to do when we detect full or partial occlusion.


                   




# TODO:
Clean up formulas
