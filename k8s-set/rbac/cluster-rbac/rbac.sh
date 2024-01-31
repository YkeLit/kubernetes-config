#!/bin/bash

set -ex

# 参数设置
file_name_prefix=github
cluster_name=kubernetes
user_name=github-deployer
expiration_time=8640000

# 创建私钥
openssl genrsa 4096 > $file_name_prefix.key

cat > $file_name_prefix.conf << END
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C = CN
ST = SiChuan
L = ChengDu
O = kubernetes 
OU = kubernetes
CN = $user_name
END

openssl req -new -key "$file_name_prefix".key -config "$file_name_prefix".conf -out "$file_name_prefix".csr

# 创建 CertificateSigningRequest
certificatesigningrequest=$(cat "$file_name_prefix".csr | base64 -w 0)

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $user_name
spec:
  request: $certificatesigningrequest
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: $expiration_time
  usages:
  - client auth
EOF

# 批准证书签名请求
kubectl certificate approve $user_name

# 取得证书
kubectl get csr $user_name -o jsonpath='{.status.certificate}'| base64 -d > "$file_name_prefix".crt

# 创建角色和角色绑定
sed "s/example/$user_name/" example-cluster-role.yaml > "$file_name_prefix"-cluster-role.yaml
sed "s/example/$user_name/" example-cluster-rolebinding.yaml > "$file_name_prefix"-cluster-rolebinding.yaml
kubectl apply -f "$file_name_prefix"-cluster-role.yaml
kubectl apply -f "$file_name_prefix"-cluster-rolebinding.yaml

# 添加新的凭据
kubectl config set-credentials $user_name --client-key "$file_name_prefix".key --client-certificate "$file_name_prefix".crt --embed-certs=true

# 添加上下文
kubectl config set-context $user_name --cluster $cluster_name --user $user_name

