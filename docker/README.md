### Build

```sh
docker build -f Dockerfile -t serverspec-example .
```
### Use
```sh
docker run --rm --volume /var/run/docker.sock:/var/run/docker.sock --volume $(pwd)/spec/localhost:/serverspec/spec/localhost -w /serverspec serverspec-example
```
### Recycle
```sh
docker image  ls -a | grep 'serverspec-example' 2>&1 | awk '{print $3}' | xargs -IX docker image rm -f X
docker image prune -f
```
### Note
Warning if the directory links  are used on the host, they will most likely point to nowhere in the container.
### See Also

 * [](https://github.com/iBossOrg/docker-dockerspec/blob/master/Dockerfile)
 * [](https://docs.docker.com/engine/reference/builder/)
