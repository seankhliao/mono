# aws amis, shared, encrypted

## kms key permissions

### _AWS_ AMIs, shared and encrypted

So you build AWS AMIs (EC2 machine images) in AWS.
Under the hood, it's an EC2 instance with an EBS volume attached,
which gets snapshotted.
You share these AMIs with all your accounts.

#### _EBS_ default encryption

Someone turned on EBS encryption by default.
All EBS volumes will now be encrypted with a KMS key,
either one you specify or the default `aws/ebs`.
This includes the EBS volume used to build your AMI,
and also the resulting snapshot.

Your AMI now doesn't work in other accounts:
snapshots / AMIs encrypted with the default (per account) key can't be shared.
You also can't exclude a particular EBS volume from default encryption.

You now have to use customer managed keys.
Encrypt the EBS volume with your own key,
and delegate access to the key to other accounts.

##### _KMS_ key policy

In AWS, to grant access to something cross account,
IAM policies need to be created in both the account that owns the resource,
and the account with the principal.

So we need a KMS key policy that grants other accounts in our org access to the key.
(note this is pretty loose since the AMI isn't really secret and we need it everywhere.)

```json
{
  "Statement": [
    {
      "Sid": "ShareAMIToAccounts",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:RetireGrant",
        "kms:RevokeGrant",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "o-$org_id"
        }
      }
    }
  ]
}
```

##### Karpenter

We run our K8s / EKS clusters with Karpenter as the primary autoscaler for workload pods.
In each account,
we add the following statement to the IAM policy attached to the IAM Role used by karpenter,
granting it access to the KMS key when used via EBS to start up an instance.

```json
{
  "Statement": {
    "Sid": "AllowKMSViaEBS",
    "Effect": "Allow",
    "Resources": ["$kms_key_arns"],
    "Action": [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ],
    "Condition": {
      "StringLike": {
        "kms:ViaService": "ec2.*.amazonaws.com"
      }
    }
  }
}
```

##### EC2 / ECS autoscaling

AWS uses Service Linked Roles for EC2 and ECS autoscaling.
These will also need permissions to KMS keys.
Unfortunately, unlike with Karpenter, you can't use IAM policies because:
a policy has to be in the account the role is in but you can't modify the policies for the Service Linked Role.

So you have to instead use KMS Key Grants.

```
role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling
role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService
```

(Syntax for creating grants omitted).

##### Multi region keys

AWS KMS Multi region keys have a primary, and regional replicas.
In their ARN, they differ only in the region.
For the Karpenter IAM policy, the region can be wildcarded like `:*:`.
For KMS key grants, you need to create one for each regional key.
