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
      python=3.6 \
      bottleneck=1.2.1 \
      cartopy=0.17.0 \
      dask=2.6.0 \
      geopandas=0.4.1 \
      jupyter=1.0.0 \
      matplotlib=3.1.1 \
      netcdf4=1.4.2 \
      notebook=5.7.4 \
      numpy=1.17.2 \
      pandas=0.25.2 \
      rasterio=1.0.21 \
      rasterstats=0.13.1 \
      scipy=1.3.1 \
      xarray=0.13.0 \
      xmltodict=0.12.0
RUN conda clean -a

ENV SOURCE_DIR=/usr/local/src

# download and unpack onhm-runners
ARG VERSION_ONHM_RUNNERS=0.1.4
RUN wget -P $SOURCE_DIR \
   https://github.com/nhm-usgs/onhm-runners/archive/$VERSION_ONHM_RUNNERS.tar.gz
RUN cd $SOURCE_DIR && tar -xf $VERSION_ONHM_RUNNERS.tar.gz && \
  rm $VERSION_ONHM_RUNNERS.tar.gz

ENV USER=nhm
RUN useradd -ms /bin/bash $USER
