# Dart Getting Started


Note: run `make` without arguments for more info

## Setup

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
