
output "private_subnets_ids" {
  value = aws_subnet.cluster_private.*.id
}

output "public_subnets_ids" {
  value = aws_subnet.cluster_public.*.id
}

output "cluster_private_rtb_ids" {
  value = aws_route_table.cluster_private_rtb.*.id
}

output "cluster_public_rtb_id" {
  value = aws_route_table.cluster_public_rtb_dynamic.id
}

output "irsa_roles" {
  value = aws_iam_role.irsa_role.*.arn
}





