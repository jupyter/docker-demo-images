# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/all-spark-notebook:c7fb6660d096

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

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

USER root

# R pre-requisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    tzdata \
    gfortran \
    gcc && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Julia dependencies
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=0.6.0

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang.s3.amazonaws.com/bin/linux/x64/`echo $JULIA_VERSION | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "3a27ea78b06f46701dc4274820d9853789db205bce56afdc7147f7bd6fa83e41 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

# Show Julia where conda libraries are \
RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    # Create JULIA_PKGDIR \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

USER $NB_USER

# R packages including IRKernel which gets installed globally.
RUN conda config --system --append channels r && \
    conda install --quiet --yes \
    'rpy2=2.8*' \
    'r-base=3.3.2' \
    'r-irkernel=0.7*' \
    'r-plyr=1.8*' \
    'r-devtools=1.12*' \
    'r-tidyverse=1.0*' \
    'r-shiny=0.14*' \
    'r-rmarkdown=1.2*' \
    'r-forecast=7.3*' \
    'r-rsqlite=1.1*' \
    'r-reshape2=1.4*' \
    'r-nycflights13=0.2*' \
    'r-caret=6.0*' \
    'r-rcurl=1.95*' \
    'r-crayon=1.3*' \
    'r-randomforest=4.6*' && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR

# Add Julia packages
# Install IJulia as jovyan and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not
# taking effect properly on the .local folder in the jovyan home dir.
RUN julia -e 'Pkg.init()' && \
    julia -e 'Pkg.update()' && \
    julia -e 'Pkg.add("HDF5")' && \
    julia -e 'Pkg.add("Gadfly")' && \
    julia -e 'Pkg.add("RDatasets")' && \
    julia -e 'Pkg.add("IJulia")' && \
    # Precompile Julia packages \
    julia -e 'using HDF5' && \
    julia -e 'using Gadfly' && \
    julia -e 'using RDatasets' && \
    julia -e 'using IJulia' && \
    # move kernelspec out of home \
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter
# ENDINCLUDE jupyter/datascience-notebook


# Install system libraries first as root
USER root

# The Glorious Glasgow Haskell Compiler
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:hvr/ghc && \
    apt-get update && \
    apt-get install -y cabal-install-1.24 ghc-8.0.2 happy-1.19.5 alex-3.1.7 && \
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

# Perl 6
RUN apt-get update \
  && apt-get install -y build-essential \
  && git clone https://github.com/rakudo/rakudo.git -b 2017.12 \
  && cd rakudo && perl Configure.pl --prefix=/usr --gen-moar --gen-nqp --backends=moar \
  && make && make install && cd .. && rm -rf rakudo \
  && git clone https://github.com/ugexe/zef.git && cd zef && perl6 -Ilib bin/zef install . \
  && export PATH=$PATH:/usr/share/perl6/site/bin \
  && zef -v install Jupyter::Kernel SVG::Plot --force-test \
  && jupyter-kernel.p6 --generate-config

ENV PATH /usr/share/perl6/site/bin:$PATH

# Now switch to $NB_USER for all conda and other package manager installs
USER $NB_USER

ENV PATH /home/$NB_USER/.cabal/bin:/opt/cabal/1.24/bin:/opt/ghc/8.0.2/bin:/opt/happy/1.19.5/bin:/opt/alex/3.1.7/bin:$PATH

# IRuby
RUN iruby register

# IHaskell + IHaskell-Widgets + Dependencies for examples
RUN cabal update && \
    CURL_CA_BUNDLE='/etc/ssl/certs/ca-certificates.crt' curl 'https://www.stackage.org/lts-9.21/cabal.config?global=true' >> ~/.cabal/config && \
    cabal install cpphs && \
    cabal install gtk2hs-buildtools && \
    cabal install ihaskell-0.9.0.2 --reorder-goals && \
    cabal install \
        # ihaskell-widgets-0.2.3.1 \ temporarily disabled because installation fails
        HTTP Chart Chart-cairo && \
    ihaskell install --prefix=$CONDA_DIR && \
    rm -fr $(echo ~/.cabal/bin/* | grep -iv ihaskell) ~/.cabal/packages ~/.cabal/share/doc ~/.cabal/setup-exe-cache ~/.cabal/logs

# Extra Kernels
RUN pip install --no-cache-dir bash_kernel && \
    python -m bash_kernel.install --sys-prefix

# Clone featured notebooks before adding local content to avoid recloning
# everytime something changes locally
RUN mkdir -p /home/$NB_USER/communities && \
    mkdir -p /home/$NB_USER/featured
RUN git clone --depth 1 https://github.com/jvns/pandas-cookbook.git /home/$NB_USER/featured/pandas-cookbook/
RUN git clone --depth 1 https://github.com/gibiansky/IHaskell.git /home/$NB_USER/IHaskell/ && \
    mv /home/$NB_USER/IHaskell/ihaskell-display/ihaskell-widgets/Examples /home/$NB_USER/featured/ihaskell-widgets && \
    rm -r /home/$NB_USER/IHaskell

# Add local content, starting with notebooks and datasets which are the largest
# so that later, smaller file changes do not cause a complete recopy during
# build
COPY notebooks/ /home/$NB_USER/
COPY datasets/ /home/$NB_USER/datasets/

# Switch back to root for permission fixes, conversions, and trust. Make sure
# trust is done as $NB_USER so that the signing secret winds up in the $NB_USER
# profile, not root's
USER root

# Convert notebooks to the current format and trust them
RUN find /home/$NB_USER -name '*.ipynb' -exec jupyter nbconvert --to notebook {} --output {} \; && \
    chown -R $NB_USER:users /home/$NB_USER && \
    sudo -u $NB_USER env "PATH=$PATH" find /home/$NB_USER -name '*.ipynb' -exec jupyter trust {} \;

# Finally, add the site specific tmpnb.org / try.jupyter.org configuration.
# These should probably be split off into a separate docker image so that others
# can reuse the very expensive build of all the above with their own site
# customization.

# Add the templates
COPY resources/templates/ /srv/templates/
RUN chmod a+rX /srv/templates

USER $NB_USER

# Install our custom.js
COPY resources/custom.js /home/$NB_USER/.jupyter/custom/

# Append tmpnb specific options to the base config
COPY resources/jupyter_notebook_config.partial.py /tmp/
RUN cat /tmp/jupyter_notebook_config.partial.py >> /home/$NB_USER/.jupyter/jupyter_notebook_config.py && \
    rm /tmp/jupyter_notebook_config.partial.py
