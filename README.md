
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

But it was fun. 

My data is 1 month of observations from wsprnet.org. WSPR by Joe Taylor K1JT
is a fascinating project in its own right - go read about it. 

My project uses PostgreSQL for data storage, manipulation and indexing, 
BezierSQLib provides the interface from Processing to PostgreSQL,
and I couldn't have done it without studying "RotatingArcs" demo by Marius Watz. 

Additionally, data from NaturalEarthData.com converted with geoconverter.hsr.ch
is used to make Earth's coastlines visible.

Earth image is from the "Texture Sphere" demo from Processing.org.

![screenshot 1](/screenshot1.png?raw=true "Screensot 1")

