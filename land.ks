// GENERIC KSP PROBE LANDER SCRIPT
// land(ALTOFFSET, VDEORBIT, ALTLANDING)
//
// ALTOFFSET - how high the altimeter is off the ground from the base of the probe
// VDEORBIT - de-orbit with this velocity
// ALTLANDING - radar altitude to trigger last phase of landing
// ^ braking phase will be 3x ALTLANDING

DECLARE PARAMETER P1, P2, P3.

DECLARE ALTOFFSET TO 5. IF(P1) SET ALTOFFSET TO P1.
DECLARE VDEORBIT TO 100. IF(P2) SET VDEORBIT TO P2.
DECLARE ALTLANDING TO 1000. IF(P3) SET ALTLANDING TO P3.
DECLARE ALTBRAKING TO ALTLANDING*3.

PRINT "COMMENCING AUTO LANDING...".
PRINT "========================================".
PRINT "1) ALTIMETER OFFSET: " + ALTOFFSET + " m".
PRINT "2)       V(DEORBIT): " + VDEORBIT + " m/s".
PRINT "3)  LANDING MODE AT: " + ALTLANDING + " m".
PRINT "^   BRAKING MODE AT: " + ALTBRAKING + " m".

// *** de-orbit systems prep and orientation change ***
IF( STAGE:READY ) STAGE.
SAS OFF.
// make sure landing gear is retracted
GEAR OFF.
// retract solar panels for landing
PANELS OFF.
WAIT 1.

// retrograde orientation by SAS introduces inaccuracies and latencies
// that are inacceptable for landing in low-grav (like Minmus), hence
// we need to lock steering directly to the inverse of our movement vector:
LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
// using minimal thrust to accelerate orientation change in craft with
// underpowered reaction wheels:
LOCK THROTTLE TO 0.1.
WAIT 3.

// *** init de-orbit burn ***
PRINT "RETRO BURN...".
SAS ON.
WAIT 0.1.
SET SASMODE TO "STABILITY".
UNTIL SHIP:SURFACESPEED < VDEORBIT {
  LOCK THROTTLE TO 1.
  WAIT 0.1.
}

// *** going into descent mode ***
PRINT "DESCENDING...".
SAS ON.
SET T TO 0.
LOCK THROTTLE TO T.
WAIT 3.

// *** descent control loop ***
SET MODE TO "". SET LMODE TO "".

UNTIL ALT:RADAR < ALTOFFSET {

  SET DV TO 0.
  IF( ALT:RADAR < ALTLANDING ) {
    // "hovering" landing mode, precise thrust control
    SET MODE TO "LANDING".
    SET MAXLANDINGSPEED TO SQRT(MAX(0.1, ALT:RADAR - ALTOFFSET)).
        SET DV TO MAX(0, SHIP:SURFACESPEED - MAXLANDINGSPEED).
  } ELSE IF( ALT:RADAR < ALTBRAKING ) {
    // braking mode is for general speed control prior to landing
        SET MODE TO "BRAKING".
    SET MAXLANDINGSPEED TO ALT:RADAR / 25.
        SET DV TO MAX(0, SHIP:SURFACESPEED - MAXLANDINGSPEED).
  }
  ELSE {
        SET MODE TO "STAND-BY".
  }

  IF( LMODE <> MODE ) {
    PRINT MODE + " MODE (DV:" + ROUND(DV) + " m/s)".
        SET LMODE TO MODE.
  }

  IF( DV > 0 ) {
        // controls tightness of thrust adjustment with SQRT
    SET T TO MIN(1, SQRT(DV)/5).
  }
  ELSE {
    // smooth power-down
    SET T TO MAX(0, T - 0.01).
  }

  IF( ALT:RADAR < 20 ) {
    // prepare for touch down
        GEAR ON.
  }

  WAIT 0.001.

}

PRINT "TOUCH DOWN.".
LOCK THROTTLE TO 0.
LOCK STEERING TO UP.
WAIT 2.

PRINT "LANDING COMPLETE.".
UNLOCK STEERING.
PANELS ON.
WAIT 1.

SAS OFF.


