################################### REQUIRES ###################################

rimraf = require 'rimraf'
fs = require 'fs'
mkdirp = require 'mkdirp'
optimist = require 'optimist'

{
  Seed
  sjcl
  Base
  Wallet
} = require 'ripple-lib'

#################################### HELPERS ###################################

banner = (n, c) -> new Array(n+1).join(c)

validation_create = (from_json_able) ->
  seed = Seed.from_json(from_json_able)
  encodedSeed = seed.to_json()

  bytes = (new Wallet(encodedSeed).getPublicGenerator()
                                  .value.toBytesCompressed())
  pub = Base.encode_check(28, bytes)

  seed: encodedSeed
  public_key: pub


create_ini = (struct) ->
  lines = []

  add_value = (v, d=0) ->
    if typeof v in ['string', 'number', 'boolean']
      lines.push(v)
    else if Array.isArray(v) and d == 0
      add_value(e, d+1) for e in v
    else if typeof v == 'object' and d == 0
      for kk, vv of v
        lines.push("#{kk}=#{vv}")

  for k,v of struct
    lines.push("[#{k}]")
    add_value v
    lines.push('')

  lines.join('\n')

config = (name, port_offset, peers) ->
  port_offset *= 3 # we have two ports
  validator_keys = validation_create(name)

  struct =
    validation_public_key: validator_keys.public_key
    validation_seed: validator_keys.seed
    node_seed: validator_keys.seed

    validation_quorum: 3

    node_db:
      type: 'memory'

    server : ['port_peer', 'port_ws', 'port_http']
    peer_private: 1

    node_size: 'medium'

    database_path: __dirname + '/' + name

    port_peer:
      ip: '127.0.0.1'
      port: 7550 + port_offset
      protocol: 'peer'

    port_http:
      ip: '127.0.0.1'
      port: 7551 + port_offset
      admin: 'allow'
      protocol: 'http'

    # rpc_startup: '{ "command": "log_level", "severity": "trace" }'

    port_ws:
      ip: '127.0.0.1'
      port: 7552 + port_offset
      admin: 'allow'
      protocol: 'ws'

  struct

find_peer_ports = (peers_conf) ->
  ([name, conf.port_peer.port] for name, conf of peers_conf)

find_validators = (peers_conf) ->
  ([name, conf.validation_public_key] for name, conf of peers_conf)

add_fixed_ips = (peer_ports, peers_conf) ->
  for [name, port] in peer_ports
    for n, peer_conf of peers_conf when n != name
      # if not peer_conf.ips?
      #   [leader_name, leader_port] = peer_ports[0]
      (peer_conf.ips ?= []).push "# #{name}\n127.0.0.1 #{port}"

      ips_fixed = peer_conf.ips_fixed ?= []
      ips_fixed.push("# #{name}\n127.0.0.1 #{port}")

add_validators = (validators, peers_conf) ->
  for [name, public_key] in validators
    for n, peer_conf of peers_conf when n != name
      console.log(name, public_key)
      (peer_conf.validators ?= []).push("#{public_key} #{name}")

create_peers = (n) ->
  peers = {}

  for p in [0 ... n]
    name = "N#{p}"
    peers[name] = config(name, p)

  peer_ports = find_peer_ports(peers)
  validators = find_validators(peers)

  add_fixed_ips(peer_ports, peers)
  add_validators(validators, peers)

  peers

dump_peer = (p, conf) ->
  rimraf p, (e) ->

    mkdirp "#{p}/db", (e) ->
      fs.writeFileSync("#{p}/rippled.cfg", conf)
      console.log banner(80, '#')
      console.log '#'+ p
      console.log(conf)

for p, s of create_peers(15)
  dump_peer(p, create_ini s)