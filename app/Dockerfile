# Imagen de la app de prueba: nginx Alpine sirviendo una landing estatica.
# Endurecida para Zero Trust en runtime:
#   - Base Alpine (superficie minima)
#   - Corre como usuario no-root (nginx, uid 101)
#   - Compatible con readonlyRootFilesystem (temporales en /tmp)
#   - HEALTHCHECK integrado

FROM nginx:1.27-alpine

# Metadatos
LABEL org.opencontainers.image.title="simon-movilidad-app" \
      org.opencontainers.image.description="Landing de prueba servida por nginx en ECS Fargate"

# Config propia y contenido estatico
COPY nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/

# Crear dirs temporales y dar permisos al usuario nginx (no-root)
RUN mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp \
             /tmp/uwsgi_temp /tmp/scgi_temp \
    && chown -R nginx:nginx /usr/share/nginx/html /tmp \
    && chmod -R 755 /usr/share/nginx/html

# Puerto no privilegiado
EXPOSE 8080

# Ejecutar como usuario no-root
USER nginx

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:8080/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
