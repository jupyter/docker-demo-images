# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/minimal

MAINTAINER Jupyter Project <jupyter@googlegroups.com>

USER root

# Julia dependencies
RUN apt-get install -y julia libnettle4

# R dependencies that conda can't give us
RUN apt-get install -y libxrender1 fonts-dejavu

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
RUN conda install --yes numpy pandas scikit-learn matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle numba bokeh

# R packages
RUN conda config --add channels r
RUN conda install --yes r-irkernel r-plyr r-devtools r-rcurl r-dplyr r-ggplot2 r-caret
RUN echo "library(devtools); install_github('jimhester/robustr')" | R --no-save

# IJulia and Julia packages
RUN julia -e 'Pkg.add("IJulia")'
RUN julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")'

# Featured notebooks
RUN git clone --depth 1 https://github.com/jvns/pandas-cookbook.git /home/jovyan/featured/pandas-cookbook/

# Convert notebooks to the current format
RUN find . -name '*.ipynb' -exec ipython nbconvert --to notebook {} --output {} \;
RUN find . -name '*.ipynb' -exec ipython trust {} \;

CMD ipython notebook
