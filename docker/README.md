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
```
```sh
docker run -e DOCKER_IMAGE='serverspec-example' -e CONTAINER-NAME='test' --rm --volume /var/run/docker.sock:/var/run/docker.sock --volume $(pwd)/spec/localhost:/serverspec/spec/localhost -w /serverspec serverspec-example|tee a.log
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
### Examine

```sh
docker run -e DOCKER_IMAGE='serverspec-example' -e CONTAINER-NAME='test' -it --volume /var/run/docker.sock:/var/run/docker.sock --volume $(pwd)/spec/localhost:/serverspec/spec/localhost -w /serverspec serverspec-example /bin/ash
```
### Recycle
```sh
docker container prune -f
docker image ls -a | grep 'serverspec-example' 2>&1 | awk '{print $3}' | xargs -IX docker image rm -f X
docker image prune -f
```

### TODO:

Debug the error:
```js
{
  "errorDetail": {
    "message": "ADD failed: stat /var/lib/docker/tmp/docker-builder326715086/data.json: no such file or directory"
  },
  "error": "ADD failed: stat /var/lib/docker/tmp/docker-builder326715086/data.json
```
from adding a
```sh
# ADD "data.json" "${sampledir}/data.json"
# ADD "data.xml" "${sampledir}/data.xml"
```
while the files are present and the container shows them copied. The error only affects serverspec run.

### Note
Warning if the directory links  are used on the host, they will most likely point to nowhere in the container.
### See Also

 * [](https://github.com/iBossOrg/docker-dockerspec/blob/master/Dockerfile)
 * [](https://docs.docker.com/engine/reference/builder/)
