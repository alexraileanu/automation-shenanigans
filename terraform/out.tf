output "Public ip" {
  value = "${digitalocean_droplet.echo.ipv4_address}"
}

output "Name" {
  value = "${digitalocean_droplet.echo.name}"
}