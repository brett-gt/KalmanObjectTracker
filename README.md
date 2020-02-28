# KalmanObjectTracker
Object tracker in video.  Uses Kalman filter to predict object position to handle occlusion and minimize computation time.

## Overview
My original desire was to create a ball tracker application for Apple products using their Vision Framework provided for modern iPhone/iPads (similar to the shot tracker or pitch cams seen on TV broadcast).  The application would process real time video, extract the path taken by a ball, and overlay it on top of real-time video.  Turns out in testing Apple's Vision Framework it was not very good at tracking objects through rapid acceleration or occlusion, both of which happened for my use case (a golf ball being hit or a pitcher releasing a pitch).

Instead, I started from scratch to try to develop the algorithms necessary to implement this application.  Initial testing has been performed on videos of golf putting, since that was one of the simpler cases.  


## TODO List:

1. Still need to perfect the algorithm implementation. One hanging issue is increasing the bounding box size greater than the Kalman filter size seems to throw off results.  I think this may be a coding error where there is some dependency on the bounding box size I am not seeing which is shifting my center point calculations.

2. Rehost back in to an iPhone. 


## Algorithms
Several algorithms and some glue logic/state management are required for the core object tracking:

1. Background Removal: To make the problem managable, background objects (not interesting) need to be seperated from foreground objects (things we might care about).  I did some limited exploration on using some background subtraction techniques (which work really well for moving objects), but currently I cheat.  Golf balls are pure white, so I simply convert the RGB image to a binary image using a threshold that removes anything that isn't mostly white from the image.  For the most part, this removes the background and many foreground objects I am not interested in.

2. Object detection: A method of detecting and identifying an object in a video.  The goal is to be able to draw a bounding box around that object.  Currently I am using a one component at a time Connected-Component Labeling (CCL) algorithm.  

3. Occlusion handling: In many instances, the objects being examined can be temporarily hidden from view (golf club, hand of a pitcher, person's body in the way).  To handle occlusion, objects position and size are tracked using Kalman filters.  When occlusion is detected, the Kalman filters are updated using only their internal states to predict the objects motion and changes in size.  These predictions help inform re-identifying the object when it does return to the frame.

4. Optimization: Searching over the entire video frame requires execessive computation.  Instead, the Kalman filters are used to predict where the object is at in each video frame.  The algorithms focus on this local area, allowing orders of magnitude less computation to be used.

