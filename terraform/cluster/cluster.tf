provider "google" {
  project = var.project
}

# CLUSTER NETWORK
module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.5"
  project_id   = var.project
  network_name = var.network

  subnets = [
    {
      subnet_name           = var.subnetwork
      subnet_ip             = "10.0.128.0/17"
      subnet_region         = var.region
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    "${var.subnetwork}" = [
      {
        range_name    = var.ip_range_pods
        ip_cidr_range = "192.168.128.0/18"
      },
      {
        range_name    = var.ip_range_services
        ip_cidr_range = "192.168.192.0/18"
      },
    ]
  }
}

# CLUSTER
module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version    = "12.3.0"
  project_id = var.project
  name       = var.cluster_name
  regional   = false
  region     = var.region
  zones      = [var.cluster_location]


  network                 = module.gcp-network.network_name
  subnetwork              = module.gcp-network.subnets_names[0]
  ip_range_pods           = var.ip_range_pods
  ip_range_services       = var.ip_range_services
  create_service_account  = true
  enable_private_endpoint = false
  # enable_private_nodes       = true
  # master_ipv4_cidr_block     = "172.16.0.0/28"
  http_load_balancing        = false
  remove_default_node_pool   = true
  skip_provisioners          = true
  maintenance_start_time     = "22:00"
  network_policy             = false
  monitoring_service         = "none"
  logging_service            = "none"
  add_cluster_firewall_rules = var.add_cluster_firewall_rules
  firewall_inbound_ports     = ["8443", "9443", "15017"]
  node_pools = [
    {
      name         = "ingress-pool"
      machine_type = "e2-micro"
      disk_size_gb = 10
      autoscaling  = false
      node_count   = 1
      image_type   = "COS_CONTAINERD"
      auto_upgrade = true
      preemptible  = true
    },
    {
      name               = "web-pool"
      machine_type       = "e2-micro"
      disk_size_gb       = 10
      autoscaling        = false
      initial_node_count = 1
      node_count         = 1
      image_type         = "COS_CONTAINERD"
      auto_upgrade       = true
      preemptible        = true
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/service.management",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/trace.append",
    ]

  }

  node_pools_taints = {
    all = []
    ingress-pool = [

      {
        key    = "ingress-pool"
        value  = true
        effect = "NO_EXECUTE"
      },

    ]
  }

  node_pools_tags = {
    ingress-pool = [
      "ingress-pool"
    ]
    web-pool = [
      "web-pool"
    ]
  }

  master_authorized_networks = [
    {
      display_name = "Anyone"
      cidr_block   = "0.0.0.0/0"
    },
  ]
}

# HTTP TRAFFIC
resource "google_compute_firewall" "http_node_port" {
  name    = "http-node-port"
  network = module.gcp-network.network_name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

# HTTPS TRAFFIC
resource "google_compute_firewall" "https_node_port" {
  name    = "https-node-port"
  network = module.gcp-network.network_name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

module "gke_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version      = "12.3.0"
  project_id   = var.project
  location     = module.gke.location
  cluster_name = module.gke.name
}

module "kubeip" {
  source                 = "github.com/nufailtd/terraform-budget-gcp//modules/kubeip"
  project_id             = var.project
  zone                   = module.gke.location
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
}
