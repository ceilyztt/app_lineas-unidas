# ==========================================
# Etapa 1: Entorno de Compilación
# ==========================================
FROM debian:bookworm-slim AS build-env

# Instalar las dependencias de sistema requeridas para Flutter
RUN apt-get update && apt-get install -y \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  && rm -rf /var/lib/apt/lists/*

# Descargar e instalar el canal oficial estable de Flutter SDK (usando --depth 1 para descarga rápida)
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /usr/local/flutter

# Agregar Flutter al PATH global de la imagen
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Validar la instalación y descargar previamente las herramientas de compilación Web
RUN flutter doctor -v
RUN flutter precache --web

# Configurar el directorio de trabajo e importar el código del proyecto
WORKDIR /app
COPY . .

# Configurar la plataforma Web en el proyecto
RUN flutter create . --platforms web

# Obtener dependencias y compilar la aplicación para el navegador Web
RUN flutter pub get
RUN flutter build web --release

# ==========================================
# Etapa 2: Servidor Web de Producción (Nginx)
# ==========================================
FROM nginx:alpine

# Copiar el resultado de la compilación web de la etapa anterior hacia la carpeta pública de Nginx
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Exponer el puerto estándar HTTP
EXPOSE 80

# Iniciar el servidor web
CMD ["nginx", "-g", "daemon off;"]
