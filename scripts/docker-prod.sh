#!/bin/bash

# Script para gerenciar ambiente de produção Docker
# Uso: ./scripts/docker-prod.sh [comando]

set -e

COMPOSE_FILE="docker-compose.prod.yml"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Função para verificar se o Docker está rodando
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker não está rodando. Inicie o Docker e tente novamente."
        exit 1
    fi
}

# Função para verificar se o arquivo .env existe e está configurado
check_env_file() {
    if [ ! -f .env ]; then
        print_error "Arquivo .env não encontrado. Crie-o a partir do env.example e configure as variáveis de ambiente."
        exit 1
    fi
    
    # Verificar se as variáveis críticas estão definidas
    local critical_vars=(
        "JWT_SECRET"
        "POSTGRES_AUTH_PASSWORD"
        "POSTGRES_USERS_PASSWORD"
        "POSTGRES_POSTS_PASSWORD"
        "MONGO_COMMENTS_PASSWORD"
        "MONGO_NOTIFICATIONS_PASSWORD"
        "ELASTICSEARCH_PASSWORD"
        "INFLUXDB_PASSWORD"
        "RABBITMQ_PASSWORD"
        "REDIS_PASSWORD"
        "GRAFANA_ADMIN_PASSWORD"
    )
    
    for var in "${critical_vars[@]}"; do
        if ! grep -q "^${var}=" .env || grep -q "^${var}=your-secure" .env; then
            print_error "Variável $var não está configurada ou está usando valor padrão. Configure-a no arquivo .env"
            exit 1
        fi
    done
    
    print_message "Arquivo .env verificado com sucesso!"
}

# Função para verificar portas em uso
check_ports() {
    local ports=("80" "443" "3000" "3001" "3002" "3003" "3004" "3005" "3006" "3007" "3008" "5432" "5433" "5434" "27017" "27018")
    
    for port in "${ports[@]}"; do
        if lsof -i :$port > /dev/null 2>&1; then
            print_warning "Porta $port está em uso. Verifique se não há outros serviços rodando."
        fi
    done
}

# Função para backup
backup() {
    print_header "Criando backup dos volumes"
    
    local backup_dir="backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_dir}/backup_${timestamp}.tar.gz"
    
    mkdir -p $backup_dir
    
    print_message "Parando serviços..."
    docker-compose -f $COMPOSE_FILE down
    
    print_message "Criando backup..."
    docker run --rm -v $(pwd):/backup -v /var/run/docker.sock:/var/run/docker.sock alpine tar -czf /backup/$backup_file -C /var/lib/docker/volumes $(docker volume ls -q | grep microblog-platform)
    
    print_message "Reiniciando serviços..."
    docker-compose -f $COMPOSE_FILE up -d
    
    print_message "Backup criado: $backup_file"
}

# Função para restaurar backup
restore() {
    local backup_file=${2:-""}
    
    if [ -z "$backup_file" ]; then
        print_error "Especifique o arquivo de backup. Exemplo: $0 restore backups/backup_20231201_120000.tar.gz"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Arquivo de backup não encontrado: $backup_file"
        exit 1
    fi
    
    print_header "Restaurando backup"
    print_warning "Isso irá parar todos os serviços e restaurar os dados!"
    read -p "Tem certeza? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Operação cancelada."
        exit 0
    fi
    
    print_message "Parando serviços..."
    docker-compose -f $COMPOSE_FILE down
    
    print_message "Restaurando backup..."
    docker run --rm -v $(pwd):/backup -v /var/run/docker.sock:/var/run/docker.sock alpine sh -c "cd /var/lib/docker/volumes && tar -xzf /backup/$backup_file"
    
    print_message "Reiniciando serviços..."
    docker-compose -f $COMPOSE_FILE up -d
    
    print_message "Backup restaurado com sucesso!"
}

