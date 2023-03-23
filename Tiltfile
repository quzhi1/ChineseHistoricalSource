# -*- mode: Python -*-

load('ext://restart_process', 'docker_build_with_restart')
load('ext://helm_resource', 'helm_resource', 'helm_repo')
update_settings(max_parallel_updates=10, k8s_upsert_timeout_secs=60)

# Pull opensearch charts
helm_repo('opensearch', 'https://opensearch-project.github.io/helm-charts')

# Spin up opensearch
helm_resource(
  'opensearch-service',
  'helm/opensearch',
  port_forwards=["9200:9200", "9600:9600"],
  labels='opensearch',
)

# Init opensearch
local_resource(
  'opensearch-init',
  "go run go/create_user_role/main.go",
  deps="go/create_user_role/",
  resource_deps=["opensearch-service"],
  allow_parallel=True,
  labels=["opensearch"],
)

# Install opensearch-dashboards
helm_resource(
  'opensearch-dashboards',
  'opensearch/opensearch-dashboards',
  port_forwards=["5601:5601"],
  flags=[
    '--set',
    'clusterName=elasticsearch-history-source',
    '--set',
    'opensearchHosts=https://opensearch.default.svc.cluster.local:9200',
  ],
  resource_deps=['opensearch-service'],
  labels='opensearch',
)
