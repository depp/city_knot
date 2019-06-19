# City Life


## About 

The demo consists of a exploring a cityscape wrapped around a torusknot 

Target duration: 3 min

License; GPL

## Live Version

http://art.muth.org/delta.html 

( Developer Mode http://art.muth.org/delta.html#develop )

## Development

Note: run `make` without arguments for more info

### Install SDK 

Ubuntu: package `dart``

Other platforms:  https://dart.dev/tutorials/web/get-started (Section 2. Install Dart)


update PATH in Makefile 

### Install Demo Dependencies

make get

### Development Build

make serve

(launches web server with just-in-time-transpiling)

Navigate to localhost:8080/delta.html

### Release Build

make build_release 

make zipball (optional)

make serve_release

Navigate to localhost:8080/delta.html

