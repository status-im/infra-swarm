# Descirption

This role installs the certificate and key pair from CloudFlare which is called an __Origin__ certificate and is issued by CloudFlare CA to facilitate an SSL Proxy setup which allows the site to authenticate with the `*.status.im` wildcard certificate from CloudFlare without having it on the host.

>WARNING: The origin certificate alone is not enough to facilitate a valid SSL setup.

Details: https://blog.cloudflare.com/cloudflare-ca-encryption-origin/

# Usage

The certificates end up in the same place as other certs:

* `/certs/origin.crt`
* `/certs/origin.key`

And are used by services like Nginx or Grafana for the purpose of verifying their identity for CloudFlare proxy servers.
