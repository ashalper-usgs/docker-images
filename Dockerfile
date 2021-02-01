# U.S. Geological Survey
#
# File - Dockerfile
#
# Purpose - Dockerfile to build USGS National Hydrologic Model (NHM).
#
# Authors - Andrew Halper <ashalper@usgs.gov>
#

# Miniconda 3
FROM continuumio/miniconda3:4.7.12

LABEL maintainer="ashalper@usgs.gov"

# nhm user
RUN useradd -ms /bin/bash nhm
ENV HOMEDIR=/home/nhm

# data directories
VOLUME ["/nhm"]
RUN mkdir -p /nhm/gridmetetl
RUN chown -R nhm /nhm
RUN chgrp -R nhm /nhm
RUN chmod -R 755 /nhm

# install additional packages
RUN apt-get update && \
    apt-get -y install dialog file gcc gfortran make procps unzip && \
    apt-get autoclean && \
    apt-get purge

# It should only be necessary to set this to "-k" (the
# "conda update/install ..." option) at certain installations in
# .usgs.gov where the DOI root SSL certificate has not been installed
# (e.g., on a VM).
ARG insecure
RUN if [ "$insecure" = -k ]; then \
       wget http://sslhelp.doi.net/docs/DOIRootCA2.cer ; \
       # see
       # https://stackoverflow.com/questions/9072376/configure-git-to-accept-a-particular-self-signed-server-certificate-for-a-partic
       git config --global http.sslCAInfo DOIRootCA2.cer ; \
    fi

# Update/upgrade Conda
RUN conda update -n base conda -y $insecure
RUN conda install -n base -c defaults -c conda-forge $insecure \
    python=3.7 \
    dask \
    geopandas \
    nco \
    netcdf4 \
    pandas\
    requests \
    xarray \
    xmltodict
RUN conda clean -a

ENV SOURCE_DIR=/usr/local/src

# onhm-runners
ARG VERSION_ONHM_RUNNERS=0.1.6
RUN wget --progress=bar:force:noscroll -P $SOURCE_DIR \
   https://github.com/nhm-usgs/onhm-runners/archive/$VERSION_ONHM_RUNNERS.tar.gz
RUN cd $SOURCE_DIR && tar -xzf $VERSION_ONHM_RUNNERS.tar.gz
RUN mv $SOURCE_DIR/onhm-runners-$VERSION_ONHM_RUNNERS $SOURCE_DIR/onhm-runners
RUN rm $SOURCE_DIR/$VERSION_ONHM_RUNNERS.tar.gz

# gridmETL
ARG VERSION_TAG_GRIDMETETL=v0.25
RUN wget -P $SOURCE_DIR https://github.com/nhm-usgs/gridmetetl/archive/$VERSION_TAG_GRIDMETETL.tar.gz
RUN cd $SOURCE_DIR && tar -xvzf $VERSION_TAG_GRIDMETETL.tar.gz
# not sure why it's necessary to omit the "v" from "0.25" here, but it is
RUN mv $SOURCE_DIR/gridmetetl-0.25 $SOURCE_DIR/gridmetetl
RUN rm $SOURCE_DIR/$VERSION_TAG_GRIDMETETL.tar.gz
RUN mkdir -p /nhm/gridmetetl/Output

# data-loader

# TODO: try to move these environment variables to ../nhm.env. They
# are defined here because this is the only place we could find where
# their values are reliably passed into the container.

# HRU data
ENV HRU_DATA_PKG=Data_hru_shp_gfv11_v1.zip
ENV HRU_SOURCE=ftp://ftpext.usgs.gov/pub/cr/co/denver/BRR-CR/pub/rmcd/${HRU_DATA_PKG}

# PRMS data file archive
ENV PRMS_DATA_PKG=NHM-PRMS_CONUS_GF_1_1_v5.1.0.4.zip
ENV PRMS_SOURCE=ftp://ftpext.usgs.gov/pub/cr/co/denver/BRR-CR/pub/rmcd/${PRMS_DATA_PKG}

# PRMS
ARG VERSION_TAG_PRMS=5.1.0.4_linux
# Build PRMS
RUN git -c advice.detachedHead=false clone \
    https://github.com/nhm-usgs/prms.git --branch $VERSION_TAG_PRMS \
    --depth=1 $SOURCE_DIR/prms && \
    cd $SOURCE_DIR/prms && \
    make && \
    rm -rf .git || true && \
    rm .gitignore || true && \
    rm Makefile || true && \
    rm makelist || true

# verifier
ARG VERSION_TAG_VERIFY=0.1.1
RUN wget --progress=bar:force:noscroll -P $SOURCE_DIR \
    https://github.com/nhm-usgs/onhm-verify-eval/archive/$VERSION_TAG_VERIFY.tar.gz
RUN cd $SOURCE_DIR && tar -xf $VERSION_TAG_VERIFY.tar.gz && \
  mv onhm-verify-eval-$VERSION_TAG_VERIFY onhm-verify-eval && \
  rm $VERSION_TAG_VERIFY.tar.gz

# nhm user
USER nhm
WORKDIR /home/nhm

# install entry-point script
COPY model /usr/local/bin

ENTRYPOINT /usr/local/bin/model
