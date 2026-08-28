# Deploy — joaopaulofarias.com.br

LP estática (um `index.html` + `assets/`) servida por nginx atrás do Traefik da
empresa. Segue o mesmo padrão da `lp-frontend`, com uma diferença de cache
explicada no fim.

**Convenções da VPS** (extraídas da `lp-frontend`, já aplicadas nos arquivos):

| | |
|---|---|
| Orquestração | Docker Compose (não Swarm) |
| Rede | `traefik_default` (externa) |
| Certresolver | `leresolver` |
| Entrypoints | `web,websecure` |

---

## 1. DNS — fazer primeiro

`joaopaulofarias.com.br` é domínio novo, então precisa apontar pra VPS **antes**
de subir. Se o Let's Encrypt tentar emitir o certificado sem DNS resolvendo, ele
falha e entra em backoff.

No painel do registrador, crie dois registros **A** apontando pro IP da VPS:

```
@      A    <IP_DA_VPS>
www    A    <IP_DA_VPS>
```

Descubra o IP na VPS com `curl -4 ifconfig.me`. Confira a propagação:

```bash
dig +short joaopaulofarias.com.br
dig +short www.joaopaulofarias.com.br
```

Só siga quando os dois devolverem o IP certo.

---

## 2. Meta Pixel

Antes de subir, descomente o bloco do Pixel no fim do `index.html` e troque
`SEU_PIXEL_ID` (o comentário CONFIG no topo do arquivo marca isso).

---

## 3. Clonar o repositório na VPS

```bash
cd /root/perfiljoaolp
git clone https://github.com/SEU_USUARIO/SEU_REPO.git .
```

O **ponto no final** faz o clone cair direto nessa pasta, em vez de criar
`perfiljoaolp/SEU_REPO/`. Só funciona se a pasta estiver vazia.

Repositório privado? A senha do GitHub não funciona mais — gere um token em
Settings > Developer settings > Personal access tokens (escopo `repo`) e use
ele como senha quando o `git clone` pedir.

### Atualizar depois

```bash
cd /root/perfiljoaolp
git pull
docker compose up -d --build
```

A `originais/` não vem no clone — está no `.gitignore`, então nem entrou no
repositório. É de propósito: são 232 MB de material bruto que o site não serve.

---

## 4. Subir

```bash
cd /root/perfiljoaolp
docker compose up -d --build
docker compose logs -f lp-joao
```

O `traefik_default` já existe (a `lp-frontend` usa), então não precisa criar
rede. Em 30–60 s o `leresolver` emite o certificado e o domínio responde.

Testar:

```bash
curl -I https://joaopaulofarias.com.br
curl https://joaopaulofarias.com.br/health    # deve responder "healthy"
```

---

## 5. Atualizar depois

```bash
cd /root/perfiljoaolp
docker compose up -d --build
```

O HTML vai com `expires -1`, então texto novo aparece no primeiro refresh.

**O detalhe do cache:** na `lp-frontend` os assets têm `expires 1y` + `immutable`,
o que é seguro lá porque o Vite põe hash no nome de cada arquivo. Aqui os nomes
são fixos (`joao-avatar.jpg`, `print-funil.png`), então 1 ano prenderia a versão
antiga no navegador de quem já visitou — inclusive o seu, quando for conferir.
Por isso deixei **30 dias sem `immutable`**.

Se trocar uma imagem mantendo o nome, renomeie (`print-funil-v2.png`) e atualize
o `src` no HTML. É a forma confiável de furar o cache de quem já viu a página.

---

## Se der errado

| Sintoma | Causa quase sempre |
|---|---|
| 404 do Traefik | DNS ainda não resolve, ou o container não subiu — `docker compose ps` |
| Cert inválido / ERR_CERT | DNS não propagou quando o Traefik tentou emitir. Corrija o DNS e `docker compose restart` |
| Gateway timeout | nginx caiu no boot — `docker compose logs lp-joao` mostra erro de sintaxe no `nginx.conf` |
| Vídeo não carrega no iPhone | Confira se o `assets/joao-lp.mp4` subiu inteiro (14 MB) — FTP às vezes corta |

Ver o que o Traefik registrou:

```bash
docker logs $(docker ps -qf name=traefik) --tail 50 | grep -i joaopaulo
```
