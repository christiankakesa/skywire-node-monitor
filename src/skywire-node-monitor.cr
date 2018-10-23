require "awesome-logger"
require "http/client"
require "crystal-rethinkdb"
require "pool/connection"

# Structure of RethinkDB tables
#
# # nodes_metrics
# + name: [skycoin]
# + timestamp_minute
# + type: [num_of_nodes]
# + values: Hash(String, JSON::Any)

module SkywireNodeMonitor
  VERSION = "0.1.0"

  class Node
    JSON.mapping(
      key: String,
      type: String,
      send_bytes: UInt64,
      recv_bytes: UInt64,
      last_ack_time: UInt64,
      start_time: UInt64
    )
  end

  alias Nodes = Array(Node)

  class App
    include RethinkDB::Shortcuts

    DB_HOST          = ENV.fetch("APP_DB_HOST", "localhost")
    DB_NAME          = ENV.fetch("APP_DB_NAME", "test")
    DB_PASSWORD      = ENV.fetch("APP_DB_PASSWORD", "xxxxxxxxxx")
    DB_PORT          = ENV["APP_DB_PORT"]?.try(&.to_i32) || 28015
    DB_TABLE_NAME    = ENV.fetch("APP_DB_TABLE_NAME", "nodes_metrics")
    DB_USER          = ENV.fetch("APP_DB_USER", "skywirenode")
    DISCOVERY_QUERY  = ENV.fetch("APP_DISCOVERY_QUERY", "/conn/getAll")
    DISCOVERY_URI    = ENV.fetch("APP_DISCOVERY_URI", "http://discovery.skycoin.net:8001")
    TICK_TIME_SECOND = ENV["APP_TICK_TIME_SECOND"]?.try(&.to_i32) || 10

    @@rpool : ConnectionPool(RethinkDB::Connection) = ConnectionPool.new(capacity: 10, timeout: 0.1) do
      RethinkDB.connect(host: DB_HOST, port: DB_PORT, db: DB_NAME, user: DB_USER, password: DB_PASSWORD)
    end
    @@rpool.connection do |conn|
      begin
        RethinkDB.db(DB_NAME).table_create(DB_TABLE_NAME).run(conn) unless RethinkDB.db(DB_NAME).table_list.run(conn).includes?(DB_TABLE_NAME)
        RethinkDB.db(DB_NAME).table(DB_TABLE_NAME).index_create("timestamp_minute").run(conn) unless RethinkDB.db(DB_NAME).table(DB_TABLE_NAME).index_list.run(conn).includes?("timestamp_minute")
      rescue ex : RethinkDB::ReqlRunTimeError
        L.w "#{ex.message}"
      end
    end

    @@hpool : ConnectionPool(HTTP::Client) = ConnectionPool.new(capacity: 5, timeout: 0.1) do
      HTTP::Client.new(URI.parse(DISCOVERY_URI))
    end

    def run
      while true
        @@hpool.connection do |http|
          http.exec(HTTP::Request.new("GET", DISCOVERY_QUERY)) do |response|
            if response.status_code == 200
              json_str = response.body_io.gets
              if json_str && !json_str.strip.empty?
                spawn write_stats(json_str)
                sleep TICK_TIME_SECOND
              else
                L.w "[ERROR - HTTP RESPONSE]: empty"
                sleep 1
              end
            else
              L.w "[ERROR - HTTP STATUS CODE]: #{response.status_code}"
              sleep 1
            end
          end
        end
      end
    end

    def write_stats(json_str : String)
      # Exeample (MongoDB): https://www.mongodb.com/blog/post/schema-design-for-time-series-data-in-mongodb
      # hour
      return if json_str.strip.empty?
      now = Time.utc_now
      current_minute_ts = now.at_beginning_of_minute.epoch
      nodes = Nodes.from_json(json_str)
      @@rpool.connection do |conn|
        if r.db(DB_NAME).table(DB_TABLE_NAME).filter({timestamp_minute: r.epoch_time(current_minute_ts),
                                                      type:             "num_of_nodes"}).run(conn).size > 0
          r.db(DB_NAME).table(DB_TABLE_NAME).filter({timestamp_minute: r.epoch_time(current_minute_ts),
                                                     type:             "num_of_nodes"}).update { |metrics|
            {
              num_samples:   metrics["num_samples"] + 1,
              total_samples: metrics["total_samples"] - metrics["values"]["#{now.second}"].default(0) + nodes.size,
              values:        {
                "#{now.second}" => nodes.size,
              },
            }
          }.run(conn)
        else
          r.db(DB_NAME).table(DB_TABLE_NAME).insert({
            name:             "skycoin",
            timestamp_minute: r.epoch_time(current_minute_ts),
            type:             "num_of_nodes",
            num_samples:      1,
            total_samples:    nodes.size,
            values:           {
              "#{now.second}" => nodes.size,
            },
          }).run(conn)
        end
      end
      L.i "TS: #{now} - Number of nodes: #{nodes.size}"
    end
  end
end

SkywireNodeMonitor::App.new.run
