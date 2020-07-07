# Recording

This branch exists to create a video recording of the demo. This is a dumb hack with manual steps and a bunch of modifications to the code.

Result: [Youtube: City Knot (demoscene)](https://www.youtube.com/watch?v=asV6yIC_bsk)

You will need [WSCapture](https://github.com/depp/wscapture), which requires Go and FFmpeg.

    pub global activate webdev 2.1.0
    make build_release

Then, edit the canvas style in build.html to have the desired video resolution. Finally,

    wscapture -root=build -rate=60 -size=1080p

Then, go to http://localhost:8080/delta.html. This will record a video. Keep the browser window open until done. The result must be combined with the music, which can be done with FFmpeg:

    ffmpeg -i videos/<video>.mkv -i ./web/music.opus -codec:v copy \
        -codec:a copy -shortest output.mkv

The result can be uploaded to YouTube.
