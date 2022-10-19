# scad-lib-hirthjoints
An OpenSCAD library to generate Hirth joints. Flat or conical.  

## Details

usage: put this library in one of the standard locations:  
http://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Libraries  
e.g. Linux: $HOME/.local/share/OpenSCAD/libraries  

use <lib-hirthjoints.scad> or  
use <scad-lib-cyclogearprofiles/lib-hirthjoints.scad>  
depending on location  

```
hirth
  ( n = 12
  , r = 24
  , zbase = 8
  , slant = 60 
  , a1up = 10
  , a1down = 12
  , cuttype = "cylindrical"
  , dbore = 12
  , acone = 0
  )
```

## Usage tipps

- Always keep down_angle bigger than up_angle or the roofs will hit the valleys.
- If you use ist as a cutter then increase r and decrease dbore compared to the counterpart such that the teeth will fit radially.
- For printing a hirth interface at the bottom of a FFF-3D-print one can avert the need for support material by cutting off half of the teeth. This still meshes with full teeth but not with cutoff teeth.

## Demos

![Demo of a range of hirth joints that can be generated](demogrid-square--Screenshot_20221019_105427.png)
![Demo of a 12 tooth hirth joint](demo-square--Screenshot_20221019_111236.png)

## Notes:

This is the third and so far most performant attempt.
It uses convex hulls to span volumes.

I found that the crux for hirth joints is to 
***operate in spherical rahther than in cylindrical coordinates***

## History of preceding attempts versions

Elegant but inefficient & buggy (attempt two):
Intersections of approximated halfspaces
https://www.thingiverse.com/thing:397553

Earliest (attempt one):
Vertices and meshing:
https://www.thingiverse.com/thing:387292
