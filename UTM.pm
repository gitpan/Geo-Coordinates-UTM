package Geo::Coordinates::UTM;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require 5.005;
require Exporter;
require AutoLoader;

use Math::Trig;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     latlon_to_utm
	     utm_to_latlon
	     );

$VERSION = '0.02';

my $pi = 3.14159265;
my $quarterpi = $pi / 4;
my $deg2rad = $pi / 180;
my $rad2deg = 180 / $pi;

# Ellipsoid array (name,equatorial radius,square of eccentricity)

my @Ellipsoid=([ "Blank", 0, 0],
	       [ "Airy", 6377563, 0.00667054],
	       [ "Australian National", 6378160, 0.006694542],
	       [ "Bessel 1841", 6377397, 0.006674372],
	       [ "Bessel 1841 (Nambia) ", 6377484, 0.006674372],
	       [ "Clarke 1866", 6378206, 0.006768658],
	       [ "Clarke 1880", 6378249, 0.006803511],
	       [ "Everest", 6377276, 0.006637847],
	       [ "Fischer 1960 (Mercury) ", 6378166, 0.006693422],
	       [ "Fischer 1968", 6378150, 0.006693422],
	       [ "GRS 1967", 6378160, 0.006694605],
	       [ "GRS 1980", 6378137, 0.00669438],
	       [ "Helmert 1906", 6378200, 0.006693422],
	       [ "Hough", 6378270, 0.00672267],
	       [ "International", 6378388, 0.00672267],
	       [ "Krassovsky", 6378245, 0.006693422],
	       [ "Modified Airy", 6377340, 0.00667054],
	       [ "Modified Everest", 6377304, 0.006637847],
	       [ "Modified Fischer 1960", 6378155, 0.006693422],
	       [ "South American 1969", 6378160, 0.006694542],
	       [ "WGS 60", 6378165, 0.006693422],
	       [ "WGS 66", 6378145, 0.006694542],
	       [ "WGS-72", 6378135, 0.006694318],
	       [ "WGS-84", 6378137, 0.00669438]);

