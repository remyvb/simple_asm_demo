# Demo Puppet implementation

This repo contains a demonstration of a simple database installation. It contains no patches and hardly any setup inside of the database (e.g. tablespaces, users, synomyms). It's purpose is to help you guide through an initial installation of an Oracle node with Puppet.

## Starting the nodes masterless

All nodes are available to test with Puppet masterless. To do so, add `ml-` for the name when using vagrant:

```
$ vagrant up <ml-asm112|ml-asm121|ml-asm122>
```

## Staring the nodes with PE

You can also test with a Puppet Enterprise server. To do so, add `pe-` for the name when using vagrant:

```
$ vagrant up pe-asmmaster
$ vagrant up <pe-asm112|pe-asm121|pe-asm122>
```

## ordering

You must always use the specified order:

1. asmmaster
2. <asm112|asm121|asm122>

## Required software

The software must be placed in `modules/software/files`. It must contain the next files:

### Puppet Enterprise
- puppet-enterprise-2016.5.1-el-7-x86_64.tar.gz (Extracted tar)

You can download this file from
[here](https://pm.puppetlabs.com/cgi-bin/download.cgi?dist=el&rel=7&arch=x86_64&ver=2016.5.1)


### Oracle Database
- linuxx64_12201_database.zip
- linuxx64_12201_grid_home.zip

You can download these files from [here](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/oracle12c-linux-12201-3608234.html)
