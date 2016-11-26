#!/bin/bash

LEPTONICA_PRE_COMPILED="leptonica-1.71.tgz"
OPENCV_PRE_COMPILED="opencv3.0_with_contrib_2.tar.gz"
TESSERACT_PRE_COMPILED="tesseract_2.tar.gz"
GHOSTSCRIPT_PRE_COMPILED="gs9_2.tar.gz"
TESSDATA_PRE_COMPILED="tessdata-slim_2.tar.gz"
PYTHON_GS_PRE_COMPILED="python-gs_2.tar.gz"

LEPTONICA_LOCATION="http://www.leptonica.org/source/leptonica-1.71.tar.gz"
OPENCV_LOCATION="https://s3.amazonaws.com/labsdeps/opencv.tar.gz"
OPENCV_CONTRIB_LOCATION="https://s3.amazonaws.com/labsdeps/opencv_contrib.tar.gz"
TESSERACT_LOCATION="https://github.com/tesseract-ocr/tesseract/archive/3.04.00.tar.gz"
GHOSTSCRIPT_LOCATION="https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs920/ghostscript-9.20.tar.gz"

apt-get update

#build leptonica
  apt-get install -y build-essential automake autoconf libtool g++ python-pip \
  && wget $LEPTONICA_LOCATION \
  && tar -zxvf leptonica-1.71.tar.gz \
  && cd leptonica-1.71/ \
  && ./autobuild \
  && mkdir -p ../labs-leptonica-1.71 \
  && ./configure --prefix=/labs-leptonica-1.71 \
  && make && make install \
  && cd / \
  && tar -cvzf $LEPTONICA_PRE_COMPILED /labs-leptonica-1.71 \
  && cp $LEPTONICA_PRE_COMPILED /app
  # && pip install s3cmd && pip install s4cmd && wget -O ~/.s3cfg https://s3.amazonaws.com/labsdeps/.s3cfg \
  # && chmod u+x /usr/local/bin/s4cmd 
  # && \
  # s4cmd put labs-leptonica-1.71_2.tgz s3://labsdeps/

#build opencv
apt-get install -y cmake pkg-config libjpeg8-dev libtiff4-dev libjasper-dev libpng12-dev libatlas-base-dev gfortran checkinstall yasm libopencore-amrnb-dev libtheora-dev libxvidcore-dev libdc1394-22 libdc1394-22-dev libxine-dev libtbb-dev wget autoconf automake libtool g++ ghostscript liblog4cplus-dev tk8.5 tcl8.5 tk8.5-dev tcl8.5-dev python-pip python-dev \
  && wget $OPENCV_LOCATION \
  && wget $OPENCV_CONTRIB_LOCATION \
  && tar -xvf opencv.tar.gz  \
  && tar -xvf opencv_contrib.tar.gz  \
  && mkdir -p /opencv/build \
  && cd /opencv/build \
  && pip install numpy \
  && cmake -D WITH_FFMPEG=OFF -D WITH_GSTREAMER=NO -D WITH_V4L=NO -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D OPENCV_EXTRA_MODULES_PATH=/opencv_contrib/modules .. \
  && make -j4 \
  && make install \
  && cp lib/cv2.so . \
  && cp /usr/lib/x86_64-linux-gnu/libdc1394.so.22 lib/ \
  && cp /usr/lib/x86_64-linux-gnu/libraw1394.* lib/ \
  && cp /usr/lib/x86_64-linux-gnu/libpng* lib/ \
  && cp /usr/lib/x86_64-linux-gnu/libtiff* lib/ \
  && cp /usr/lib/x86_64-linux-gnu/libjpeg.* lib/ \
  && cp /lib/x86_64-linux-gnu/libusb-* lib/ \
  && cp -r /usr/local/share/ . \
  && rm -rf share/ca-certificates/ share/fonts/ share/fonts/ share/ruby-build/ share/man \
  && tar -czf $OPENCV_PRE_COMPILED bin/ include/ lib/ share/ cv2.so  \
  && cp $OPENCV_PRE_COMPILED /app

