# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/demo

MAINTAINER CognitiveScale <devops@cognitivescale.com>

USER root
RUN apt-get install -y nodejs npm && ln -s /usr/bin/nodejs /usr/bin/node

USER jovyan

CMD ["/bin/bash","-c","/home/jovyan//notebooks/CogU/run.sh && ipython notebook"]

