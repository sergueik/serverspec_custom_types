### Info

Collection of over 150 custom serverspec snipets for Windows and over 200 custom serverspec snippets for Unix designed to examine complex configurations produced by Chef Puppet or Ansible for which the standard resources are not sufficient.

These can be added to provision pipeline via [vagrant-serverspeci](https://github.com/vvchik/vagrant-serverspec) or run on the target instance within some sort of standalone Ruby environment (which is usually chosen to leave the target system system Ruby-clean) through
[rvm](https://rvm.io/), 
[scl](https://www.softwarecollections.org/en/scls/rhscl/rh-ruby23/) or [Uru Serverspec](https://github.com/sergueik/uru_serverspec)

Quite often (especially in windows case) a serverspec test later
becomes ia custom Puppet fact / Chef ohai fact evaluating version or state of its target application or becomes an `unless` `onlyif` condition on some resource managing the same for [idempotency](https://en.wikipedia.org/wiki/Idempotence) of the provision

The extraction of the approprtate repository part out of the parent [sergueik/puppetmaster_vagrant](https://github.com/sergueik/puppetmaster_vagrant/tree/master/facts) is a work in progress

Porting to [inspec](https://github.com/inspec/inspec) semantics is a work in progess and is unlikely to cause any problem.

Exampes of integrated Vagrantfile are in the parent repository [sergueik/puppetmaster_vagrant](https://github.com/sergueik/puppetmaster_vagrant).

There is some overlap with [sampler](https://github.com/sqshq/sampler) [recipes](https://github.com/sqshq/sampler#real-world-recipes)

### Author
[Serguei Kouzmine](kouzmine_serguei@yahoo.com)
