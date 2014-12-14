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

# jovyan is our user
RUN useradd -m -s /bin/bash jovyan

USER jovyan
RUN ipython profile create

# IJulia installation
RUN julia -e 'Pkg.add("IJulia")'
# Julia packages
RUN julia -e 'Pkg.add("Gadfly")'
RUN julia -e 'Pkg.add("RDatasets")'

# R installation
RUN echo 'R_LIBS_USER=~/.R:/usr/lib/R/site-library' > /home/jovyan/.Renviron
RUN echo 'options(repos=structure(c(CRAN="http://cran.rstudio.com")))' > /home/jovyan/.Rprofile
RUN mkdir /home/jovyan/.R/
RUN echo "install.packages(c('ggplot2', 'XML', 'plyr', 'randomForest', 'Hmisc', 'stringr', 'RColorBrewer', 'reshape', 'reshape2'))" | R --no-save

# Workaround for issue with ADD permissions
USER root
ADD common/ipython_notebook_config.py /home/jovyan/.ipython/profile_default/

# All the additions to give to the created user.
ADD kernels/Julia/ /srv/Julia/
ADD kernels/R/ /srv/R/
ADD notebooks/ /home/jovyan/

# Add Google Analytics templates
ADD common/ga/ /srv/ga/

RUN chmod a+rX /srv/R/ -R
RUN chown jovyan:jovyan /home/jovyan -R

## Final actions for user

USER jovyan
ENV HOME /home/jovyan
ENV SHELL /bin/bash
ENV USER jovyan

WORKDIR /home/jovyan/

# Install Julia kernel
RUN mkdir -p /home/jovyan/.ipython/kernels/julia/
RUN cp /srv/Julia/kernel.json /home/jovyan/.ipython/kernels/julia/kernel.json

# Install R kernel
RUN cat /srv/R/install_kernel.R | R --no-save

# Example notebooks 
RUN cp -r /srv/ipython/examples /home/jovyan/ipython_examples

RUN chown -R jovyan:jovyan /home/jovyan

RUN find . -name '*.ipynb' -exec ipython trust {} \;

CMD ipython3 notebook
