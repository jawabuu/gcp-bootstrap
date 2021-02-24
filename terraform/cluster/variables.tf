variable "project" {
  type    = string
  default = "silvester-304916"
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "cluster_location" {
  type    = string
  default = "europe-west1-b"
}

variable "cluster_name" {
  type    = string
  default = "silvester-cluster"
}

variable "add_cluster_firewall_rules" {
  default = false
}

variable "network" {
  type    = string
  default = "default"
}

variable "subnetwork" {
  type    = string
  default = "gke-subnet"
}

variable "ip_range_pods" {
  type    = string
  default = "ip-range-pods"
}

variable "ip_range_services" {
  type    = string
  default = "ip-range-scv"
}