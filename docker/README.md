### Info

This directory contains a `Dockerfile` and helpers derived from [](https://github.com/operep/docker-serverspec) project and [](https://github.com/iBossOrg/docker-dockerspec) and [ikauzak/dockerfile_tdd](https://github.com/ikauzak/dockerfile_tdd).

### Build
* name the image
```sh
export DOCKER_IMAGE=serverspec-image
export CONTAINER_NAME=serverspec-example
```
* build the image
```sh
docker build -f Dockerfile -t $DOCKER_IMAGE .
```

### Use

* run
```sh
export DEBUG=true
docker run -e CONTAINER_NAME=$CONTAINER_NAME -e DEBUG=$DEBUG --rm --volume /var/run/docker.sock:/var/run/docker.sock --volume $(pwd)/spec/localhost:/serverspec/spec/localhost -w /serverspec $DOCKER_IMAGE 2>&1 |tee a.log
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
docker run -it --volume /var/run/docker.sock:/var/run/docker.sock --volume $(pwd)/spec/localhost:/serverspec/spec/localhost -w /serverspec $CONTAINER_NAME /bin/ash
```
### Recycle
```sh
docker container prune -f
docker image ls -a | grep $DOCKER_IMAGE 2>&1 | awk '{print $3}' | xargs -IX docker image rm -f X
docker image prune -f
docker system prune -f
```
### Note
Soft directory links will be meaningless in the mapped directory inside container.

### LEGACY:

Debug the error in older version:
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


### See Also

 * [iBossOrg/docker-dockerspec](https://github.com/iBossOrg/docker-dockerspec/blob/master/Dockerfile)
 * [Docker documentation](https://docs.docker.com/engine/reference/builder/)
