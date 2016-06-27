# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/all-spark-notebook:a249876881d3

MAINTAINER Jupyter Project <jupyter@googlegroups.com>

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
RUN gem update --system --no-document && \
    gem install --no-document sciruby-full

# Now switch to jovyan for all conda and other package manager installs
USER jovyan

ENV PATH /home/jovyan/.cabal/bin:/opt/cabal/1.22/bin:/opt/ghc/7.8.4/bin:/opt/happy/1.19.4/bin:/opt/alex/3.1.3/bin:$PATH

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
RUN mkdir -p /home/jovyan/work/communities && \
    mkdir -p /home/jovyan/work/featured
RUN git clone --depth 1 https://github.com/jvns/pandas-cookbook.git /home/jovyan/work/featured/pandas-cookbook/
RUN git clone --depth 1 https://github.com/gibiansky/IHaskell.git /home/jovyan/work/IHaskell/ && \
    mv /home/jovyan/work/IHaskell/ihaskell-display/ihaskell-widgets/Examples /home/jovyan/work/featured/ihaskell-widgets && \
    rm -r /home/jovyan/work/IHaskell

# Add local content, starting with notebooks and datasets which are the largest
# so that later, smaller file changes do not cause a complete recopy during 
# build
COPY notebooks/ /home/jovyan/work/
COPY datasets/ /home/jovyan/work/datasets/

# Switch back to root for permission fixes, conversions, and trust. Make sure
# trust is done as jovyan so that the signing secret winds up in the jovyan
# profile, not root's
USER root

# Convert notebooks to the current format and trust them
RUN find /home/jovyan/work -name '*.ipynb' -exec jupyter nbconvert --to notebook {} --output {} \; && \
    chown -R jovyan:users /home/jovyan && \
    sudo -u jovyan env "PATH=$PATH" find /home/jovyan/work -name '*.ipynb' -exec jupyter trust {} \;

# Finally, add the site specific tmpnb.org / try.jupyter.org configuration.
# These should probably be split off into a separate docker image so that others
# can reuse the very expensive build of all the above with their own site 
# customization.

# Expose our custom setup to the installed ipython (for mounting by nginx)
COPY resources/custom.js /opt/conda/lib/python3.4/site-packages/notebook/static/custom/

# Add the templates
COPY resources/templates/ /srv/templates/
RUN chmod a+rX /srv/templates

# Append tmpnb specific options to the base config
COPY resources/jupyter_notebook_config.partial.py /tmp/
RUN cat /tmp/jupyter_notebook_config.partial.py >> /home/jovyan/.jupyter/jupyter_notebook_config.py && \
    rm /tmp/jupyter_notebook_config.partial.py
