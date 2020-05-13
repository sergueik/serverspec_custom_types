### Info
This directory contains fragment of the yaml-mapped shallow directory set [serverspec project](https://github.com/Uki884/serverspec)
### Usage
```sh
rake serverspec
```
or presumably
```sh
rake serverspec:all prod
```
but the latter does not run clean: in addition to loading `conf/prod.yaml` it also tries to run `prod` as a rake target:
```sh
rake aborted!
Don't know how to build task 'prod' (see --tasks)
```
