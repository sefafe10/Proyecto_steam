#!/bin/bash

# 1. Directorio del proyecto
cd /home/ubuntu/steam_insight

# 2. Convertir el Notebook de Jupyter a un script de Python ejecutable
# (Esto asume que tu notebook se llama 'scraper.ipynb')
docker exec -it steam_insight-jupyter-spark-1 jupyter nbconvert --to script /home/jovyan/work/scraper.ipynb

# 3. Ejecutar el script de Python dentro del contenedor de Jupyter
# Esto bombeará nuevos datos a Kafka -> NiFi -> Mongo
docker exec -it steam_insight-jupyter-spark-1 python3 /home/jovyan/work/scraper.py

echo "Pipeline ejecutado con éxito: $(date)" >> logs_ejecucion.txt