sub latlon_to_utm {
    # Expects Ellipsoid Number, Latitude, Longitude 
    # (Latitude and Longitude in decimal degrees)
    # Returns UTM Zone, UTM Easting, UTM Northing
    my (@args)=@_;
    my $ellipsoid=$args[0];
    my $latitude=$args[1];
    my $longitude=$args[2];
    if (($ellipsoid <1) or ($ellipsoid >23)) {
	die "Ellipsoid value (".$ellipsoid.") invalid.";
    }
    if  (($longitude < -180) or ($longitude > 180)) {
	die "Longitude value (".$longitude.") invalid.";
    }
    my $radius=$Ellipsoid[$ellipsoid][1];
    my $eccentricity=$Ellipsoid[$ellipsoid][2];
    my $k0=0.9996;
    my $long2=(($longitude + 180) - int (($longitude + 180)/360 ) * 360 - 180);
    my $zone=(int(($long2 + 180)/6) + 1);
    my $lat_radian=($latitude * $deg2rad);
    my $long_radian=($long2 * $deg2rad);
    if (($latitude >= 56.0) and ($latitude < 64.0) and ($long2 >= 3.0) and ($long2 < 12.0)) {
	$zone = 32;
    }
    if(( $latitude >= 72.0) and ($latitude < 84.0)) { 
	if(($long2 >= 0.0) and ($long2 <  9.0)) {
	    $zone = 31;
	} elsif(($long2 >= 9.0) and ($long2 < 21.0)) {
	    $zone = 33;
	} elsif(($long2 >= 21.0) and ($long2 < 33.0)) {
	    $zone = 35;
	} elsif(($long2 >= 33.0) and ($long2 < 42.0)) {
	    $zone = 37;
	}
    }    
    my $longorigin = (($zone - 1)*6 - 180 + 3);
    my $longoriginradian = $longorigin * $deg2rad;
    my $eccentprime=($eccentricity/(1-$eccentricity));
    
    my $N = ($radius/sqrt(1-$eccentricity * sin($lat_radian) * sin($lat_radian)));
    my $T = (tan($lat_radian) * tan($lat_radian));
    my $C = ($eccentprime*cos($lat_radian)*cos($lat_radian));
    my $A = (cos($lat_radian)*($long_radian-$longoriginradian));
    my $M = ($radius * ((1 - $eccentricity/4 - 3 * $eccentricity * $eccentricity/64 - 5 * $eccentricity * $eccentricity * $eccentricity/256) * $lat_radian - (3 * $eccentricity/8 + 3 * $eccentricity * $eccentricity/32 + 45 * $eccentricity * $eccentricity * $eccentricity/1024) * sin(2 * $lat_radian) + (15 * $eccentricity * $eccentricity/256 + 45 * $eccentricity * $eccentricity * $eccentricity/1024) * sin(4 * $lat_radian) - (35 * $eccentricity * $eccentricity * $eccentricity/3072) * sin(6 * $lat_radian)));
    my $utm_easting=($k0*$N*($A+(1-$T+$C)*$A*$A*$A/6 + (5-18*$T+$T*$T+72*$C-58*$eccentprime)*$A*$A*$A*$A*$A/120) + 500000.0);
    my $utm_northing=($k0*($M+$N*tan($lat_radian)*($A*$A/2+(5-$T+9*$C+4*$C*$C)*$A*$A*$A*$A/24 + (61-58*$T+$T*$T+600*$C-330*$eccentprime)*$A*$A*$A*$A*$A*$A/720)));
    if($latitude < 0) {
	$utm_northing += 10000000.0; 
    }
    my $utm_letter;
    if ((84 >= $latitude) and ($latitude >= 72)) {
	$utm_letter = 'X';
    } elsif ((72 > $latitude) && ($latitude >= 64)) {
	$utm_letter = 'W';
    } elsif ((64 > $latitude) && ($latitude >= 56)) {
	$utm_letter = 'V';
    } elsif ((56 > $latitude) && ($latitude >= 48)) {
	$utm_letter = 'U';
    } elsif ((48 > $latitude) && ($latitude >= 40)) {
	$utm_letter = 'T';
    } elsif ((40 > $latitude) && ($latitude >= 32)) {
	$utm_letter = 'S';
    } elsif ((32 > $latitude) && ($latitude >= 24)) {
	$utm_letter = 'R';
    } elsif ((24 > $latitude) && ($latitude >= 16)) {
	$utm_letter = 'Q';
    } elsif ((16 > $latitude) && ($latitude >= 8)) {
	$utm_letter = 'P';
    } elsif (( 8 > $latitude) && ($latitude >= 0)) {
	$utm_letter = 'N';
    } elsif (( 0 > $latitude) && ($latitude >= -8)) {
	$utm_letter = 'M';
    } elsif ((-8> $latitude) && ($latitude >= -16)) {
	$utm_letter = 'L';
    } elsif ((-16 > $latitude) && ($latitude >= -24)) {
	$utm_letter = 'K';
    } elsif ((-24 > $latitude) && ($latitude >= -32)) {
	$utm_letter = 'J';
    } elsif ((-32 > $latitude) && ($latitude >= -40)) {
	$utm_letter = 'H';
    } elsif ((-40 > $latitude) && ($latitude >= -48)) {
	$utm_letter = 'G';
    } elsif ((-48 > $latitude) && ($latitude >= -56)) {
	$utm_letter = 'F';
    } elsif ((-56 > $latitude) && ($latitude >= -64)) {
	$utm_letter = 'E';
    } elsif ((-64 > $latitude) && ($latitude >= -72)) {
	$utm_letter = 'D';
    } elsif ((-72 > $latitude) && ($latitude >= -80)) {
	$utm_letter = 'C';
    } else {
	die "Latitude (".$latitude.") out of UTM range.";
    }
    $zone.=$utm_letter;
    return $zone,$utm_easting,$utm_northing;
}