#build tesseract
wget $TESSERACT_LOCATION \
 && tar -zxvf 3.04.00.tar.gz \
 && rm -rf 3.04.00.tar.gz \
 && cd tesseract-3.04.00/ \
 && ./autogen.sh \
 && mkdir /labs-tesseract-3.0 \
 && LIBLEPT_HEADERSDIR=/labs-leptonica-1.71/include/ ./configure --prefix=/labs-tesseract-3.0/ --with-extra-libraries=/labs-leptonica-1.71/lib/ \
 && make -j2 \
 && make install \
 && cd /labs-tesseract-3.0/ \
 && tar -czf $TESSERACT_PRE_COMPILED bin/ include/ lib/ share/ \
 && cp $TESSERACT_PRE_COMPILED /app
 # \
 # && s4cmd put -f tesseract_2.tar.gz s3://labsdeps/

 #tessdata
 mkdir /tessdata
 cd /tessdata
 wget https://github.com/rebbix/tesseract-language-files/blob/master/eng/eng.cube.bigrams \
 https://github.com/rebbix/tesseract-language-files/blob/master/eng/eng.cube.fold \
 https://github.com/rebbix/tesseract-language-files/blob/master/eng/eng.cube.lm \
 https://github.com/rebbix/tesseract-language-files/blob/master/eng/eng.cube.nn \
 https://github.com/rebbix/tesseract-language-files/blob/master/eng/eng.cube.params \
 https://github.com/rebbix/tesseract-language-files/blob/master/eng/eng.cube.size \
 https://github.com/rebbix/tesseract-language-files/blob/master/eng/eng.cube.word-freq \
 https://github.com/rebbix/tesseract-language-files/blob/master/eng/eng.tesseract_cube.nn \
 https://github.com/rebbix/tesseract-language-files/blob/master/eng/eng.traineddata
 tar -czf $TESSDATA_PRE_COMPILED *.*
 cp $TESSDATA_PRE_COMPILED /app
 # s4cmd put -f tessdata-slim_2.tar.gz s3://labsdeps/

 #ghostscript
 mkdir /gs
 cd /gs
 wget $GHOSTSCRIPT_LOCATION
 mkdir -p /app/.heroku/vendor
 tar -zxvf ghostscript-9.20.tar.gz
 cd ghostscript-9.20
 ./configure --prefix=/app/.heroku/vendor --disable-compile-inits --enable-dynamic --with-system-libtiff
 make
 make so 
 make install
 make soinstall
 cd /app/.heroku/vendor
 tar -czf $GHOSTSCRIPT_PRE_COMPILED bin/ lib/ share/ include/
 cp $GHOSTSCRIPT_PRE_COMPILED /app

 #python-gs
 pip install ghostscript
 sed -i -e 's/cdll.LoadLibrary("libgs.so")/cdll.LoadLibrary("\/app\/.heroku\/vendor\/lib\/libgs.so")/g' /usr/local/lib/python2.7/dist-packages/ghostscript/_gsprint.py
 cd /usr/local/lib/python2.7/dist-packages/
 tar -czf $PYTHON_GS_PRE_COMPILED ghostscript ghostscript-0.4.1.egg-info/
 cp $PYTHON_GS_PRE_COMPILED /app

 cd /app
 echo "" > sift-dependencies-md5.txt
 md5sum $LEPTONICA_PRE_COMPILED >> sift-dependencies-md5.txt
 md5sum $OPENCV_PRE_COMPILED >> sift-dependencies-md5.txt
 md5sum $TESSERACT_PRE_COMPILED >> sift-dependencies-md5.txt
 md5sum $TESSDATA_PRE_COMPILED >> sift-dependencies-md5.txt
 md5sum $GHOSTSCRIPT_PRE_COMPILED >> sift-dependencies-md5.txt
 md5sum $PYTHON_GS_PRE_COMPILED >> sift-dependencies-md5.txt
