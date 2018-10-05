### Info

Custom serverspec snippet collection for Windows and Unix. 

These snippets turn out helpful for integration testing on complex application stacks provisioned by Puppet, Chef etc.

These can be added to provision pipeline via [vagrant-serverspeci](https://github.com/vvchik/vagrant-serverspec) or run on the target instance within some sort of standalone Ruby environment (which is usually chosen to leave the target system system Ruby-absent) through
[rvm](https://rvm.io/), 
[scl](https://www.softwarecollections.org/en/scls/rhscl/rh-ruby23/) or [Uru Serverspec](https://github.com/sergueik/uru_serverspec)

Quite often (especially in windows case) a serverspec test later
becomes custom Puppet fact evaluating version or state of its target application or becomes an `unless` `onlyif` condition on some resource managing the same.

The extraction of the approprtate repository part out of the parent [sergueik/puppetmaster_vagrant](https://github.com/sergueik/puppetmaster_vagrant/tree/master/facts) is a work in progress

Porting to [inspec](https://github.com/inspec/inspec) semantics is a work in progess and is unlikely to cause any problem.

Exampes of integrated Vagrantfile are in the parent repository [sergueik/puppetmaster_vagrant](https://github.com/sergueik/puppetmaster_vagrant).

### Author
[Serguei Kouzmine](kouzmine_serguei@yahoo.com)
