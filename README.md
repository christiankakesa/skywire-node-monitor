# Skywire Node Monitor

This program store the number of available Skywire nodes in world over the time.

## Installation

You have to install crystal for your operating system: https://crystal-lang.org/docs/installation/

## Set environment variables

    export APP_DB_HOST=localhost
    export APP_DB_NAME=test
    export APP_DB_PASSWORD=xxxxxxxxxx
    export APP_DB_PORT=28015
    export APP_DB_TABLE_NAME=nodes_metrics
    export APP_DB_USER=skywirenode
    export APP_DISCOVERY_QUERY="/conn/getAll"
    export APP_DISCOVERY_URI="http://discovery.skycoin.net:8001"
    export APP_TICK_TIME_SECOND=300

## Usage

    shards build --production ./bin/skywire-node-monitor

## Development

### Launch RethinkDB administration tool

First of all, you need a RethinkDB datastore: https://rethinkdb.com/docs/install/.

You can deploy an instance on cloud provider like AWS or Compose: https://rethinkdb.com/docs/paas/

1. With *docker*

    __replace *rethinkdb* by your docker instance name__

        xdg-open "http://$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' rethinkdb):8080"

2. With a local RethinkDB instance

        xdg-open "http://localhost:8080"

3. With a remote instance of RethinkDB

        xdg-open "https://my.domain.com:8080"

### Configure the database

    r.db('rethinkdb').table('users').insert({id: 'skywirenode', password: 'xxxxxxxxxxxxxxxxxxxxxxx'});
    r.dbCreate('skywirenode_production');
    r.db('skywirenode_production').grant('skywirenode', {read: true, write: true, config: true});

## Contributing

1. Fork it (<https://github.com/fenicks/skywire-node-monitor/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [fenicks](https://github.com/fenicks) Christian Kakesa - creator, maintainer
