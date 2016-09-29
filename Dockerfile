# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/all-spark-notebook:28515ed64e5e

MAINTAINER Jupyter Project <jupyter@googlegroups.com>

USER root
RUN apt-get update \
 && apt-get -y dist-upgrade --no-install-recommends \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# BEGININCLUDE jupyter/datascience-notebook
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# FROM jupyter/scipy-notebook

# MAINTAINER Jupyter Project <jupyter@googlegroups.com>

USER root

# R pre-requisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    gfortran \
    gcc && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Julia dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    julia \
    libnettle4 && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $NB_USER

# R packages including IRKernel which gets installed globally.
# Pin r-base to a specific build number for https://github.com/jupyter/docker-stacks/issues/210#issuecomment-246081809
RUN conda config --add channels r && \
    conda install --quiet --yes \
    'rpy2=2.8*' \
    'r-base=3.3.1 1' \
    'r-irkernel=0.6*' \
    'r-plyr=1.8*' \
    'r-devtools=1.11*' \
    'r-dplyr=0.4*' \
    'r-ggplot2=2.1*' \
    'r-tidyr=0.5*' \
    'r-shiny=0.13*' \
    'r-rmarkdown=0.9*' \
    'r-forecast=7.1*' \
    'r-stringr=1.0*' \
    'r-rsqlite=1.0*' \
    'r-reshape2=1.4*' \
    'r-nycflights13=0.2*' \
    'r-caret=6.0*' \
    'r-rcurl=1.95*' \
    'r-randomforest=4.6*' && conda clean -tipsy

# Install IJulia packages as jovyan and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not
# taking effect properly on the .local folder in the jovyan home dir.
RUN julia -e 'Pkg.add("IJulia")' && \
    mv /home/$NB_USER/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter

# Show Julia where conda libraries are
# Add essential packages
RUN echo "push!(Sys.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" > /home/$NB_USER/.juliarc.jl && \
    julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")' && julia -F -e 'Pkg.add("HDF5")'
# ENDINCLUDE jupyter/datascience-notebook


# Install system libraries first as root
USER root

# The Glorious Glasgow Haskell Compiler
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:hvr/ghc && \
    sed -i s/jessie/trusty/g /etc/apt/sources.list.d/hvr-ghc-jessie.list && \
    apt-get update && \
    apt-get install -y cabal-install-1.22 ghc-7.8.4 happy-1.19.4 alex-3.1.3 && \
    apt-get clean

# IHaskell dependencies
RUN apt-get install -y --no-install-recommends zlib1g-dev libzmq3-dev libtinfo-dev libcairo2-dev libpango1.0-dev && apt-get clean

# Ruby dependencies
RUN apt-get install -y --no-install-recommends ruby ruby-dev libtool autoconf automake gnuplot-nox libsqlite3-dev libatlas-base-dev libgsl0-dev libmagick++-dev imagemagick && \
    ln -s /usr/bin/libtoolize /usr/bin/libtool && \
    apt-get clean
# We need to pin activemodel to 4.2 while we have ruby < 2.2
RUN gem update --system --no-document && \
    gem install --no-document 'activemodel:~> 4.2' sciruby-full

# Now switch to $NB_USER for all conda and other package manager installs
USER $NB_USER

ENV PATH /home/$NB_USER/.cabal/bin:/opt/cabal/1.22/bin:/opt/ghc/7.8.4/bin:/opt/happy/1.19.4/bin:/opt/alex/3.1.3/bin:$PATH

# IRuby
RUN iruby register

# IHaskell + IHaskell-Widgets + Dependencies for examples
RUN cabal update && \
    CURL_CA_BUNDLE='/etc/ssl/certs/ca-certificates.crt' curl 'https://www.stackage.org/lts-2.22/cabal.config?global=true' >> ~/.cabal/config && \
    cabal install cpphs && \
    cabal install gtk2hs-buildtools && \
    cabal install ihaskell-0.8.0.0 --reorder-goals && \
    cabal install ihaskell-widgets-0.2.2.1 HTTP Chart Chart-cairo && \
    ihaskell install && \
    rm -fr $(echo ~/.cabal/bin/* | grep -iv ihaskell) ~/.cabal/packages ~/.cabal/share/doc ~/.cabal/setup-exe-cache ~/.cabal/logs

# Extra Kernels
RUN pip install --user --no-cache-dir bash_kernel && \
    python -m bash_kernel.install

# Clone featured notebooks before adding local content to avoid recloning
# everytime something changes locally
RUN mkdir -p /home/$NB_USER/work/communities && \
    mkdir -p /home/$NB_USER/work/featured
RUN git clone --depth 1 https://github.com/jvns/pandas-cookbook.git /home/$NB_USER/work/featured/pandas-cookbook/
RUN git clone --depth 1 https://github.com/gibiansky/IHaskell.git /home/$NB_USER/work/IHaskell/ && \
    mv /home/$NB_USER/work/IHaskell/ihaskell-display/ihaskell-widgets/Examples /home/$NB_USER/work/featured/ihaskell-widgets && \
    rm -r /home/$NB_USER/work/IHaskell

# Add local content, starting with notebooks and datasets which are the largest
# so that later, smaller file changes do not cause a complete recopy during 
# build
COPY notebooks/ /home/$NB_USER/work/
COPY datasets/ /home/$NB_USER/work/datasets/

# Switch back to root for permission fixes, conversions, and trust. Make sure
# trust is done as $NB_USER so that the signing secret winds up in the $NB_USER
# profile, not root's
USER root

# Convert notebooks to the current format and trust them
RUN find /home/$NB_USER/work -name '*.ipynb' -exec jupyter nbconvert --to notebook {} --output {} \; && \
    chown -R $NB_USER:users /home/$NB_USER && \
    sudo -u $NB_USER env "PATH=$PATH" find /home/$NB_USER/work -name '*.ipynb' -exec jupyter trust {} \;

# Finally, add the site specific tmpnb.org / try.jupyter.org configuration.
# These should probably be split off into a separate docker image so that others
# can reuse the very expensive build of all the above with their own site 
# customization.

# Install our custom.js
COPY resources/custom.js /home/$NB_USER/.jupyter/custom/

# Add the templates
COPY resources/templates/ /srv/templates/
RUN chmod a+rX /srv/templates

# Append tmpnb specific options to the base config
COPY resources/jupyter_notebook_config.partial.py /tmp/
RUN cat /tmp/jupyter_notebook_config.partial.py >> /home/$NB_USER/.jupyter/jupyter_notebook_config.py && \
    rm /tmp/jupyter_notebook_config.partial.py
