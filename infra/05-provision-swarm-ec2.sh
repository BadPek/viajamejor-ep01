#!/usr/bin/env bash
# Etapa opcional de infraestructura:
# Crea 2 instancias Amazon EC2 Ubuntu 22.04 (1 Manager + 1 Worker) con Docker preinstalado
# y Security Group configurado para formar el cluster Docker Swarm de ViajaMejor.
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
KEY_NAME="${EC2_KEY_NAME:-vockey}"
INSTANCE_TYPE="${EC2_INSTANCE_TYPE:-t3.small}"
SG_NAME="${SWARM_SG_NAME:-viajamejor-swarm-sg}"

echo "== [1/3] Buscando AMI oficial de Ubuntu 22.04 LTS en ${AWS_REGION} =="
AMI_ID="$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" "Name=state,Values=available" \
  --region "${AWS_REGION}" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)"

echo "== [2/3] Creando/verificando Security Group Swarm (${SG_NAME}) =="
VPC_ID="$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --region "${AWS_REGION}" --query 'Vpcs[0].VpcId' --output text)"
SG_ID="$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" --region "${AWS_REGION}" --query 'SecurityGroups[0].GroupId' --output text)"

if [[ "${SG_ID}" == "None" || -z "${SG_ID}" ]]; then
  SG_ID="$(aws ec2 create-security-group \
    --group-name "${SG_NAME}" \
    --description "Puertos Docker Swarm y microservicios ViajaMejor" \
    --vpc-id "${VPC_ID}" \
    --region "${AWS_REGION}" \
    --query GroupId --output text)"

  # SSH + puertos publicados de microservicios
  aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "${AWS_REGION}" >/dev/null
  aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" --protocol tcp --port 8081-8087 --cidr 0.0.0.0/0 --region "${AWS_REGION}" >/dev/null
  # Puertos internos del cluster Docker Swarm entre nodos del mismo SG
  aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" --protocol tcp --port 2377 --source-group "${SG_ID}" --region "${AWS_REGION}" >/dev/null
  aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" --protocol tcp --port 7946 --source-group "${SG_ID}" --region "${AWS_REGION}" >/dev/null
  aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" --protocol udp --port 7946 --source-group "${SG_ID}" --region "${AWS_REGION}" >/dev/null
  aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" --protocol udp --port 4789 --source-group "${SG_ID}" --region "${AWS_REGION}" >/dev/null
  echo "Security Group ${SG_NAME} creado (${SG_ID})."
fi

USER_DATA_FILE="/tmp/viajamejor-docker-userdata.sh"
cat > "${USER_DATA_FILE}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
apt-get update -y
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
usermod -aG docker ubuntu
systemctl enable --now docker
EOF

echo "== [3/3] Lanzando instancias EC2 (Manager + Worker) =="
for NODE_NAME in viajamejor-swarm-manager viajamejor-swarm-worker-1; do
  EXISTING="$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${NODE_NAME}" "Name=instance-state-name,Values=pending,running" \
    --region "${AWS_REGION}" \
    --query 'Reservations[0].Instances[0].InstanceId' --output text)"

  if [[ "${EXISTING}" == "None" || -z "${EXISTING}" ]]; then
    INST_ID="$(aws ec2 run-instances \
      --image-id "${AMI_ID}" \
      --instance-type "${INSTANCE_TYPE}" \
      --key-name "${KEY_NAME}" \
      --security-group-ids "${SG_ID}" \
      --user-data "file://${USER_DATA_FILE}" \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${NODE_NAME}},{Key=Project,Value=ViajaMejor}]" \
      --region "${AWS_REGION}" \
      --query 'Instances[0].InstanceId' --output text)"
    echo "Instancia ${NODE_NAME} lanzada: ${INST_ID}"
  else
    echo "Instancia ${NODE_NAME} ya activa: ${EXISTING}"
  fi
done

echo ""
echo "== Esperando IPs publicas y privadas (15s) =="
sleep 15
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ViajaMejor" "Name=instance-state-name,Values=pending,running" \
  --region "${AWS_REGION}" \
  --query 'Reservations[].Instances[].{Nombre:Tags[?Key==`Name`].Value|[0],ID:InstanceId,IP_Publica:PublicIpAddress,IP_Privada:PrivateIpAddress,Estado:State.Name}' \
  --output table
