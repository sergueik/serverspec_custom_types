### Info

This directory contains a `Dockerfile` and helpers derived from [](https://github.com/operep/docker-serverspec) project and [](https://github.com/iBossOrg/docker-dockerspec).

### Build

```sh
docker build -f Dockerfile -t serverspec-example .
```

### Use
```sh
docker run -e CONTAINER_NAME=test_container --rm --volume /var/run/docker.sock:/var/run/docker.sock --volume $(pwd)/spec/localhost:/serverspec/spec/localhost -w /serverspec serverspec-example
```
```sh
export DOCKER_IMAGE=serverspec-example
export CONTAINER_NAME=serverspe-example


docker run -e DOCKER_IMAGE='serverspec-example' -e CONTAINER-NAME='test' --rm --volume /var/run/docker.sock:/var/run/docker.sock --volume $(pwd)/spec/localhost:/serverspec/spec/localhost -w /serverspec serverspec-example
```

You will observe one failing spec examines the committed images to find the one named

```sh
Failures:

  1) Dockerfile Docker image "serverspec-example" is expected to exist
```
Unclear, how to make *this* test pass (found that even committing the container to save the image does not help
```
docker commit 881bce4c82e4 serverspec-example
```
### Errors

If the error 
```sh
Docker::Error::NotFoundError:
No such container: test_container
```
is seen, need to  recycle the containers

### Recycle
```sh
docker container prune -f
docker image ls -a | grep 'serverspec-example' 2>&1 | awk '{print $3}' | xargs -IX docker image rm -f X
docker image prune -f
```
### Note
Warning if the directory links  are used on the host, they will most likely point to nowhere in the container.
### See Also

 * [](https://github.com/iBossOrg/docker-dockerspec/blob/master/Dockerfile)
 * [](https://docs.docker.com/engine/reference/builder/)
