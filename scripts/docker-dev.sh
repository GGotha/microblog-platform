#!/bin/bash

# Script para gerenciar ambiente de desenvolvimento Docker
# Uso: ./scripts/docker-dev.sh [comando]

set -e

COMPOSE_FILE="docker-compose.dev.yml"

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

# Função para verificar se o arquivo .env existe
check_env_file() {
    if [ ! -f .env ]; then
        print_warning "Arquivo .env não encontrado. Criando a partir do exemplo..."
        if [ -f env.example ]; then
            cp env.example .env
            print_message "Arquivo .env criado. Edite-o conforme necessário."
        else
            print_error "Arquivo env.example não encontrado."
            exit 1
        fi
    fi
}

# Função para verificar portas em uso
check_ports() {
    local ports=("3000" "3001" "3002" "3003" "3004" "3005" "3006" "3007" "3008" "5432" "5433" "5434" "27017" "27018")
    
    for port in "${ports[@]}"; do
        if lsof -i :$port > /dev/null 2>&1; then
            print_warning "Porta $port está em uso. Verifique se não há outros serviços rodando."
        fi
    done
}

# Função para iniciar serviços
start() {
    print_header "Iniciando ambiente de desenvolvimento"
    check_docker
    check_env_file
    check_ports
    
    print_message "Iniciando serviços..."
    docker-compose -f $COMPOSE_FILE up -d
    
    print_message "Aguardando serviços ficarem prontos..."
    sleep 10
    
    print_message "Verificando status dos serviços..."
    docker-compose -f $COMPOSE_FILE ps
    
    print_message "Ambiente de desenvolvimento iniciado!"
    print_message "Gateway: http://localhost:3000"
    print_message "Grafana: http://localhost:3010 (admin/admin)"
    print_message "Prometheus: http://localhost:9090"
    print_message "MailHog: http://localhost:8025"
}

# Função para parar serviços
stop() {
    print_header "Parando ambiente de desenvolvimento"
    docker-compose -f $COMPOSE_FILE down
    print_message "Ambiente de desenvolvimento parado!"
}

# Função para reiniciar serviços
restart() {
    print_header "Reiniciando ambiente de desenvolvimento"
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

# Função para limpar tudo
clean() {
    print_header "Limpando ambiente de desenvolvimento"
    print_warning "Isso irá remover todos os containers, volumes e imagens!"
    read -p "Tem certeza? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose -f $COMPOSE_FILE down -v --rmi all
        docker system prune -f
        print_message "Limpeza concluída!"
    else
        print_message "Operação cancelada."
    fi
}

# Função para mostrar ajuda
help() {
    print_header "Comandos disponíveis"
    echo "start     - Iniciar ambiente de desenvolvimento"
    echo "stop      - Parar ambiente de desenvolvimento"
    echo "restart   - Reiniciar ambiente de desenvolvimento"
    echo "rebuild   - Rebuild de todos os serviços"
    echo "logs      - Mostrar logs (opcional: especificar serviço)"
    echo "status    - Mostrar status dos serviços"
    echo "exec      - Executar comando em um serviço"
    echo "clean     - Limpar tudo (containers, volumes, imagens)"
    echo "help      - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 start"
    echo "  $0 logs auth-service"
    echo "  $0 exec auth-service sh"
    echo "  $0 rebuild"
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
        clean)
            clean
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
