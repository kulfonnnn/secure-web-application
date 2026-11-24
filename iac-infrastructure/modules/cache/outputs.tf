output "endpoint" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}
output "member_cluster_id" {
  value = tolist(aws_elasticache_replication_group.this.member_clusters)[0]
}