# Overview

This [article](https://www.bzarg.com/p/how-a-kalman-filter-works-in-pictures/) and associated video gives a good overview on how a Kalman filter works.

To maximize performance of the Kalman filter, there are several parameters that can be tuned.  This post documents tuning performed to first develop an intuition about tuning a Kalman filter and then to specificly tune to the object tracking use cast I am appliyng it to.


# General Intuition

## System Transition Matrix
The state transition matrix (usually denoted as "A" or "Fk" in literature) describes the dynamics of the system.  Applied to modeling motion, the state transition matrix encodes the kinematic equations that describe an object's motion.  Typically, one of two options are used: constant velocity or constant acceleration.



TODO:
Clean up formulas