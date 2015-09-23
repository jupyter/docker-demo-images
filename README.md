Docker Demo Image
=================

[![Join the chat at https://gitter.im/jupyter/docker-demo-images](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jupyter/docker-demo-images?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Herein lies the Dockerfile for [`jupyter/demo`](https://registry.hub.docker.com/u/jupyter/demo/), the container image currently used by [tmpnb.org](https://tmpnb.org)). It inherits from [`jupyter/minimal-notebook`](https://registry.hub.docker.com/u/jupyter/minimal-notebook/), the base image defined in [`jupyter/docker-stacks`](https://github.com/jupyter/docker-stacks).

Creating sample notebooks does not require knowledge of Docker, just the IPython/Jupyter notebook. Submit PRs against the `notebooks/` folder to get started.

### Organization

The big demo image pulls in resources from:

* `notebooks/` for example notebooks
* `datasets/` for example datasets
* `resources/` for configuration and branding

### Community Notebooks

[tmpnb.org](https://tmpnb.org) is a great resource for communities
looking for a place to host their public IPython/Jupyter notebooks.  If
your group has a notebook you want to share, just fork this repository
and add a directory for your community in the `notebooks/communities` folder
and place your notebook in the new directory
(e.g. `notebooks/communities/north_pole_julia_group/`).  Commit and push
your changes to Github and send us a pull request.

The following tips will make sure your notebooks work well on
[tmpnb.org](https://tmpnb.org) and work well for the users of your
notebook.

* Create your notebook using Jupyter Notebook 4.x to ensure your notebook is `v4` format.
* If adding a notebook that was a slideshow, make sure to set the "Cell Toolbar" setting back to `None`.
* If you are creating your notebook on [tmpnb.org](https://tmpnb.org), make sure you're aware of the 10 minute idle time notebook reaper.  If you walk away from your notebook for too long, you can lose it!

### Building the Docker Image

There is a Makefile to make life a bit easier here:

```
# build it
make build
# try it locally
make dev
```
