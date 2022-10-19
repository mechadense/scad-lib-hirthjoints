/*
Author: Lukas M. Süss aka mechadense
License: LGPL-3.0
Description: A minimal function for generation of hirth joints.

This is more meant as a library.
Deliberately kept minimal.

Customizer is just meant as a quick preview of what can be done.
Note that there is no math for sanity checking of supplied parameters.

## Usage tipps:

```
use <lib-hirthjoints.scad>
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

- Always keep down_angle bigger than up_angle or the roofs will hit the valleys.
- If you use ist as a cutter then increase r and decrease dbore compared to the counterpart such that the teeth will fit radially.
- For printing a hirth interface at the bottom of a FFF-3D-print one can avert the need for support material by cutting off half of the teeth. This still meshes with full teeth but not with cutoff teeth.

## Notes:

This is the third and so far most performant attempt.
It uses convex hulls to span volumes.

I found that the crux for hirth joints is to 
***operate in spherical rather than in cylindrical coordinates***

## History of preceding attempts:

Elegant but inefficient & buggy (attempt two):
Intersections of approximated halfspaces
https://www.thingiverse.com/thing:397553

Earliest (attempt one):
Vertices and meshing:
https://www.thingiverse.com/thing:387292
*/


// TODO:  add more vertical height in demos
// Publish on thingiverse and github
// import into bearing model and continue



// ##################################
// ##################################
// https://customizer.makerbot.com/docs
// Customizer

/* [Global] */

// number of hirth teeth (>=2)
toot_number = 12;
// radius … use a bit bigger radius for cutters
r0 = 24;
// vertical distance from hirths center-point to bottom of support
z_base =12;
// slant angle of the hirth teeth
slant_angle = 60;
// rotation angle upwards (roughly correspods to tooth height)
up_angle = 10;
// rotation angle downwards (roughly correspods to tooth depth)
down_angle = 12;
// spherical is most natural choice but slowest
type_of_cutoff = "cylindrical"; //["cylindrical","spherical","none"]
// hole diameter (0 means no more)
hole_diameter = 12;
// if not 0 then the complementariy interface needs the same cone angle but negative 
cone_angle = 0;

/* [Hidden] */

//Resolution
// minimal angle per "circle edge" 
$fa = 2;
// minimal length per "circle edge"
$fs = 0.4;

// colors
cylcol = [0.9,0.9,0.9];
basecolor = "cyan";


// ##################################


customizer_demo();
//demoarray();

module customizer_demo()
{
hirth
  ( n = toot_number // >=2
  , r = r0 // use a bit bigger r for cutters
  , zbase = z_base // bottom depth of straight cylindrical support
  , slant = slant_angle // tooth slant angle 
  , a1up = up_angle // big circle rotation angle up (~tooth height)
  , a1down = down_angle // big circle rotation angle down (~tooth depth)
  , cuttype = type_of_cutoff // cylindrical,spherical,none
  , dbore = hole_diameter
  , acone = cone_angle
  );
}

// need to debug zbasedemo ...
module demoarray
  (nmax = 12
  ,rdemo = 18
  ,dist = 48, // way bigger for cuttype none
  ,zbasedemo_convex = 32
  ,zbasedemo_flat = 16
  ,zbasedemo_concave = 4
  ,aconedemo = 30
  ,cuttypedemo = "cylindrical"
  ,dboredemo = 12.6
  )
{
for(ndemo=[2:nmax])
  {
  i = ndemo-2;
  translate([0,dist*i,0])
    {
    translate([-1*dist,0,0])
    hirth
      ( n = ndemo
      , r = rdemo
      , zbase = zbasedemo_concave
      , slant = 60
      , a1up = 12 - ndemo/2 // just to get something reasonable
      , a1down = 14  - ndemo/2
      , cuttype = cuttypedemo
      , dbore = dboredemo
      , acone = -aconedemo
      );
    translate([0*dist,0,0])
    hirth
      ( n = ndemo
      , r = rdemo
      , zbase = zbasedemo_flat
      , slant = 60
      , a1up = 12 - ndemo/2 
      , a1down = 14 - ndemo/2
      , cuttype = cuttypedemo
      , dbore = 0
      , acone = 0
      );
    translate([+1*dist,0,0])
    hirth
      ( n = ndemo
      , r = rdemo
      , zbase = zbasedemo_convex
      , slant = 60
      , a1up = 12 - ndemo/2 
      , a1down = 14 - ndemo/2
      , cuttype = cuttypedemo
      , dbore = dboredemo
      , acone = +aconedemo
      ); 
    }
  }
}

// #####################################
// #####################################
// #####################################
// #####################################

