# Skywire Node Monitor

TODO: Write a description here

## Installation

TODO: Write installation instructions here

## Usage

TODO: Write usage instructions here

## Development

### Launch RethinkDB administration tool

1. With *docker*

    __replace *rethinkdb* by your docker instance name__

        xdg-open "http://$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' rethinkdb):8080"

2. With a local RethinkDB instance

        xdg-open "http://localhost:8080"

3. With a remote instance of RethinkDB

        xdg-open "https://my.domain.com:8080"

### Set `APP_RETHINKDB_URL` environment variable

Example:

    export APP_RETHINKDB_URL=rethinkdb://my.domain.com:28015/skywirenode_development

### Production database

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
