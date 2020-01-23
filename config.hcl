disable_cache = true
disable_mlock = true
ui = true

listener "tcp" {
   address          = "0.0.0.0:443"
   tls_disable      = 0
   tls_cert_file = "/etc/vault/certs/app.crt"
   tls_key_file  = "/etc/vault/certs/app.key"
}

storage "file" {
   path  = "/var/lib/vault/data"
}

max_lease_ttl         = "2h"
default_lease_ttl    = "2h"
cluster_name         = "vault"
raw_storage_endpoint     = true
disable_sealwrap     = true
disable_printable_check = true