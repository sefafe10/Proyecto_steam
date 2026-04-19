#!/bin/bash
echo "INICIANDO DESPLIEGUE AUTOMATICO DE STEAM INSIGHT..."

# 1. Crear Memoria SWAP (Vital para que la t2.large no explote con Hadoop)
echo "Configurando memoria SWAP de 4GB..."
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 2. Instalar dependencias y Docker
echo "Instalando Docker y herramientas..."
sudo apt update && sudo apt install -y docker.io git net-tools curl
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu

# 3. Instalar Docker Compose V2 (A nivel global para evitar el bug de Python)
echo "Instalando Docker Compose V2..."
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# 4. Clonar el repositorio
echo "Descargando el proyecto desde GitHub..."
if [ ! -d "steam_insight" ]; then
    git clone https://github.com/sefafe10/Proyecto_steam.git steam_insight
fi
cd steam_insight

# 5. Crear archivo de configuracion para Hadoop
echo "Generando archivo hadoop.env..."
cat <<EOF > hadoop.env
CORE_CONF_fs_defaultFS=hdfs://namenode:8020
CORE_CONF_hadoop_http_staticuser_user=root
HDFS_CONF_dfs_namenode_datanode_registration_ip___hostname__check=false
HDFS_CONF_dfs_permissions_enabled=false
HDFS_CONF_dfs_webhdfs_enabled=true
EOF

# 6. MAGIA: Detectar nueva IP de AWS y actualizar NiFi automaticamente
echo "Detectando nueva IP Publica..."
MI_NUEVA_IP=$(curl -s ifconfig.me)
echo "   -> IP detectada: $MI_NUEVA_IP"
echo "   -> Actualizando configuracion de NiFi..."
sed -i -E "s/- NIFI_WEB_PROXY_HOST=.*/- NIFI_WEB_PROXY_HOST=${MI_NUEVA_IP}:8443,*/g" docker-compose.yml

# 7. Limpieza preventiva de contenedores (Evita conflictos de nombres)
echo "Limpiando residuos de ejecuciones anteriores..."
sudo -u ubuntu sg docker -c "docker rm -f \$(docker ps -aq) 2>/dev/null"

# 8. Levantar la infraestructura
echo "Levantando el clúster de Big Data (Kafka, Mongo, NiFi, Jupyter, Hadoop)..."
sudo -u ubuntu sg docker -c "docker compose up -d"

echo "DESPLIEGUE COMPLETADO CON EXITO"
echo "--------------------------------------------------"
echo "Jupyter: http://${MI_NUEVA_IP}:8888"
echo "NiFi:    https://${MI_NUEVA_IP}:8443/nifi"
echo "Hadoop:  http://${MI_NUEVA_IP}:9870"
echo "--------------------------------------------------"