# Função para iniciar serviços
start() {
    print_header "Iniciando ambiente de produção"
    check_docker
    check_env_file
    check_ports
    
    print_message "Iniciando serviços..."
    docker-compose -f $COMPOSE_FILE up -d
    
    print_message "Aguardando serviços ficarem prontos..."
    sleep 30
    
    print_message "Verificando status dos serviços..."
    docker-compose -f $COMPOSE_FILE ps
    
    print_message "Ambiente de produção iniciado!"
    print_message "Gateway: http://localhost:3000"
    print_message "Nginx: http://localhost:80"
    print_message "Grafana: http://localhost:3010"
    print_message "Prometheus: http://localhost:9090"
}

# Função para parar serviços
stop() {
    print_header "Parando ambiente de produção"
    docker-compose -f $COMPOSE_FILE down
    print_message "Ambiente de produção parado!"
}

# Função para reiniciar serviços
restart() {
    print_header "Reiniciando ambiente de produção"
    stop
    start
}

# Função para rebuild
rebuild() {
    print_header "Rebuild dos serviços"
    docker-compose -f $COMPOSE_FILE down
    docker-compose -f $COMPOSE_FILE build --no-cache
    docker-compose -f $COMPOSE_FILE up -d
    print_message "Rebuild concluído!"
}

# Função para mostrar logs
logs() {
    local service=${2:-""}
    if [ -n "$service" ]; then
        print_message "Mostrando logs do serviço: $service"
        docker-compose -f $COMPOSE_FILE logs -f $service
    else
        print_message "Mostrando logs de todos os serviços"
        docker-compose -f $COMPOSE_FILE logs -f
    fi
}

# Função para mostrar status
status() {
    print_header "Status dos serviços"
    docker-compose -f $COMPOSE_FILE ps
}

# Função para executar comando em um serviço
exec() {
    local service=${2:-""}
    local command=${3:-"sh"}
    
    if [ -z "$service" ]; then
        print_error "Especifique um serviço. Exemplo: $0 exec auth-service"
        exit 1
    fi
    
    print_message "Executando comando no serviço: $service"
    docker-compose -f $COMPOSE_FILE exec $service $command
}

# Função para monitoramento
monitor() {
    print_header "Informações de monitoramento"
    
    echo -e "${BLUE}Uso de recursos:${NC}"
    docker stats --no-stream
    
    echo -e "\n${BLUE}Volumes:${NC}"
    docker volume ls | grep microblog-platform
    
    echo -e "\n${BLUE}Networks:${NC}"
    docker network ls | grep microblog-platform
    
    echo -e "\n${BLUE}Logs recentes:${NC}"
    docker-compose -f $COMPOSE_FILE logs --tail=10
}

# Função para atualizar
update() {
    print_header "Atualizando serviços"
    
    print_message "Fazendo pull das imagens..."
    docker-compose -f $COMPOSE_FILE pull
    
    print_message "Reiniciando serviços..."
    docker-compose -f $COMPOSE_FILE up -d
    
    print_message "Atualização concluída!"
}

# Função para mostrar ajuda
help() {
    print_header "Comandos disponíveis"
    echo "start     - Iniciar ambiente de produção"
    echo "stop      - Parar ambiente de produção"
    echo "restart   - Reiniciar ambiente de produção"
    echo "rebuild   - Rebuild de todos os serviços"
    echo "logs      - Mostrar logs (opcional: especificar serviço)"
    echo "status    - Mostrar status dos serviços"
    echo "exec      - Executar comando em um serviço"
    echo "backup    - Criar backup dos volumes"
    echo "restore   - Restaurar backup"
    echo "monitor   - Mostrar informações de monitoramento"
    echo "update    - Atualizar imagens e reiniciar"
    echo "help      - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 start"
    echo "  $0 logs auth-service"
    echo "  $0 exec auth-service sh"
    echo "  $0 backup"
    echo "  $0 restore backups/backup_20231201_120000.tar.gz"
}

# Função principal
main() {
    case "${1:-help}" in
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        rebuild)
            rebuild
            ;;
        logs)
            logs "$@"
            ;;
        status)
            status
            ;;
        exec)
            exec "$@"
            ;;
        backup)
            backup
            ;;
        restore)
            restore "$@"
            ;;
        monitor)
            monitor
            ;;
        update)
            update
            ;;
        help|--help|-h)
            help
            ;;
        *)
            print_error "Comando inválido: $1"
            help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
