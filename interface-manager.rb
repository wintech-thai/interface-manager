require 'sinatra'
require 'json'

set :bind, '0.0.0.0'
set :port, 8080

set :protection, :except => :host_header

set :host_authorization, {
  permitted_hosts: []
}

STATE_FILE = "/data/state.json"

# -----------------------------
# State persistence
# -----------------------------

def load_state
  if File.exist?(STATE_FILE)
    JSON.parse(File.read(STATE_FILE))
  else
    {"disabled" => []}
  end
end

def save_state(state)
  File.write(STATE_FILE, JSON.pretty_generate(state))
end

STATE = load_state

# -----------------------------
# Interface discovery
# -----------------------------

def physical_interfaces
  Dir.entries("/sys/class/net").select do |iface|
    next if iface == "." || iface == ".." || iface == "lo"
    File.directory?("/sys/class/net/#{iface}/device")
  end
end

# -----------------------------
# Interface info helpers
# -----------------------------

def mac_address(iface)
  File.read("/sys/class/net/#{iface}/address").strip
end

def ip_addresses(iface)
  json = `ip -j addr show #{iface}`
  data = JSON.parse(json)

  data[0]["addr_info"]
    .select { |a| a["family"] == "inet" }
    .map { |a| a["local"] }
end

def iface_stats(iface)
  base = "/sys/class/net/#{iface}/statistics"

  {
    rx_bytes: File.read("#{base}/rx_bytes").to_i,
    tx_bytes: File.read("#{base}/tx_bytes").to_i,
    rx_packets: File.read("#{base}/rx_packets").to_i,
    tx_packets: File.read("#{base}/tx_packets").to_i
  }
end

def interface_info(iface)
  {
    name: iface,
    mac: mac_address(iface),
    ip: ip_addresses(iface),
    stats: iface_stats(iface)
  }
end

# -----------------------------
# API endpoints
# -----------------------------

# interfaces available for capture
get '/interfaces' do
  enabled = physical_interfaces.reject { |i| STATE["disabled"].include?(i) }

  result = enabled.map { |i| interface_info(i) }

  content_type :json
  {interfaces: result}.to_json
end

# raw traffic counters
get '/interfaces/stats' do
  result = physical_interfaces.map do |iface|
    {
      name: iface,
      stats: iface_stats(iface)
    }
  end

  content_type :json
  {interfaces: result}.to_json
end

# simple activity indicator
get '/interfaces/activity' do
  result = physical_interfaces.map do |iface|
    stats = iface_stats(iface)

    {
      name: iface,
      has_traffic: stats[:rx_packets] > 0
    }
  end

  content_type :json
  {interfaces: result}.to_json
end

# disable interface
post '/interfaces/:name/disable' do
  name = params["name"]

  unless STATE["disabled"].include?(name)
    STATE["disabled"] << name
    save_state(STATE)
  end

  content_type :json
  {status: "ok", disabled: STATE["disabled"]}.to_json
end

# enable interface
post '/interfaces/:name/enable' do
  name = params["name"]

  STATE["disabled"].delete(name)
  save_state(STATE)

  content_type :json
  {status: "ok", disabled: STATE["disabled"]}.to_json
end

# debug endpoint
get '/interfaces/all' do
  result = physical_interfaces.map { |i| interface_info(i) }

  content_type :json
  {
    interfaces: result,
    disabled: STATE["disabled"]
  }.to_json
end

# enabled interfaces (plain text for zeek)
get '/interfaces/enabled' do
  enabled = physical_interfaces.reject { |i| STATE["disabled"].include?(i) }

  content_type "text/plain"
  enabled.join("\n")
end

# health check
get '/healthz' do
  content_type :json
  {status: "ok"}.to_json
end
