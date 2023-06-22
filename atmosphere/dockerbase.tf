variable "database_name" {
    default = "automatisch"
}
variable "database_user" {
    default = "automatisch"
}
variable "database_password" {
    default = ""
}

variable "encription_key" {
    default = ""
}

variable "webhook_secret_key" {
    default = ""
}

variable "app_secret_key" {
    default = ""
}

variable "domain" {
    default = ""
}

variable "webmaster_email" {
    default = ""
}

resource "random_password" "database_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "encription_key" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "webhook_secret_key" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "app_secret_key" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "digitalocean_droplet" "www-automatisch" {
  #This has pre installed docker
  image = "docker-20-04"
  name = "www-automatisch"
  region = "nyc3"
  size = "s-1vcpu-1gb"
  ssh_keys = [
    digitalocean_ssh_key.terraform.id
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = var.pvt_key != "" ? file(var.pvt_key) : tls_private_key.pk.private_key_pem
    timeout = "4m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # install nginx and docker
      "sleep 5s",
      "apt update",
      "sleep 5s",
      "apt install -y nginx",
      "apt install -y python3-certbot-nginx",
      "apt install -y git",
      # create automatisch installation directory
      "cd /root",
      "git clone https://github.com/automatisch/automatisch.git",
    ]
  }

  provisioner "file" {
    content      = templatefile("docker-compose.yml.tpl", {
      database_user = var.database_user != "" ? var.database_user : "automatisch",
      database_name = var.database_name != "" ? var.database_name : "automatisch",
      database_password = var.database_password != "" ? var.database_password : random_password.database_password.result,
      encription_key = var.encription_key != "" ? var.encription_key : random_password.encription_key.result,
      webhook_secret_key = var.webhook_secret_key != "" ? var.webhook_secret_key : random_password.webhook_secret_key.result,
      app_secret_key = var.app_secret_key != "" ? var.app_secret_key : random_password.app_secret_key.result
    })
    destination = "/root/automatisch/docker-compose.yml"
  }

  provisioner "file" {
    content      = templatefile("atmosphere-nginx.conf.tpl", {
      server_name = var.domain != "" ? var.domain : "0.0.0.0"
    })
    destination = "/etc/nginx/conf.d/atmosphere-nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # run compose
      "cd /root/automatisch",
      "docker compose up -d",
      "rm /etc/nginx/sites-enabled/default",
      "systemctl restart nginx",
      "ufw allow http",
      "ufw allow https",
      "%{if var.domain!= ""}certbot --nginx --non-interactive --agree-tos --domains ${var.domain} --redirect %{if var.webmaster_email!= ""} --email ${var.webmaster_email} %{ else } --register-unsafely-without-email %{ endif } %{ else }echo NOCERTBOT%{ endif }"
    ]
  }
}
