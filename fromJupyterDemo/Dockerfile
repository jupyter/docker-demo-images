# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/demo

MAINTAINER CognitiveScale <devops@cognitivescale.com>

ENV COGU_HOME=/home/jovyan/notebooks/CogU \
    JUPYTER_SCRIPTS=/jupyter_scripts


USER root
RUN mkdir $JUPYTER_SCRIPTS 
ADD dexy.yaml dexy_requirements.txt run.sh j2cli.sh setup_git_filters.sh $JUPYTER_SCRIPTS/ 
ADD page.html /srv/templates/page.html

RUN chown -R jovyan:jovyan $JUPYTER_SCRIPTS && \
    chown -R jovyan:jovyan /home/jovyan && \
    apt-get -y install nodejs npm && \
    ln -s /usr/bin/nodejs /usr/bin/node 

USER jovyan


RUN $CONDA_DIR/envs/python2/bin/pip install -r $JUPYTER_SCRIPTS/dexy_requirements.txt
# Install bash_kernel to python front end
RUN python -m bash_kernel.install

USER jovyan

CMD ["/bin/bash","-c","$JUPYTER_SCRIPTS/run.sh && ipython notebook"]

