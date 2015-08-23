# Base image of the IPython/Jupyter notebook, with conda
# Intended to be used in a tmpnb installation

FROM debian:jessie

MAINTAINER Jupyter Project <jupyter@googlegroups.com>

ENV DEBIAN_FRONTEND noninteractive

RUN  apt-get update && apt-get install -y git vim wget build-essential python-dev ca-certificates bzip2 libsm6 nodejs npm && apt-get clean

USER root

ENV CONDA_DIR=/opt/conda \
    COGU_HOME=/home/jovyan/notebooks/CogU

# Install conda for the jovyan user only (this is a single user container)

RUN echo 'export PATH=$CONDA_DIR/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-3.9.1-Linux-x86_64.sh && \
    /bin/bash /Miniconda3-3.9.1-Linux-x86_64.sh -b -p $CONDA_DIR && \
    rm Miniconda3-3.9.1-Linux-x86_64.sh 
RUN ls -al $CONDA_DIR 
RUN $CONDA_DIR/bin/conda install --yes conda

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
# Hack to configure nodejs binary mapping
RUN chown jovyan:jovyan /home/jovyan -R && \
    ln -s /usr/bin/nodejs /usr/bin/node 
USER jovyan

# Expose our custom setup to the installed ipython (for mounting by nginx)
RUN cp /home/jovyan/.ipython/profile_default/static/custom/* /opt/conda/lib/python3.4/site-packages/IPython/html/static/custom/

# Convert notebooks to the current format
RUN find . -name '*.ipynb' -exec ipython nbconvert --to notebook {} --output {} \;
RUN find . -name '*.ipynb' -exec ipython trust {} \;

# We need pip.conf for artifactory creds, but prefer not to put creds in git repo.
# COPY pip.conf /home/jovyan/.config/pip/
# COPY dexy.yaml dexy_requirements.txt  /home/jovyan/notebooks/

# Run the ipython notebook from a python2 environment that we control
# Install publically available packages here, private once in run.sh after pip.conf is available

# Python packages
RUN conda install --yes numpy pandas scikit-learn scikit-image matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle dill bokeh && conda clean -yt

# Now for a python2 environment
RUN conda create -p $CONDA_DIR/envs/python2 python=2.7 ipython numpy pandas \ 
                    scikit-learn scikit-image matplotlib scipy seaborn sympy \
                    cython patsy statsmodels cloudpickle dill numba bokeh && \ 
    conda clean -yt 

RUN $CONDA_DIR/envs/python2/bin/python  $CONDA_DIR/envs/python2/bin/ipython kernelspec install-self --user 
RUN pip install bash_kernel && \
    python -m bash_kernel.install

# Featured notebooks
RUN git clone --depth 1 https://github.com/jvns/pandas-cookbook.git /home/jovyan/featured/pandas-cookbook/

CMD ["/bin/bash","-c","/jupyter_scripts/run.sh $COGU_HOME && ipython notebook"]
