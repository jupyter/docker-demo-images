# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/minimal

MAINTAINER Jupyter Project <jupyter@googlegroups.com>

USER root

# Julia dependencies
RUN apt-get install -y julia libnettle4 && apt-get clean

# R dependencies that conda can't provide (X, fonts)
RUN apt-get install -y libxrender1 fonts-dejavu && apt-get clean

# The Glorious Glasgow Haskell Compiler
RUN apt-get install -y --no-install-recommends software-properties-common && apt-get clean
RUN add-apt-repository -y ppa:hvr/ghc
RUN sed -i s/jessie/trusty/g /etc/apt/sources.list.d/hvr-ghc-jessie.list
RUN apt-get update
RUN apt-get install -y cabal-install-1.22 ghc-7.8.4 happy-1.19.4 alex-3.1.3 && apt-get clean
ENV PATH /opt/cabal/1.22/bin:/opt/ghc/7.8.4/bin:/opt/happy/1.19.4/bin:/opt/alex/3.1.3/bin:$PATH

# IHaskell dependencies
RUN apt-get install -y --no-install-recommends zlib1g-dev libzmq3-dev libtinfo-dev libcairo2-dev libpango1.0-dev && apt-get clean

RUN mkdir /home/jovyan/communities && mkdir /home/jovyan/featured
ADD notebooks/ /home/jovyan/
RUN chown -R jovyan:jovyan /home/jovyan

EXPOSE 8888

USER jovyan
ENV HOME /home/jovyan
ENV SHELL /bin/bash
ENV USER jovyan
ENV PATH $CONDA_DIR/bin:$PATH
WORKDIR $HOME

USER jovyan

# Python packages
RUN conda install --yes numpy pandas scikit-learn matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle numba bokeh && conda clean -yt

# R packages
RUN conda config --add channels r
RUN conda install --yes r-irkernel r-plyr r-devtools r-rcurl r-dplyr r-ggplot2 r-caret && conda clean -yt

# IJulia and Julia packages
RUN julia -e 'Pkg.add("IJulia")'
RUN julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")'

# IHaskell
ENV PATH /home/jovyan/.cabal/bin:$PATH
RUN cabal update && \
    cabal install cpphs && \
    cabal install gtk2hs-buildtools && \
    cd && git clone --depth 1 https://github.com/gibiansky/IHaskell.git && \
    cd IHaskell/ && \
    ./build.sh ihaskell && \
    cd && rm -fr ~/IHaskell $(echo ~/.cabal/bin/* | grep -iv ihaskell) ~/.cabal/packages ~/.cabal/share/doc ~/.cabal/setup-exe-cache ~/.cabal/logs

# Extra Kernels
RUN pip install --user bash_kernel

# Featured notebooks
RUN git clone --depth 1 https://github.com/jvns/pandas-cookbook.git /home/jovyan/featured/pandas-cookbook/

# Convert notebooks to the current format
RUN find . -name '*.ipynb' -exec ipython nbconvert --to notebook {} --output {} \;
RUN find . -name '*.ipynb' -exec ipython trust {} \;

CMD ipython notebook
