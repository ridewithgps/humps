Humps
=====
Humps takes all the difficulty out of working with DEM files.

Humps expects your file to be a GridFloat, which is a simple binary grid of elevation values in row major order.  Looking up a specific elevation value is simple when you know the grid size of each file.

This library is in use at [ridewithgps](http://ridewithgps.com) and is tailored towards our elevation datasets.  Meaning, there are a bunch of hardcoded things in here that may or may not apply to you.  At some point that stuff will all be extracted out or made generic, but that day is not today.
