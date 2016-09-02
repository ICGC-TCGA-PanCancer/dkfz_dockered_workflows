Grid-Engine Role
----------------

This role sets up SGE in two ways, either as a master or as a worker. This role provides some examples of how to create idempotent tasks when the underlying software is not designed for it. 

Also note that the master is setup with a worker on the same node when the single\_node variable is set (i.e. when you're working only with one node, you are forced to setup a worker on the master even though it is not ideal). 
