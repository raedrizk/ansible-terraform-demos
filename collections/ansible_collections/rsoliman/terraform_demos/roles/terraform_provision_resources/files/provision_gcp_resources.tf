variable "project" {
  type        = string
  description = "The GCP Project to provision resources into."
}

variable "region" {
  type        = string
  description = "The GCP region to provision resources into."
}

variable "zone" {
  type        = string
  description = "The GCP Availability Zone to provision resources into."
}

variable "image" {
  type        = string
  description = "The Image to use for the new vm."
}

variable "name" {
  type        = string
  description = "The Name to use for the network,firewall and instance."
}

variable "type" {
  type        = string
  description = "The machine type for the new vm."
}

variable "disksize" {
  type        = string
  description = "The disk size for the new vm."
}


terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}


resource "google_compute_network" "vpc_network" {
  name = var.name
}

resource "google_compute_firewall" "default" {
  name    = var.name
  network = google_compute_network.vpc_network.name


  allow {
    protocol = "tcp"
    ports    = ["22", "5985", "5986", "80", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_instance" "vm_instance" {
  name         = var.name
  machine_type = var.type
  tags         = ["ansible","terraform","demo"]

  boot_disk {
    initialize_params {
      image = var.image
      size = var.disksize
    }
  }
  metadata_startup_script = file("userdata_Linux.sh")
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}

output "ip" {
  value = google_compute_instance.vm_instance.network_interface.0.network_ip
}
output "name" {
  value = google_compute_instance.vm_instance.name
}
