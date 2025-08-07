# Docker Compose Configuration

Este projeto inclui configurações Docker Compose separadas para desenvolvimento e produção.

## 📁 Arquivos

- `docker-compose.yml` - Configuração original (legacy)
- `docker-compose.dev.yml` - **Desenvolvimento** com hot reload
- `docker-compose.prod.yml` - **Produção** otimizada
- `env.example` - Exemplo de variáveis de ambiente

## 🚀 Desenvolvimento

### Pré-requisitos

- Docker e Docker Compose instalados
- Portas disponíveis (3000-3010, 5432-5434, 27017-27018, etc.)

### Iniciar ambiente de desenvolvimento

```bash
# Copiar arquivo de exemplo de variáveis de ambiente
cp env.example .env

# Iniciar todos os serviços de desenvolvimento
docker-compose -f docker-compose.dev.yml up -d

# Ou iniciar apenas serviços específicos
docker-compose -f docker-compose.dev.yml up -d auth-service gateway-service postgres-auth
```

### Características do ambiente de desenvolvimento

✅ **Hot Reload**: Mudanças no código são refletidas automaticamente  
✅ **Volumes**: Código fonte montado em volumes para desenvolvimento  
✅ **Health Checks**: Verificação de saúde dos serviços  
✅ **Ferramentas de desenvolvimento**: Redis, MailHog para testes  
✅ **Logs detalhados**: Logs completos para debugging

### Serviços disponíveis em desenvolvimento

| Serviço               | Porta                    | Descrição                 |
| --------------------- | ------------------------ | ------------------------- |
| Gateway               | 3000                     | API Gateway               |
| Auth Service          | 3001 (TCP) / 3002 (HTTP) | Autenticação              |
| Users Service         | 3003                     | Gerenciamento de usuários |
| Posts Service         | 3004                     | Gerenciamento de posts    |
| Comments Service      | 3005                     | Comentários               |
| Notifications Service | 3006                     | Notificações              |
| Search Service        | 3007                     | Busca                     |
| Analytics Service     | 3008                     | Analytics                 |
| Prometheus            | 9090                     | Monitoramento             |
| Grafana               | 3010                     | Dashboards                |
| Redis                 | 6379                     | Cache                     |
| MailHog               | 1025/8025                | Email testing             |

## 🏭 Produção

### Pré-requisitos

- Docker e Docker Compose instalados
- Arquivo `.env` configurado com senhas seguras
- Certificados SSL (opcional)

### Configurar variáveis de ambiente

```bash
# Copiar arquivo de exemplo
cp env.example .env

# Editar o arquivo .env com senhas seguras
nano .env
```

### Iniciar ambiente de produção

```bash
# Iniciar todos os serviços de produção
docker-compose -f docker-compose.prod.yml up -d

# Verificar status dos serviços
docker-compose -f docker-compose.prod.yml ps

# Ver logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Características do ambiente de produção

✅ **Segurança**: Senhas e secrets configuráveis  
✅ **Recursos limitados**: Limites de CPU e memória  
✅ **Health Checks**: Verificação de saúde robusta  
✅ **Networks**: Rede isolada para serviços  
✅ **Nginx**: Load balancer/reverse proxy  
✅ **Backup**: Volumes persistentes  
✅ **Monitoramento**: Prometheus + Grafana

## 🔧 Comandos úteis

### Desenvolvimento

```bash
# Iniciar ambiente de desenvolvimento
docker-compose -f docker-compose.dev.yml up -d

# Parar ambiente de desenvolvimento
docker-compose -f docker-compose.dev.yml down

# Rebuild e reiniciar um serviço específico
docker-compose -f docker-compose.dev.yml up -d --build auth-service

# Ver logs de um serviço específico
docker-compose -f docker-compose.dev.yml logs -f auth-service

# Executar comandos dentro de um container
docker-compose -f docker-compose.dev.yml exec auth-service sh
```

### Produção

```bash
# Iniciar ambiente de produção
docker-compose -f docker-compose.prod.yml up -d

# Parar ambiente de produção
docker-compose -f docker-compose.prod.yml down

# Backup dos volumes
docker-compose -f docker-compose.prod.yml down
tar -czf backup-$(date +%Y%m%d).tar.gz $(docker volume ls -q | grep microblog-platform)

# Restaurar backup
tar -xzf backup-20231201.tar.gz
docker-compose -f docker-compose.prod.yml up -d
```

### Monitoramento

```bash
# Verificar saúde dos serviços
docker-compose -f docker-compose.prod.yml ps

# Ver logs de todos os serviços
docker-compose -f docker-compose.prod.yml logs

# Ver logs de um serviço específico
docker-compose -f docker-compose.prod.yml logs -f gateway-service

# Verificar uso de recursos
docker stats
```

## 🛠️ Dockerfiles

### Desenvolvimento

- `services/*/Dockerfile.dev` - Para desenvolvimento com hot reload
- Usa `pnpm run start:dev` para hot reload
- Volumes montados para código fonte

### Produção

- `services/*/Dockerfile` - Para produção otimizada
- Usa `pnpm run start:prod` para produção
- Multi-stage build para otimização

## 🔒 Segurança

### Desenvolvimento

- Senhas padrão para facilitar desenvolvimento
- Portas expostas para debugging
- Logs detalhados

### Produção

- Todas as senhas devem ser alteradas
- Variáveis de ambiente para secrets
- Rede isolada
- Health checks robustos
- Limites de recursos

## 📊 Monitoramento

### Prometheus

- URL: http://localhost:9090
- Configuração: `monitoring/prometheus/prometheus.dev.yml` (dev) / `prometheus.prod.yml` (prod)

### Grafana

- URL: http://localhost:3010
- Usuário: admin
- Senha: admin (dev) / configurável (prod)

## 🚨 Troubleshooting

### Problemas comuns

1. **Porta já em uso**

   ```bash
   # Verificar portas em uso
   lsof -i :3000

   # Parar processo que está usando a porta
   kill -9 <PID>
   ```

2. **Serviço não inicia**

   ```bash
   # Ver logs do serviço
   docker-compose -f docker-compose.dev.yml logs auth-service

   # Verificar health checks
   docker-compose -f docker-compose.dev.yml ps
   ```

3. **Problemas de conectividade entre serviços**

   ```bash
   # Verificar rede Docker
   docker network ls
   docker network inspect microblog-platform_microblog-network
   ```

4. **Problemas de permissão**
   ```bash
   # Ajustar permissões dos volumes
   sudo chown -R $USER:$USER $(docker volume inspect microblog-platform_postgres-auth-data | jq -r '.[0].Mountpoint')
   ```

## 📝 Notas importantes

- **Desenvolvimento**: Use `docker-compose.dev.yml` para desenvolvimento local
- **Produção**: Use `docker-compose.prod.yml` para ambientes de produção
- **Variáveis de ambiente**: Sempre configure o arquivo `.env` antes de iniciar
- **Backup**: Faça backup regular dos volumes em produção
- **Monitoramento**: Configure alertas no Prometheus/Grafana para produção
- **SSL**: Configure certificados SSL no Nginx para produção
