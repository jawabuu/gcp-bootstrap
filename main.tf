provider "google" {
  project = "silvester-304916"
}

resource "google_container_cluster" "default" {
  name               = "silvester-cluster"
  location           = "europe-west1-b" # MUST BE A SINGLE ZONE, OTHERWISE IT COUNTS AS A REGIONAL CLUSTER


  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}


resource "google_container_node_pool" "default" {
  name     = "silvester-nodepool-ingress"
  cluster  = google_container_cluster.default.name
  initial_node_count = 1
  location = "europe-west1-b" 

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  management {
    auto_repair = true
    auto_upgrade = true
  }

  node_config {
    machine_type = "e2-micro" 
    preemptible  = true 
    disk_size_gb = 10
    taint = [ {
      effect = "NO_SCHEDULE"
      key = "dedicated"
      value = "ingress"
    } ]
  }
}

resource "google_container_node_pool" "memory_optimized" {
  name     = "silvester-nodepool"
  cluster  = google_container_cluster.default.name
  initial_node_count = 1
  location = "europe-west1-b" 

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  management {
    auto_repair = true
    auto_upgrade = true
  }

  node_config {
    machine_type = "n2d-highmem-4" 
    preemptible  = true 
  }
}

