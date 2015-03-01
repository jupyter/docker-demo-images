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

# Julia and R Installation
RUN apt-get install software-properties-common python-software-properties -y && \
    add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" && \
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
    gpg -a --export E084DAB9 | apt-key add - && \
    add-apt-repository ppa:staticfloat/juliareleases && \
    add-apt-repository ppa:staticfloat/julia-deps && \
    apt-get update && \
    apt-get install julia -y && \
    apt-get install libnettle4 && \
    apt-get install -y r-base r-base-dev r-cran-rcurl libreadline-dev && \
    pip2 install rpy2 && pip3 install rpy2

EXPOSE 8888

# We run our docker images with a non-root user as a security precaution.
# jovyan is our user
RUN useradd -m -s /bin/bash jovyan

USER jovyan
ENV HOME /home/jovyan
ENV SHELL /bin/bash
ENV USER jovyan

RUN ipython profile create && mkdir /home/jovyan/communities && mkdir /home/jovyan/featured

# IJulia installation
RUN julia -e 'Pkg.add("IJulia")'
# Julia packages
RUN julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")'

# R installation
RUN mkdir /home/jovyan/.R/
RUN echo 'R_LIBS_USER=/home/jovyan/.R:/usr/lib/R/site-library' > /home/jovyan/.Renviron
RUN echo 'options(repos=structure(c(CRAN="http://cran.rstudio.com")))' > /home/jovyan/.Rprofile
RUN echo "PKG_CXXFLAGS = '-std=c++11'" > /home/jovyan/.R/Makevars
RUN echo "install.packages(c('ggplot2', 'XML', 'plyr', 'randomForest', 'Hmisc', 'stringr', 'RColorBrewer', 'reshape', 'reshape2'))" | R --no-save
RUN echo "install.packages(c('RCurl', 'devtools', 'dplyr'))" | R --no-save
RUN echo "install.packages(c('httr', 'knitr', 'packrat'))" | R --no-save
RUN echo "install.packages(c('rmarkdown', 'rvtest', 'testit', 'testthat', 'tidyr', 'shiny'))" | R --no-save
RUN echo "library(devtools); install_github('armstrtw/rzmq'); install_github('takluyver/IRdisplay'); install_github('takluyver/IRkernel'); IRkernel::installspec()" | R --no-save
RUN echo "library(devtools); install_github('hadley/lineprof')" | R --no-save
RUN echo "library(devtools); install_github('rstudio/rticles')" | R --no-save
RUN echo "library(devtools); install_github('jimhester/covr')" | R --no-save

RUN echo "install.packages(c('base64enc', 'Cairo', 'codetools', 'data.table', 'gridExtra', 'gtable', 'hexbin', 'jpeg', 'Lahman', 'lattice'))" | R --no-save
RUN echo "install.packages(c('MASS', 'PKI', 'png', 'microbenchmark', 'mgcv', 'mapproj', 'maps', 'maptools', 'mgcv', 'multcomp', 'nlme'))" | R --no-save
RUN echo "install.packages(c('nycflights13', 'quantreg', 'rJava', 'roxygen2', 'RSQLite', 'XML'))" | R --no-save

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