sub utm_to_latlon {
    # Expects Ellipsoid Number, UTM zone, UTM Easting, UTM Northing
    # Returns Latitude, Longitude
    # (Latitude and Longitude in decimal degrees, UTM Zone e.g. 23S)
    my (@args)=@_;
    my $valid_utm="CDEFGHJKLMNPQRSTUVWX";
    my $ellipsoid=$args[0];
    my $zone=$args[1];
    my $easting=$args[2];
    my $northing=$args[3];
    my $zone_letter=substr($zone,(length($zone)-1),1);
    my $ZoneNumber=substr($zone,0,(length($zone)-1));
    if (($ellipsoid <1) or ($ellipsoid >23)) {
	die "Ellipsoid value (".$ellipsoid.") invalid.";
    }
    if (($valid_utm=~ tr/\Q$zone_letter//) = 0) {
	die "UTM zone (".$zone_letter.") invalid.";
    }
    my $radius=$Ellipsoid[$ellipsoid][1];
    my $eccentricity=$Ellipsoid[$ellipsoid][2];
    my $k0=0.9996;
    my $e1 = (1-sqrt(1-$eccentricity))/(1+sqrt(1-$eccentricity));
    my $x = $easting - 500000; # Remove Longitude offset
    my $y = $northing;
    # Set hemisphere (1=Northern, 0=Southern)
    my $hemisphere;
    if (("NPQRSTUVWX" =~ $zone_letter) > 0) {
	$hemisphere = 1;
    } else {
	$hemisphere = 0;
	$y -= 10000000.0; # Remove Southern Offset
    }
    my $longorigin=($ZoneNumber - 1)*6 - 180 + 3;
    my $eccPrimeSquared = ($eccentricity)/(1-$eccentricity);
    my $M = ($y/$k0);
    my $mu = $M/($radius*(1-$eccentricity/4-3*$eccentricity*$eccentricity/64-5*$eccentricity*$eccentricity*$eccentricity/256));
    my $phi1rad = $mu+(3*$e1/2-27*$e1*$e1*$e1/32)*sin(2*$mu)+(21*$e1*$e1/16-55*$e1*$e1*$e1*$e1/32)*sin(4*$mu)+(151*$e1*$e1*$e1/96)*sin(6*$mu);
    my $phi1 = $phi1rad*$rad2deg;
    my $N1 = $radius/sqrt(1-$eccentricity*sin($phi1rad)*sin($phi1rad));
    my $T1 = tan($phi1rad)*tan($phi1rad);
    my $C1 = $eccentricity*cos($phi1rad)*cos($phi1rad);
    my $R1 = $radius*(1-$eccentricity)/((1-$eccentricity*sin($phi1rad)*sin($phi1rad))**1.5);
    my $D = $x/($N1*$k0);

    my $Latitude = $phi1rad-($N1*tan($phi1rad)/$R1)*($D*$D/2-(5+3*$T1+10*$C1-4*$C1*$C1-9*$eccPrimeSquared)*$D*$D*$D*$D/24+(61+90*$T1+298*$C1+45*$T1*$T1-252*$eccPrimeSquared-3*$C1*$C1)*$D*$D*$D*$D*$D*$D/720);
    $Latitude = $Latitude * $rad2deg;
    my $Longitude = ($D-(1+2*$T1+$C1)*$D*$D*$D/6+(5-2*$C1+28*$T1-3*$C1*$C1+8*$eccPrimeSquared+24*$T1*$T1)*$D*$D*$D*$D*$D/120)/cos($phi1rad);
    $Longitude = $longorigin + $Longitude * $rad2deg;
    return $Latitude, $Longitude;
}

1;
__END__

=head1 NAME

Geo::Coordinates::UTM - Perl extension for Latitiude Longitude conversions.

=head1 SYNOPSIS

use Geo::Coordinates::UTM;

($zone,$easting,$northing)=latlon_to_utm($ellipsoid,$latitude,$longitude);

($latitude,$longitude)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);

=head1 DESCRIPTION

This module will translate latitude longitude coordinates to Universal Transverse Mercator(UTM) coordinates and vice versa.

=head2 Mercator Projection

The Mercator projection was first invented to help mariners. They needed to be able to take a course and know the distance traveled, and draw a line on the map which showed the day's journey. In order to do this, Mercator invented a projection which preserved length, by projecting the earth's surface onto a cylinder, sharing the same axis as the earth itself.
This caused all Latitude and Longitude lines to intersect at a 90 degree angle, thereby negating the problem that longitude lines get closer together at the poles.

=head2 Transverse Mercator Projection

A Transverse Mercator projection takes the cylinder and turns it on its side. Now the cylinder's axis passes through the equator, and it can be rotated to line up with the area of interest. Many countries use Transverse Mercator for their grid systems.

=head2 Universal Transverse Mercator

The Universal Transverse Mercator(UTM) system sets up a universal world wide system for mapping. The Transverse Mercator projection is used, with the cylinder in 60 positions. This creates 60 zones around the world.
Positions are measured using Eastings and Northings, measured in meters, instead of Latitude and Longitude. Eastings start at 500,000 on the centre line of each zone.
In the Northern Hemisphere, Northings are zero at the equator and increase northward. In the Southern Hemisphere, Northings start at 10 million at the equator, and decrease southward. You must know which hemisphere and zone you are in to interpret your location globally. 
Distortion of scale, distance, direction and area increase away from the central meridian.

