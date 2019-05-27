# Delta 1 

The demo consists of a exploring a citiscape wrapped around a torusknot 

Target duration: 2-3min


Go to http://0.0.0.0:8080/build/delta.html for what we have so far


## A Very Preliminary Script

basically we are alternating between travelling on the surface or inside a torus knot
and changing themes (audio/video) whenever there is a transition.

1. **15 sec** the camera will start far away from the TK and move towards it until it almost touches the surface 
2. **20 sec** it will then travel along the surface of the TK hovering over one of the roads until
             the road leads into an underground tunnel
3. **15 sec** the camera now travel inside the TK - this is a standard demoscene situation - ideas welcome
4. **20 sec** trip along outside of TK (variation of 2.) 
5. **15 sec** trip inside the TK (variation of 3.) 
6. **20 sec** trip along outside of TK (variation of 2.) 
7. **15 sec** trip inside the TK (variation of 3.) 
8. **10 sec** Finale


## Top Priorities

* Script/Storyboard
* Ideas for inside torus knot theme
* Ideas for finale
* Music composition
* Implementation: video
* Implementation: audio


## Secondary Priorities

* cars - fallback: no cars
* audio-video sync (maybe even fft based effects) - fallback: sync based on time elapsed since music started
* background - fallback: no background, pick routes with litte visible background
* fancy building interiors with paralax shaders - fallback: simple facade texture as in pixelcity
* ideas for beginning: switch from planar city to city on torus know - fallback: zoom from distance to torus knot

## Backup

### Inside torus knot ideas

* check shader toy for tunnel ideas
* stick buildings on the inside


### Music 

* https://www.youtube.com/watch?v=aoXOdAUD7IM starting at [0:15] it has this interesting helicopter like sound which slowly morphs until [1:20]
* https://www.youtube.com/watch?v=Fk1z0TfRIR0 starting [1:10] could be the intro
* https://www.youtube.com/watch?v=jpYNwFGaMik
* http://www.jamendo.com/de/track/34406/life-s-things (used by demoscene-ish example)
* https://www.youtube.com/watch?v=MFu66ye6YWM
* https://soundcloud.com/twoseventwo/return-to-the-earth
* https://soundcloud.com/twoseventwo/dreams-of-a-forgotten-past

### Synthesizer

* overview: http://chrisstrelioff.ws/sound-room/about.html
* https://github.com/padenot/litsynth
* https://github.com/mmontag/dx7-synth-js/blob/master/images/yamaha-dx-7.png
* drums https://github.com/philcowans/Javascript-DX7
* drums  https://dev.opera.com/articles/drum-sounds-webaudio/




## Setup andf Development


Note: run `make` without arguments for more info

### git issues

This repo recursively includes the `mondrianjs` repo . After the initial cloning run


`git submodule update --init`


to populate the `mondrianjs/` subdir.
If that does not work because of
permission/authorization problems try to patch `.git/config` so that 
all url line start with `url = https://USERNAME@github.com/net...`

### Install SDK

Ubuntu: package `dart``

Other platforms:  https://dart.dev/tutorials/web/get-started (Section 2. Install Dart)


update PATH in Makefile 

### Install Demo Dependencies

make get


## Development Build

### Launch web server (also does just-in-time-transpiling)

make serve

Go to localhost:8080/delta.html

## Release Build

make build_release 

make serve_release



