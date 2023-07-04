#!/bin/bash 

### Server IP of Grafana/Prometheus Instance
MONITORING_SERVER=192.168.1.1

### Allow Grafana Instance ###
sudo ufw allow from $MONITORING_SERVER to any port 9099

### Variables  CHANGE ME ###
valoperaddress=# junovaloper123456789
validatorwallet=# juno123456789
exporter_denom=# junox junox for juno testnet
bechprefix=# the global prefix for addresses. Defaults to i.e. juno


### Prometheus ###
cd ~
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvf prometheus-2.45.0.linux-amd64.tar.gz
sudo cp prometheus-2.45.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-2.45.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.45.0.linux-amd64/console_libraries /etc/prometheus
rm prometheus-2.45.0.linux-amd64.tar.gz
rm -r prometheus-2.45.0.linux-amd64
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /var/lib/prometheus
echo "global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets:
          - localhost:9099
  - job_name: node_exporter
    static_configs:
      - targets:
          - localhost:9199
  - job_name: cosmos
    metrics_path: /metrics
    static_configs:
      - targets:
          - localhost:26660
  - job_name: validators
    metrics_path: /metrics/validators
    static_configs:
      - targets:
          - localhost:9300
        labels: {}
  - job_name: validator
    metrics_path: /metrics/validator
    relabel_configs:
      - source_labels:
          - address
        target_label: __param_address
    static_configs:
      - targets:
          - localhost:9300
        labels:
          address: $valoperaddress
  - job_name: wallet
    metrics_path: /metrics/wallet
    relabel_configs:
      - source_labels:
          - address
        target_label: __param_address
    static_configs:
      - targets:
          - localhost:9300
        labels:
          address: $validatorwallet" | sudo tee -a /etc/prometheus/prometheus.yml > /dev/null
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus

echo "[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
User=prometheus
Group=prometheus
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=":9099"
[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/prometheus.service > /dev/null



### Node Exporter for System Metrics ### 



cd ~
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz
tar xvf node_exporter-1.6.0.linux-amd64.tar.gz
sudo cp node_exporter-1.6.0.linux-amd64/node_exporter /usr/local/bin
rm node_exporter-1.6.0.linux-amd64.tar.gz
rm -r node_exporter-1.6.0.linux-amd64
sudo useradd --no-create-home --shell /bin/false node_exporter

echo "[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=":9199" 
[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/node_exporter.service > /dev/null 



cd ~
curl -LO https://github.com/solarlabsteam/cosmos-exporter/releases/download/v0.3.0/cosmos-exporter_0.3.0_Linux_x86_64.tar.gz
tar xvf cosmos-exporter_0.3.0_Linux_x86_64.tar.gz
sudo cp cosmos-exporter /usr/local/bin
rm cosmos-exporter_0.3.0_Linux_x86_64.tar.gz
rm cosmos-exporter
sudo useradd --no-create-home --shell /bin/false cosmos-exporter

echo "[Unit]
Description=Cosmos Exporter
After=network-online.target
[Service]
User=cosmos-exporter
Group=cosmos-exporter
TimeoutStartSec=0
CPUWeight=95
IOWeight=95
ExecStart=/usr/local/bin/cosmos-exporter --denom $exporter_denom --denom-coefficient 1000000 --bech-prefix $bechprefix --tendermint-rpc tcp://127.0.0.1:26657 --node 0.0.0.0:9090
Restart=always
RestartSec=2
LimitNOFILE=800000
KillSignal=SIGTERM
[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/cosmos_exporter.service > /dev/null 








sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl start cosmos_exporter
sudo systemctl enable cosmos_exporter