module hirth
  ( n = 12 // >=2
  , r = 24 // use a bit bigger r for cutters
  , zbase = 8 // bottom depth of straight cylindrical support
  , slant = 60 // tooth slant angle 
  , a1up = 10 // big circle rotation angle up (~tooth height)
  , a1down = 12 // big circle rotation angle down (~tooth depth)
  , cuttype = "cylindrical" // cylindrical,spherical,none
  , dbore = 0 // diameter of center hole
  , acone = 0 // conicality
  , verbose = "false"
  , eps = 0.05
  )
{ 
  
  a2 = slant; // hirth plane tilt angle
  // a2 ideally as high (steep) as possible 
  // without causing parts to remain stuck together
  // after heavy compressive loading
  // if printlayers hooking together just barely sometimes is problemeatic
  // then stay below 70°

  angle = 360/n; // angle per full tooth period 
  a3 = angle/4; // angle per half addendum or dedendum

  // Note: rmax includes some overstand that can be cut off by 
  // choosing a cuttype parameter of "cylindrical" or "spherical"
  // cuttoff overstand factor of 2.0 was choosen to 
  // have no missing part artefacts even with just 2 teeth
  rmax = r*2/cos(acone);
  // the cos(acone) part takes care of a shrinking cylindrical radius for 
  // higher absolute values of acone  
  // making the factor bigger is bad since at some point it
  // overrides the specified baseheight
  

  // TODO -- how to calculate a1 for sharp teeth (no flat at tip)?
  // It may be that this is not analytically solvable ...

  // ###############################################
  // deriving the height of the dedenta of the teeth
  // basically manually multiplying rotation matrices
  // Math derivation. DO NOT REMOVE.
  // after first rotation around z axis
  // rmax * [cos(a1),sin(a1),0] 
  // after second rotation around x axis
  // rmax * [cos(a1), sin(a1), 0]
  // rmax * [cos(a1), sin(a1)*cos(a2)-0*sin(a2),sin(a1)*sin(a2)+0*cos(a2)]
  // rmax * [cos(a1), sin(a1)*cos(a2),sin(a1)*sin(a2)]
  // after third rotation around z axis again
  // rmax * [cos(a1)*cos(a3)-sin(a1)*cos(a2)*sin(a3),
  //         cos(a1)*sin(a3)+sin(a1)*cos(a2)*cos(a3),
  //         sin(a1)*sin(a2)]
  // last line gives z height of where the point finally ends up
  k0down = sin(a1down) * sin(a2);
  z0down = rmax * k0down; // see math derivation above
  a0down = asin(k0down);
  // analogously for the addenda (not checked, not in use)
  k0up = sin(a1up) * sin(a2);
  z0up = rmax * k0up; 
  a0up = asin(k0up);


  // ############## 
  // the following is relevant for:
  // -> permanent tooth suport sttructures
  // -> the conical case (acone>0 || acone<0)
  // final rotations in xy plane (used for conicality only)
  a4up = atan2
    (cos(a1up)*sin(a3)+sin(a1up)*cos(a2)*cos(a3)
    ,cos(a1up)*cos(a3)-sin(a1up)*cos(a2)*sin(a3));
  a4down = atan2
    (cos(a1down)*sin(a3)+sin(a1down)*cos(a2)*cos(a3)
    ,cos(a1down)*cos(a3)-sin(a1down)*cos(a2)*sin(a3));

  // finding z0cone for the conical case (reduced to 2D problem)
  // point is at: [sqrt(rmax^2-z0down^2),z0down]
  // rotating it further by the cone angle:
  // z0cone = [sin(acone),cos(acone)] · [sqrt(rmax^2-z0down^2),z0down] 
  // this gives:
  z0cone = sqrt(rmax*rmax - z0down*z0down) * sin(acone) + z0down * cos(acone);
  // Sanity check: acone==0 => z0cone == z0down FINE
  r0cone = sqrt(rmax*rmax - z0down*z0down) * cos(acone) - z0down * sin(acone);

  // #################### debugging section
  if(verbose) echo(z0cone=z0cone);
  if(verbose) echo(z0down=z0down);
  if(verbose) echo(a3=a3, "quater angle per tooth");
  // DEBUG plane
  //color("grey")translate([0,0,-z0down]) cylinder(r= 100,h=0.05);
  //color("grey")translate([0,0,-z0cone]) cylinder(r= 100,h=0.05);

  difference()
  {
    intersection()
    {
      union()
      {
        for(i=[0:n-1])
        {
          rotate(360/n*i,[0,0,1])
          color("red") hirthtooth(); 
        }
        if(z0cone>=0) // flat and convex case
        {
          // permanent support structure
          support(n);
          // straight cylindrical base
          hbase = zbase-z0cone;
          color(basecolor)
          translate([0,0,-zbase])
            cylinder(r=r0cone,h=hbase,center=false);
          
          // BELOW was a somewhat dangerous hack:
          // conical adapter section
          //scale([1,1,-1])
          //  cylinder(r1=0,r2=r0cone,h=z0cone);
        } 
        else // (z0cone<0) // concave case
        {
          difference()
          {
            // baseblock
            hbase = zbase-z0cone;
            color(basecolor)
            translate([0,0,-zbase])
              cylinder(r=r0cone,h=hbase,center=false);
            // cutting from the baseblock
            translate([0,0,2*eps])  support(n);
            // doesn't this make the construction obsolete? To Check ...
            
            // BELOW was a not working hack:            
            // conical cut
            //scale([1,1,-1])
            //translate([0,0,eps])
            //  cylinder(r1=0,r2=r0cone,h=-z0cone);     
          }
        }
      }
      // cutting it round
      if(cuttype == "spherical") sphere(r=r,$fn=24*4);
      if(cuttype == "cylindrical") 
        color(cylcol) cylinder(r=r,h=42*r,center=true); //**
      if(cuttype == "none") {} // leave the cutting to the lib user
      // hirth couplings work in spherical coordinates so ...
      // a cylinder mathematically less correct than sphere ...
      // but it is computationally less expensive
      // maybe make this optional
    }
    if(dbore!=0) color(cylcol) cylinder(r=dbore/2,h=1000,center=true);
  }
  
  module hirthtooth()
  {
    hull()
    { 
      spanner(); // the center
      
      // ################
      // upper tooth tips

      // make it conical
      rotate(-a4up,[0,0,1])      
      rotate(acone,[0,1,0])      
      rotate(+a4up,[0,0,1])
      //rotate(acone,[0,-1,0]) // < only approx correct for many small teeth
      // basic planar hirth
      rotate(-a3,[0,0,1]) // rotate x-y-plane crossing of big circle
      rotate(+a2,[1,0,0]) // tilt big circle 
      rotate(a1up,[0,0,1]) // big circle rotation angle
        translate([rmax,0,0]) spanner();

      // make it conical
      rotate(+a4up,[0,0,1])      
      rotate(acone,[0,1,0])      
      rotate(-a4up,[0,0,1])      
      // basic planar hirth
      rotate(+a3,[0,0,1]) // rotate x-y-plane crossing of big circle
      rotate(-a2,[1,0,0]) // tilt big circle 
      rotate(-a1up,[0,0,1]) // big circle rotation angle
        translate([rmax,0,0]) spanner();
      
      // #################
      // lower tooth bases

      // make it conical
      rotate(-a4down,[0,0,1])      
      rotate(acone,[0,1,0])      
      rotate(+a4down,[0,0,1])
      // basic planar hirth
      rotate(-a3,[0,0,1]) // rotate x-y-plane crossing of big circle
      rotate(+a2,[1,0,0]) // tilt big circle 
      rotate(-a1down,[0,0,1]) // big circle rotation angle
        translate([rmax,0,0]) spanner();

      // make it conical
      rotate(+a4down,[0,0,1])      
      rotate(acone,[0,1,0])      
      rotate(-a4down,[0,0,1])      
      // basic planar hirth      
      rotate(+a3,[0,0,1]) // rotate x-y-plane crossing of big circle
      rotate(-a2,[1,0,0]) // tilt big circle 
      rotate(+a1down,[0,0,1]) // big circle rotation angle
        translate([rmax,0,0]) spanner();
      
      // READ IN REVERSE:
      // rotate to move flank from tooth center to tooth side
      // rotate that move into the final flank-angle 
      // rotate an angle that will become an angle anong the flank later
      // shift spanner out to spanning radius
      
      // TODO 
      // how to extend this to allow for conical hirth joints
    }    
  }
  
  module support(n)
  {
    for(i=[0:n-1])
    {
      rotate(360/n*i,[0,0,1])
      {
        a4down_complement = ((360/n)-2*a4down)/2; // ISSUE why too wide here ???? 
        // support for tooth (addendum)
        union() // does not seem to help with artefacts
        {
          color("green") support_slice(a4down);
          //spacefiller for gap (dedendum) 
          color("blue")    
            rotate(360/(2*n),[0,0,1])
              support_slice(a4down_complement); // issues here
        }
      }
    }
  }

  module support_slice(a=1)
  {
    scale([1,1,-1])
    hull()
    {
      translate([0     ,0,0     ]) spanner();
      translate([0     ,0,z0cone]) spanner();
      rotate(-a,[0,0,1])
        translate([r0cone,0,z0cone]) spanner();
      rotate(+a,[0,0,1])
        translate([r0cone,0,z0cone]) spanner();
    }
  }

  module spanner() // minor hack
  { 
    cube(eps); // fewer vertices
    //rotate(90,[0,1,0])sphere(r=0.05,$fn=6); 
  }
  
}
