# Designed to be run as 
# 
# docker run -it -p 9999:8888 ipython/latest

FROM ipython/scipystack

MAINTAINER IPython Project <ipython-dev@scipy.org>

# The ipython/ipython image has the full working copy of IPython
WORKDIR /srv/ipython/
RUN chmod a+rwX /srv/ipython/examples

# Dependencies for the example notebooks
RUN apt-get build-dep -y mpi4py && pip2 install scikit-image vincent dill networkx mpi4py && pip3 install scikit-image vincent dill networkx mpi4py

# Install vim to make it available in the terminal
RUN apt-get install -y vim

# Install R, the R kernel, and R magics
RUN apt-get install -y r-base r-base-dev r-cran-rcurl libreadline-dev
RUN pip2 install rpy2 && pip3 install rpy2
RUN pip2 install terminado && pip3 install terminado

# Julia Installation
RUN apt-get install software-properties-common python-software-properties -y && \
    add-apt-repository ppa:staticfloat/juliareleases && \
    add-apt-repository ppa:staticfloat/julia-deps && \
    apt-get update && \
    apt-get install julia -y && \
    apt-get install libnettle4

EXPOSE 8888

# We run our docker images with a non-root user as a security precaution.
# jovyan is our user
RUN useradd -m -s /bin/bash jovyan

USER jovyan
ENV HOME /home/jovyan
ENV SHELL /bin/bash
ENV USER jovyan

RUN ipython profile create
RUN mkdir /home/jovyan/communities
RUN mkdir /home/jovyan/featured

# IJulia installation
RUN julia -e 'Pkg.add("IJulia")'
# Julia packages
RUN julia -e 'Pkg.add("Gadfly")'
RUN julia -e 'Pkg.add("RDatasets")'

# R installation
RUN mkdir /home/jovyan/.R/
RUN echo 'R_LIBS_USER=/home/jovyan/.R:/usr/lib/R/site-library' > /home/jovyan/.Renviron
RUN echo 'options(repos=structure(c(CRAN="http://cran.rstudio.com")))' > /home/jovyan/.Rprofile
RUN echo "PKG_CXXFLAGS = '-std=c++11'" > /home/jovyan/.R/Makevars
RUN echo "install.packages(c('ggplot2', 'XML', 'plyr', 'randomForest', 'Hmisc', 'stringr', 'RColorBrewer', 'reshape', 'reshape2'))" | R --no-save
RUN echo "install.packages(c('RCurl', 'devtools', 'dplyr'))" | R --no-save
RUN echo "install.packages(c('httr'))" | R --no-save
RUN echo "install.packages(c('knitr'))" | R --no-save
RUN echo "install.packages(c('packrat'))" | R --no-save
RUN echo "install.packages(c('reshape2'))" | R --no-save
RUN echo "install.packages(c('rmarkdown'))" | R --no-save
RUN echo "install.packages(c('rvtest'))" | R --no-save
RUN echo "install.packages(c('testthat'))" | R --no-save
RUN echo "install.packages(c('tidyr'))" | R --no-save
RUN echo "install.packages(c('shiny'))" | R --no-save
RUN echo "library(devtools); install_github('armstrtw/rzmq'); install_github('takluyver/IRdisplay'); install_github('takluyver/IRkernel'); IRkernel::installspec()" | R --no-save
RUN echo "library(devtools); install_github('hadley/lineprof')" | R --no-save
RUN echo "library(devtools); install_github('rstudio/rticle')" | R --no-save
RUN echo "library(devtools); install_github('jimhester/covr')" | R --no-save

##
RUN echo 'source("http://bioconductor.org/biocLite.R"); biocLite("BiocInstaller")' | R --no-save

RUN echo "install.packages(c('base64enc'))" | R --no-save
RUN echo "install.packages(c('Cairo'))" | R --no-save
RUN echo "install.packages(c('codetools'))" | R --no-save
RUN echo "install.packages(c('data.table'))" | R --no-save
RUN echo "install.packages(c('downloader'))" | R --no-save
RUN echo "install.packages(c('gridExtra'))" | R --no-save
RUN echo "install.packages(c('gtable'))" | R --no-save
RUN echo "install.packages(c('hexbin'))" | R --no-save
RUN echo "install.packages(c('Hmisc'))" | R --no-save
RUN echo "install.packages(c('jpeg'))" | R --no-save
RUN echo "install.packages(c('Lahman'))" | R --no-save
RUN echo "install.packages(c('lattice'))" | R --no-save
RUN echo "install.packages(c('MASS'))" | R --no-save
RUN echo "install.packages(c('PKI'))" | R --no-save
RUN echo "install.packages(c('png'))" | R --no-save
RUN echo "install.packages(c('microbenchmark'))" | R --no-save
RUN echo "install.packages(c('mgcv'))" | R --no-save
RUN echo "install.packages(c('mapproj'))" | R --no-save
RUN echo "install.packages(c('maps'))" | R --no-save
RUN echo "install.packages(c('maptools'))" | R --no-save
RUN echo "install.packages(c('mgcv'))" | R --no-save
RUN echo "install.packages(c('multcomp'))" | R --no-save
RUN echo "install.packages(c('nlme'))" | R --no-save
RUN echo "install.packages(c('nycflights13'))" | R --no-save
RUN echo "install.packages(c('quantreg'))" | R --no-save
RUN echo "install.packages(c('Rcpp'))" | R --no-save
RUN echo "install.packages(c('RCurl'))" | R --no-save
RUN echo "install.packages(c('rJava'))" | R --no-save
RUN echo "install.packages(c('roxygen2'))" | R --no-save
RUN echo "install.packages(c('RMySQL'))" | R --no-save
RUN echo "install.packages(c('RPostgreSQL'))" | R --no-save
RUN echo "install.packages(c('RSQLite'))" | R --no-save
RUN echo "install.packages(c('testit'))" | R --no-save
RUN echo "install.packages(c('XML'))" | R --no-save





# Workaround for issue with ADD permissions
USER root
ADD common/profile_default /home/jovyan/.ipython/profile_default
RUN cp /home/jovyan/.ipython/profile_default/static/custom/* /srv/ipython/IPython/html/static/custom/ && chmod a+r /srv/ipython/IPython/html/static/custom/

# All the additions to give to the created user.
ADD kernels/Julia/ /srv/Julia/
ADD notebooks/ /home/jovyan/
RUN git clone --depth 1 https://github.com/jupyter/strata-sv-2015-tutorial.git /home/jovyan/featured/strata-sv-2015-tutorial/
RUN git clone --depth 1 https://github.com/jvns/pandas-cookbook.git /home/jovyan/featured/pandas-cookbook/

# Add Google Analytics templates
ADD common/ga/ /srv/ga/

RUN chown jovyan:jovyan /home/jovyan -R

## Final actions for user

USER jovyan

WORKDIR /home/jovyan/

# Install Julia kernel
RUN mkdir -p /home/jovyan/.ipython/kernels/julia/
RUN cp /srv/Julia/kernel.json /home/jovyan/.ipython/kernels/julia/kernel.json
RUN cp /srv/Julia/logo-64x64.png /home/jovyan/.ipython/kernels/julia/logo-64x64.png

# Example notebooks 
RUN cp -r /srv/ipython/examples /home/jovyan/ipython_examples

RUN chown -R jovyan:jovyan /home/jovyan

# Convert notebooks to the current format
RUN find . -name '*.ipynb' -exec ipython nbconvert --to notebook {} --output {} \;
RUN find . -name '*.ipynb' -exec ipython trust {} \;

CMD ipython3 notebook
