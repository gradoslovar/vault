# Read permission on the k/v secrets
path "Customers/*" {
    capabilities = ["read", "list"]
}