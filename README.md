Docker Demo Images
==================

Herein lies the Dockerfiles for both [`jupyter/demo`](https://registry.hub.docker.com/u/jupyter/demo/) (currently used by [tmpnb.org](https://tmpnb.org)) and [`jupyter/minimal`](https://registry.hub.docker.com/u/jupyter/minimal/).

Creating sample notebooks does not require knowledge of Docker, just the IPython/Jupyter notebook. Submit PRs against the notebooks/ folder to get started.

### Organization

The big demo image pulls in resources from

* `kernels/` to install dependencies for R and Juila
* `notebooks/` for example notebooks
* `common/` for core components used by `minimal` and `demo`

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
