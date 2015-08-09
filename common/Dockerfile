# Base image of the IPython/Jupyter notebook, with conda
# Intended to be used in a tmpnb installation

FROM debian:jessie

MAINTAINER Jupyter Project <jupyter@googlegroups.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y git vim wget build-essential python-dev ca-certificates bzip2 libsm6 && apt-get clean

ENV CONDA_DIR /opt/conda

# Install conda for the jovyan user only (this is a single user container)
RUN echo 'export PATH=$CONDA_DIR/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-3.9.1-Linux-x86_64.sh && \
    /bin/bash /Miniconda3-3.9.1-Linux-x86_64.sh -b -p $CONDA_DIR && \
    rm Miniconda3-3.9.1-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes conda==3.10.1

# We run our docker images with a non-root user as a security precaution.
# jovyan is our user
RUN useradd -m -s /bin/bash jovyan
RUN chown -R jovyan:jovyan $CONDA_DIR

EXPOSE 8888

USER jovyan
ENV HOME /home/jovyan
ENV SHELL /bin/bash
ENV USER jovyan
ENV PATH $CONDA_DIR/bin:$PATH
WORKDIR $HOME

USER jovyan

RUN conda install --yes ipython-notebook terminado && conda clean -yt

RUN ipython profile create

# Workaround for issue with ADD permissions
USER root
ADD profile_default /home/jovyan/.ipython/profile_default
ADD templates/ /srv/templates/
RUN chmod a+rX /srv/templates
RUN chown jovyan:jovyan /home/jovyan -R
USER jovyan

# Expose our custom setup to the installed ipython (for mounting by nginx)
RUN cp /home/jovyan/.ipython/profile_default/static/custom/* /opt/conda/lib/python3.4/site-packages/IPython/html/static/custom/

# Convert notebooks to the current format
RUN find . -name '*.ipynb' -exec ipython nbconvert --to notebook {} --output {} \;
RUN find . -name '*.ipynb' -exec ipython trust {} \;

COPY pip.conf /home/jovyan/.config/pip/
COPY dexy.yaml dexy_requirements.txt /home/jovyan/notebooks/
# Run the ipython notebook from a python2 environment that we control
RUN conda create --name python2 python2 \
    source activate python2 \
    pip install -r dexy_requirements.txt \
    conda install -r environment.yml 
    
# Expose port used by Exercises/UI
EXPOSE 5000    

CMD ["bash", "run.sh; ipython notebook"] 
