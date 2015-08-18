# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/demo

MAINTAINER CognitiveScale <devops@cognitivescale.com>

USER jovyan

#COPY dexy.yaml dexy_requirements.txt environment.yml /home/jovyan/notebooks/

RUN /bin/bash -c "source activate python2"
# && pip install -r notebooks/dexy_requirements.txt"

CMD ["/bin/bash","-c","/home/jovyan//notebooks/CogU/run.sh && ipython notebook"]

