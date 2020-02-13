Role Name
=========

Labels all the nodes in the cluster with string "infra" as with a node role of
"infra"

Also puts a tain on them infra nodes to tell the cluster to not prefer the 
infra nodes when scheduling new workload.

Long discussion of why a tain and not a default node role in the project
template. (Some other day)
