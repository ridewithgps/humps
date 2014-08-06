Humps
=====
Humps takes all the difficulty out of working with DEM files.

Humps expects your DEMs to be GridFloat, which is a simple binary grid of elevation values in row major order (x,y origin is upper left).  Looking up a specific elevation value is simple when you know the cellsize, number of cells and min lat/lng of each file.

This library is in use at [ridewithgps](http://ridewithgps.com) and is tailored towards our elevation datasets.  Meaning, there are a bunch of hardcoded things in here that may or may not apply to your elevation dataset. For example, we just updated our SRTM dataset and the number of rows/columns in each tile changed, necessitating the change of some hardcoded values used to lookup header files.  At some point that stuff will all be extracted out or made generic, but that day is not today.
