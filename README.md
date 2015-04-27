Docker Demo Images
==================

[![Join the chat at https://gitter.im/jupyter/docker-demo-images](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jupyter/docker-demo-images?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Herein lies the Dockerfiles for both [`jupyter/demo`](https://registry.hub.docker.com/u/jupyter/demo/) (currently used by [tmpnb.org](https://tmpnb.org)) and [`jupyter/minimal`](https://registry.hub.docker.com/u/jupyter/minimal/).

Creating sample notebooks does not require knowledge of Docker, just the IPython/Jupyter notebook. Submit PRs against the notebooks/ folder to get started.

### Organization

The big demo image pulls in resources from

* `notebooks/` for example notebooks
* `common/` for core components used by `minimal` and `demo`

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

* Create your notebook using IPython 3.x to ensure your notebook is `v4` format.
* If adding a notebook that was a slideshow, make sure to set the "Cell Toolbar" setting back to `None`.
* If you are creating your notebook on [tmpnb.org](https://tmpnb.org), make sure you're aware of the 10 minute idle time notebook reaper.  If you walk away from your notebook for too long, you can lose it!


### Building the Docker Images

There is a Makefile to make life a bit easier here:

```
make images
```

Alternatively, feel free to build them directly:

#### `jupyter/demo`

```
docker build -t jupyter/demo .
```

#### `jupyter/minimal`

```
docker build -t jupyter/minimal common/
```

