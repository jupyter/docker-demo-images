# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/demo-minimal

MAINTAINER Jupyter Project <jupyter@googlegroups.com>

USER root

# Julia dependencies
RUN apt-get install -y julia libnettle4 && apt-get clean

# R dependencies that conda can't provide (X, fonts, compilers)
RUN apt-get install -y libxrender1 fonts-dejavu gfortran gcc && apt-get clean

# The Glorious Glasgow Haskell Compiler
RUN apt-get install -y --no-install-recommends software-properties-common && apt-get clean
RUN add-apt-repository -y ppa:hvr/ghc
RUN sed -i s/jessie/trusty/g /etc/apt/sources.list.d/hvr-ghc-jessie.list
RUN apt-get update
RUN apt-get install -y cabal-install-1.22 ghc-7.8.4 happy-1.19.4 alex-3.1.3 && apt-get clean
ENV PATH /home/jovyan/.cabal/bin:/opt/cabal/1.22/bin:/opt/ghc/7.8.4/bin:/opt/happy/1.19.4/bin:/opt/alex/3.1.3/bin:$PATH

# IHaskell dependencies
RUN apt-get install -y --no-install-recommends zlib1g-dev libzmq3-dev libtinfo-dev libcairo2-dev libpango1.0-dev && apt-get clean

# Ruby dependencies
RUN apt-get install -y --no-install-recommends ruby ruby-dev libtool autoconf automake gnuplot-nox libsqlite3-dev libatlas-base-dev libgsl0-dev && apt-get clean && ln -s /usr/bin/libtoolize /usr/bin/libtool
RUN apt-get install -y --no-install-recommends libmagick++-dev imagemagick
RUN gem install --no-rdoc --no-ri sciruby-full

# Spark dependencies
ENV APACHE_SPARK_VERSION 1.4.1
RUN apt-get install -y --no-install-recommends openjdk-7-jre-headless
RUN wget -qO - http://d3kbcqa49mib13.cloudfront.net/spark-${APACHE_SPARK_VERSION}-bin-hadoop2.6.tgz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop2.6 spark

# Scala Spark kernel (build and cleanup)
RUN cd /tmp && \
    echo deb http://dl.bintray.com/sbt/debian / > /etc/apt/sources.list.d/sbt.list && \
    apt-get update && \
    git clone https://github.com/ibm-et/spark-kernel.git && \
    apt-get install -yq --force-yes --no-install-recommends sbt && \
    cd spark-kernel && \
    sbt compile -Xms1024M \
        -Xmx2048M \
        -Xss1M \
        -XX:+CMSClassUnloadingEnabled \
        -XX:MaxPermSize=1024M && \
    sbt pack && \
    mv kernel/target/pack /opt/sparkkernel && \
    chmod +x /opt/sparkkernel && \
    rm -rf ~/.ivy2 && \
    rm -rf ~/.sbt && \
    rm -rf /tmp/spark-kernel && \
    apt-get remove -y sbt && \
    apt-get clean

RUN mkdir /home/jovyan/communities && mkdir /home/jovyan/featured
ADD notebooks/ /home/jovyan/
ADD datasets/ /home/jovyan/datasets/
RUN chown -R jovyan:jovyan /home/jovyan

EXPOSE 8888

USER jovyan
ENV HOME /home/jovyan
ENV SHELL /bin/bash
ENV USER jovyan
ENV SPARK_HOME /usr/local/spark
ENV PATH $CONDA_DIR/bin:$CONDA_DIR/envs/python2/bin:$PATH
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.8.2.1-src.zip
WORKDIR $HOME

USER jovyan

# Python packages
RUN conda install --yes numpy pandas scikit-learn scikit-image matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle dill numba bokeh && conda clean -yt

# Now for a python2 environment
RUN conda create -p $CONDA_DIR/envs/python2 python=2.7 ipython numpy pandas scikit-learn scikit-image matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle dill numba bokeh && conda clean -yt
RUN $CONDA_DIR/envs/python2/bin/python $CONDA_DIR/envs/python2/bin/ipython kernelspec install-self --user

# IRuby
RUN iruby register

# R packages
RUN conda config --add channels r
RUN conda install --yes r-irkernel r-plyr r-devtools r-rcurl r-dplyr r-ggplot2 r-caret rpy2 r-tidyr r-shiny r-rmarkdown r-forecast r-stringr r-rsqlite r-reshape2 r-nycflights13 r-randomforest && conda clean -yt

# IJulia and Julia packages
RUN julia -e 'Pkg.add("IJulia")'
RUN julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")'

# IHaskell
RUN cabal update && \
    cabal install cpphs && \
    cabal install gtk2hs-buildtools && \
    cabal install ihaskell-0.6.2.0 --reorder-goals && \
    ihaskell install && \
    rm -fr $(echo ~/.cabal/bin/* | grep -iv ihaskell) ~/.cabal/packages ~/.cabal/share/doc ~/.cabal/setup-exe-cache ~/.cabal/logs

# Scala Spark kernel spec
RUN mkdir -p $HOME/.ipython/kernels/scala
COPY resources/kernel.json $HOME/.ipython/kernels/scala/

# Extra Kernels
RUN pip install --user bash_kernel

# Featured notebooks
RUN git clone --depth 1 https://github.com/jvns/pandas-cookbook.git /home/jovyan/featured/pandas-cookbook/

# Convert notebooks to the current format
RUN find . -name '*.ipynb' -exec ipython nbconvert --to notebook {} --output {} \;
RUN find . -name '*.ipynb' -exec ipython trust {} \;

COPY dexy.yaml dexy_requirements.txt environment.yml /home/jovyan/notebooks/

# Run the ipython notebook from a python2 environment that we control
# Install publically available packages here, private once in run.sh after pip.conf is available
RUN  conda create --name python2 python=2.7

RUN /bin/bash -c "source activate python2 && pip install -r notebooks/dexy_requirements.txt"

CMD ["/bin/bash","-c","run.sh && ipython notebook"]

