# Imagen de la app de prueba: nginx unprivileged sirviendo una landing estatica.
#
# Usamos nginxinc/nginx-unprivileged: imagen oficial disenada para correr como
# usuario NO-root (uid 101) y escuchar en 8080. Es la base correcta para ECS
# Fargate con readonlyRootFilesystem + usuario no-root, porque evita el
# conflicto de ownership que surge al montar volumenes tmpfs sobre /tmp.
#
# Endurecimiento Zero Trust en runtime:
#   - Usuario no-root (ya es el default de esta imagen)
#   - Compatible con readonlyRootFilesystem (temporales bajo /tmp, montados como
#     volumenes efimeros en la task definition)

FROM nginxinc/nginx-unprivileged:1.27-alpine

LABEL org.opencontainers.image.title="simon-movilidad-app" \
      org.opencontainers.image.description="Landing de prueba servida por nginx (unprivileged) en ECS Fargate"

# La imagen unprivileged corre como uid 101; para copiar archivos de config
# necesitamos privilegios temporales de root, luego volvemos a nginx.
USER root

# Config propia y contenido estatico
COPY nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/

RUN chown -R nginx:nginx /usr/share/nginx/html \
    && chmod -R 755 /usr/share/nginx/html

# Volver al usuario no-root para runtime
USER nginx

# Puerto no privilegiado (default de la imagen unprivileged)
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:8080/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
