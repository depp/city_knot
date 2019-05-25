# Dart Getting Started

Note: run `make` without arguments for more info

A recent runnable preview can be found at http://art.muth.org/delta.html


## Setup


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


Go to http://0.0.0.0:8080/build/delta.html


## "Vision"

The demo consists of a exploring a citiscape wrapped around a torusknot 

Target duration: 2-3min


### Script

1. **15 sec** the camera will start far away from the TK and move towards it until it almost touches the surface 
2. **20 sec** it will then travel along the surface of the TK hovering over one of the roads until
             the road leads into an underground tunnel
3. **15 sec** the camera now travel inside the TK - this is a standard demoscene situation - ideas welcome
4. **20 sec** trip along outside of TK (variation of 2.) 
5. **15 sec** trip inside the TK (variation of 3.) 
6. **20 sec** trip along outside of TK (variation of 2.) 
7. **15 sec** trip inside the TK (variation of 3.) 
8. **10 sec** Finale




The are lots of open issue, e.g what should we show:

* in the background (maybe smaller version of TK)
* for the parts traveling on the surface of the TK (variations of PixelCity scheme would be relatively easy 
  [Standard](http://art.muth.org/pixelcity.html#Standard),
  [Wireframe](http://art.muth.org/pixelcity.html#WireFrameRed),
  [Daylight](http://art.muth.org/pixelcity.html#DayLight))
* for the parts traveling inside the TK. ([for inspiration see the demoscene-ish example here](http://chronosteam.github.io/ChronosGL/Examples/)) 
* for the finale


Music is completely open too. Some ideas:

* https://www.youtube.com/watch?v=aoXOdAUD7IM starting at [0:15] it has this interesting helicopter like sound which slowly morphs until [1:20]
* https://www.youtube.com/watch?v=Fk1z0TfRIR0 starting [1:10] could be the intro
* https://www.youtube.com/watch?v=jpYNwFGaMik
* http://www.jamendo.com/de/track/34406/life-s-things (used by demoscene-ish example)
