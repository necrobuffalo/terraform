# Provider
provider "google" {
  credentials = file("secrets/sandbox-224603-95a13446622b.json")

  project = "sandbox-224603"
  region  = "us-west1"
  zone    = "us-west1-b"
}


# Default VPC
resource "google_compute_network" "default" {
  name        = "default"
  description = "Default network for the project"
}


# DNS zones
resource "google_dns_managed_zone" "sev" {
  name     = "sev"
  dns_name = "sev.sh."

  dnssec_config {
    state = "off"
  }
}


# Mail
resource "google_dns_record_set" "mx" {
  name         = google_dns_managed_zone.sev.dns_name
  managed_zone = google_dns_managed_zone.sev.name
  type         = "MX"
  ttl          = 300

  rrdatas = [
    "10 in1-smtp.messagingengine.com.",
    "20 in2-smtp.messagingengine.com.",
  ]
}
resource "google_dns_record_set" "mx_wildcard" {
  name         = "*.${google_dns_managed_zone.sev.dns_name}"
  managed_zone = google_dns_managed_zone.sev.name
  type         = "MX"
  ttl          = 300
  rrdatas = google_dns_record_set.mx.rrdatas
}
resource "google_dns_record_set" "spf" {
  name         = google_dns_managed_zone.sev.dns_name
  managed_zone = google_dns_managed_zone.sev.name
  type         = "TXT"
  ttl          = 300
  rrdatas = ["\"v=spf1 include:spf.messagingengine.com ?all\""]
}
resource "google_dns_record_set" "cname_mail1" {
  name         = "fm1._domainkey.${google_dns_managed_zone.sev.dns_name}"
  managed_zone = google_dns_managed_zone.sev.name
  type         = "CNAME"
  ttl          = 300
  rrdatas = ["fm1.sev.sh.dkim.fmhosted.com."]
}
resource "google_dns_record_set" "cname_mail2" {
  name         = "fm2._domainkey.${google_dns_managed_zone.sev.dns_name}"
  managed_zone = google_dns_managed_zone.sev.name
  type         = "CNAME"
  ttl          = 300
  rrdatas = ["fm2.sev.sh.dkim.fmhosted.com."]
}
resource "google_dns_record_set" "cname_mail3" {
  name         = "fm3._domainkey.${google_dns_managed_zone.sev.dns_name}"
  managed_zone = google_dns_managed_zone.sev.name
  type         = "CNAME"
  ttl          = 300
  rrdatas = ["fm3.sev.sh.dkim.fmhosted.com."]
}
resource "google_dns_record_set" "cname_mail_frontend" {
  name = "mail.${google_dns_managed_zone.sev.dns_name}"
  managed_zone = google_dns_managed_zone.sev.name
  type = "CNAME"
  ttl = 300
  rrdatas = ["www.fastmail.com."]
}


# Bastion
resource "google_compute_address" "bastion_ip" {
  name = "bastion-static-ip"
}
resource "google_dns_record_set" "bastion" {
  name = "bastion.${google_dns_managed_zone.sev.dns_name}"
  managed_zone = google_dns_managed_zone.sev.name
  type = "A"
  ttl = 300
  rrdatas = [google_compute_address.bastion_ip.address]
}
resource "google_compute_instance" "bastion" {
  name = "bastion"
  machine_type = "g1-small"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.default.name
    access_config {
      nat_ip = google_compute_address.bastion_ip.address
    }
  }
}


# Minecraft
resource "google_compute_address" "minecraft_ip" {
  name = "minecraft-static-ip"
}

resource "google_dns_record_set" "minecraft" {
  name = "mc.${google_dns_managed_zone.sev.dns_name}"
  managed_zone = google_dns_managed_zone.sev.name
  type = "A"
  ttl = 300
  rrdatas = [google_compute_address.minecraft_ip.address]
}

resource "google_compute_instance" "minecraft" {
  name         = "minecraft"
  machine_type = "n1-standard-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      type  = "pd-ssd"
    }
  }

  tags = ["minecraft"]

  attached_disk {
    source = google_compute_disk.minecraft_ssd.name
    device_name = "minecraft-worlds" 
  }

  network_interface {
    network = google_compute_network.default.name
    access_config {
      nat_ip = google_compute_address.minecraft_ip.address
    }
  }
}

# 30gb disk to put worlds on
resource "google_compute_disk" "minecraft_ssd" {
  name = "minecraft-worlds"
  type = "pd-ssd"

  size = 30
}

# Allow tcp/udp on the standard minecraft server port
resource "google_compute_firewall" "minecraft" {
  name = "default-allow-minecraft"
  network = google_compute_network.default.name

  target_tags = ["minecraft"]

  allow {
    protocol = "tcp"
    ports = [25565]
  }

  allow {
    protocol = "udp"
    ports = [25565]
  }
}
