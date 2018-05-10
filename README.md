
InfoVis WsprGlobe

This is a project for an Information Visualization class. The students 
were given the option to visualize a public data set using a standard tool 
like Tableau, Excel, Plotly, etc. or a library like D3.js or Highcharts, or 
to program from scratch a visualization in a lower-level fashion. Since I 
like punishment and graphics that look like they are straight out of 1992, 
I chose the hard way, using Processing.org and primitives like "line", "rect", 
"sphere".  While easier than straight C, this still took a significant amount 
of time and debugging, and I am sure I would not recommend this approach at 
this point - there are so many more interesting things that could have been 
done while I was trying to get a Great Circle mid-point calculation to work.

But it was fun. And as of 2018-05-08 it is done, so don't expect any updates 
but if you can build on this work while acknowledging sources, have at.

Data used is 1 month of observations from [wsprnet.org](http://wsprnet.org/drupal/). [WSPR](https://physics.princeton.edu/pulsar/k1jt/wspr.html) is just one of Joe Taylor K1JT's many [fascinating projects](https://physics.princeton.edu/pulsar/k1jt/index.html).  There are scripts to load PostgreSQL directly from wspr.org, 
and to batch the data into a useful indexed format.

My project uses PostgreSQL for data storage, manipulation and indexing, 
BezierSQLib provides the interface from Processing to PostgreSQL,
and I couldn't have done it without studying "RotatingArcs" demo by Marius Watz. 

Additionally, data from NaturalEarthData.com converted with geoconverter.hsr.ch
is used to make Earth's coastlines visible.

Earth image is from the "Texture Sphere" demo from Processing.org.

Project [slide presentation](https://drive.google.com/open?id=1DpR6Kd-o3gusWcLmGyRGH8EfK-am7TrypX_Tpqof7zQ)

![screenshot 1](/screenshot1.png?raw=true "Screenshot 1")

Video overview: 
[![video overview](https://img.youtube.com/vi/1hfoWJgqQ-4/0.jpg)](https://www.youtube.com/watch?v=1hfoWJgqQ-4)