UTM projection is used to define horizontal positions world-wide by dividing the surface of the Earth into 6 degree zones, each mapped by the Transverse Mercator projection with a central meridian in the center of the zone. 
UTM zone numbers designate 6 degree longitudinal strips extending from 80 degrees South latitude to 84 degrees North latitude. UTM zone characters designate 8 degree zones extending north and south from the equator. Eastings are measured from the central meridian (with a 500 km false easting to insure positive coordinates). Northings are measured from the equator (with a 10,000 km false northing for positions south of the equator).

UTM is applied separately to the Northern and Southern Hemisphere, thus within a single UTM zone, a single X / Y pair of values will occur in both the Northern and Southern Hemisphere. 
To eliminate this confusion, and to speed location of points, a UTM zone is sometimes subdivided into 20 zones of Latitude. These grids can be further subdivided into 100,000 meter grid squares with double-letter designations. This subdivision by Latitude and further division into grid squares is generally referred to as the Military Grid Reference System (MGRS).
The unit of measurement of UTM is always meters and the zones are numbered from 1 to 60 eastward, beginning at the 180th meridian.
The scale distortion in a north-south direction parallel to the central meridian (CM) is constant However, the scale distortion increases either direction away from the CM. To equalize the distortion of the map across the UTM zone, a scale factor of 0.9996 is applied to all distance measurements within the zone. The distortion at the zone boundary, 3 degrees away from the CM is approximately 1%.

=head2 Datums and Ellipsoids

Unlike local surveys, which treat the Earth as a plane, the precise determination of the latitude and longitude of points over a broad area must take into account the actual shape of the Earth. To achieve the precision necessary for accurate location, the Earth cannot be assumed to be a sphere. Rather, the Earth's shape more closely approximates an ellipsoid (oblate spheroid): flattened at the poles and bulging at the Equator. Thus the Earth's shape, when cut through its polar axis, approximates an ellipse.
A "Datum" is a standard representation of shape and offset for coordinates, which includes an ellipsoid and an origin. You must consider the Datum when working with geospatial data, since data with two different Datum will not line up. The difference can be as much as a kilometer!

=head1 EXAMPLES

A description of the available ellipsoids and sample usage of the conversion routines follows

=head2 Ellipsoids

The Ellipsoids available are numbered as follows:

=over 6

=item 1 Airy

=item 2 Australian National

=item 3 Bessel 1841

=item 4 Bessel 1841 (Nambia)

=item 5 Clarke 1866

=item 6 Clarke 1880

=item 7 Everest

=item 8 Fischer 1960 (Mercury)

=item 9 Fischer 1968

=item 10 GRS 1967

=item 11 GRS 1980

=item 12 Helmert 1906

=item 13 Hough

=item 14 International

=item 15 Krassovsky

=item 16 Modified Airy

=item 17 Modified Everest

=item 18 Modified Fischer 1960

=item 19 South American 1969

=item 20 WGS 60

=item 21 WGS 66

=item 22 WGS-72

=item 23 WGS-84

=back
 

=head2 latlon_to_utm

Latitude values in the southern hemisphere should be supplied as negative values (e.g. 30 deg South will be -30). Similarly Longitude values West of the meridian should also be supplied as negative values. Both latitude and longitude should not be entered as deg,min,sec but as their decimal equivalent, e.g. 30 deg 12 min 22.432 sec should be entered as 30.2062311

The ellipsoid value should correspond to one of the numbers above, e.g. to use WGS-84, the ellipsoid value should be 23

For latitude  57deg 49min 59.000sec North
    longitude 02deg 47min 20.226sec West

using Clarke 1866 (Ellipsoid 5)

     ($zone,$east,$north)=latlon_to_utm(5,57.803055556,-2.788951667)

returns 

     $zone  = 30V
     $east  = 512533.364651484
     $north = 6409932.13416127

=head2 utm_to_latlon

Reversing the above example,

     ($latitude,$longitude)=utm_to_latlon(5,30V,512533.364651484,6409932.13416127)

returns

     $latitude  = 57.8330555601433
     $longitude = -2.788951666974

     which equates to

     latitude  57deg 49min 59.000sec North
     longitude 02deg 47min 20.226sec West

=head1 AUTHOR

Graham Crookham, grahamc@cpan.org

=head1 COPYRIGHT

Copyright (c) 2000,2002 by Graham Crookham.  All rights reserved.
    
This package is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.             

=cut
