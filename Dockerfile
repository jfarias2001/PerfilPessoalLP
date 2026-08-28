# LP estatica: nao tem build step (sem Vite/npm), so copia os arquivos.
FROM nginx:alpine

# Config nginx customizada (mesmo padrao da lp-frontend)
COPY nginx.conf /etc/nginx/nginx.conf

# Conteudo da LP
COPY index.html /usr/share/nginx/html/index.html
COPY assets/ /usr/share/nginx/html/assets/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
