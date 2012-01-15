Welcome to the Multi-Angle Mie Sizing project.

These Matlab routines are an important part of an optical droplet measurement system based on planar multi-angle Mie scattering.  Sizing information consists of a mean droplet diameter and droplet distribution estimates for every individual point within a planar area of interest.  The planar method makes possible the fast acquisition of data within a large field of interest, and uses relatively inexpensive instrumentation. 

Currently, the method has demonstrated the ability to measure water droplets from a typical simplex spray nozzle, across the range of 5-50$\mu$m within +/-10\% of known values, and in addition return an estimate of the shape and width of the size distribution at each location within the planar region of interest.  Measurements were successfully completed for three separate flow rate spray nozzles; 1-gallon-per-hour, 2.5-gallon-per-hour, and 4.5-gallon-per-hour.

Additionally the limits of the technique have been explored with simulated data.  Conclusions from these exercises show that the multi-angle planar Mie scatter method is capable of measuring droplet distribution characteristics and means within a nominal range of 0.3$\mu$m up to 150$\mu$m.

I am not a programmer, but I wrote these Matlab routines as part of my phd project; suggestions and improvements are welcome.
----------------
VERSIONS and BRANCHES
-- Databases:  I will keep a copy of any databases I generate updated in the download section.  

-- Master: This is the Repo; there may be many other branches but Master should contain the latest working version of everything, EXCEPT you must download the scattering coeffcient database files separately and unzip them into the ./multi_angle_mie_sizing/databases directory.

-- Version 1 - Tag: dissertation

The Repo TAG "dissertation" should take you back to the dissertation version of all the routines.  But the simplest way to get started is just download the package.  All the files referenced within the dissertation are contained within multi-angle-mie-sizing_v1.tar.bz2.  These will not change or be updated.  This will maintain consistancy with the original dissertation document.  This package is available in the download section.  Put this file to it's own directory and run:

tar -jxf multi-angle-mie-sizing_v1.tar.bz2

Additional installation instructions are found within the incldued README.install.

DOCUMENTATION

Documentation currently consists of reading my dissertation - sorry about that.  But there is a complete HOWTO step-by-step example in the Appendix.  My recomenndation is to download the Version 1 package and install it as suggested.  Get my dissertation from http://www.lib.vt.edu/.  Read it, go through the example in the appendix.  At that point you will have the basic idea about things and can move on to the latest version and features.

The latest version(s) in the Repo are probably going to be undocumented other than comments in the code, so having the original version as a starting point should help.  If you want to grab the Repo and modify things, feel free to contact me so I can explain what is going on, and we can work together constructively. 


Thanks for you iterest.
Stephen LePera
Virginia Tech, 2012