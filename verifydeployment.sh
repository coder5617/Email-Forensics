#!/bin/bash

# EmailForensics - Deployment Verification Script
# Comprehensive health checks with style! 🔍

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Score tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# Test results array
declare -a TEST_RESULTS

# Banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║     🔍 EmailForensics Deployment Verification 🔍            ║"
    echo "║            Comprehensive Health Check Suite                 ║"
    echo "║                    Version 2.0                               ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print section header
print_section() {
    echo
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Test function
run_test() {
    local test_name=$1
    local test_command=$2
    local expected_result=$3
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n -e "${CYAN}  🧪 Testing: ${WHITE}${test_name}${NC}"
    
    # Add dots for alignment
    local dots=""
    local name_length=${#test_name}
    local max_length=40
    if [ $name_length -lt $max_length ]; then
        for ((i=name_length; i<max_length; i++)); do
            dots="${dots}."
        done
    fi
    echo -n -e "${CYAN}${dots}${NC}"
    
    # Run the test
    if eval $test_command > /dev/null 2>&1; then
        echo -e " ${GREEN}✅ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("✅ ${test_name}")
        return 0
    else
        echo -e " ${RED}❌ FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("❌ ${test_name}")
        return 1
    fi
}

# Warning function
print_warning() {
    local message=$1
    echo -e "${YELLOW}  ⚠️  WARNING: ${message}${NC}"
    WARNINGS=$((WARNINGS + 1))
}

# Info function
print_info() {
    local emoji=$1
    local message=$2
    echo -e "${BLUE}  ${emoji} ${message}${NC}"
}

# Check Docker status
check_docker_status() {
    print_section "🐳 Docker Environment"
    
    run_test "Docker daemon running" "docker info" ""
    run_test "Docker Compose installed" "docker-compose --version" ""
    
    # Check Docker resources
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_info "📦" "Docker version: ${docker_version}"
        
        # Check disk space
        local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
        if [ $disk_usage -gt 80 ]; then
            print_warning "Disk usage is high: ${disk_usage}%"
        else
            print_info "💾" "Disk usage: ${disk_usage}%"
        fi
    fi
}

# Check container status
check_container_status() {
    print_section "📦 Container Status"
    
    run_test "EmailForensics container exists" "docker ps -a | grep emailforensics_app" ""
    run_test "EmailForensics container running" "docker ps | grep emailforensics_app" ""
    
    if docker ps | grep emailforensics_app > /dev/null 2>&1; then
        # Get container stats
        local container_id=$(docker ps | grep emailforensics_app | awk '{print $1}')
        local cpu_usage=$(docker stats --no-stream $container_id --format "{{.CPUPerc}}" 2>/dev/null)
        local mem_usage=$(docker stats --no-stream $container_id --format "{{.MemUsage}}" 2>/dev/null)
        
        print_info "⚡" "CPU Usage: ${cpu_usage}"
        print_info "🧠" "Memory Usage: ${mem_usage}"
        
        # Check container health
        local health=$(docker inspect $container_id --format='{{.State.Status}}' 2>/dev/null)
        if [ "$health" == "running" ]; then
            print_info "💚" "Container health: Running"
        else
            print_warning "Container status: ${health}"
        fi
    fi
}

# Check application endpoints
check_application_endpoints() {
    print_section "🌐 Application Endpoints"
    
    run_test "Homepage accessible (HTTP 200)" "curl -s -o /dev/null -w '%{http_code}' http://localhost:5000 | grep -q '200'" ""
    run_test "Static CSS accessible" "curl -s -o /dev/null -w '%{http_code}' http://localhost:5000/static/css/style.css | grep -q '200'" ""
    
    # Check response time
    if command -v curl &> /dev/null; then
        local response_time=$(curl -s -o /dev/null -w '%{time_total}' http://localhost:5000 2>/dev/null)
        local response_ms=$(echo "$response_time * 1000" | bc 2>/dev/null | cut -d'.' -f1)
        
        if [ ! -z "$response_ms" ]; then
            if [ "$response_ms" -lt 500 ]; then
                print_info "⚡" "Response time: ${response_ms}ms (Excellent)"
            elif [ "$response_ms" -lt 1000 ]; then
                print_info "🔄" "Response time: ${response_ms}ms (Good)"
            else
                print_warning "Response time: ${response_ms}ms (Slow)"
            fi
        fi
    fi
}

# Check file structure
check_file_structure() {
    print_section "📁 File Structure"
    
    local required_files=(
        "app.py"
        "requirements.txt"
        "Dockerfile"
        "docker-compose.yml"
        "templates/index.html"
        "templates/results.html"
        "static/css/style.css"
        "README.md"
    )
    
    for file in "${required_files[@]}"; do
        run_test "File exists: $file" "[ -f EmailForensics/$file ]" ""
    done
    
    # Check file permissions
    if [ -d "EmailForensics" ]; then
        local file_count=$(find EmailForensics -type f | wc -l)
        local dir_count=$(find EmailForensics -type d | wc -l)
        print_info "📊" "Total files: ${file_count}, Total directories: ${dir_count}"
    fi
}

# Check network connectivity
check_network() {
    print_section "🌍 Network Connectivity"
    
    run_test "DNS resolution (google.com)" "nslookup google.com" ""
    run_test "IPInfo API accessible" "curl -s https://ipinfo.io/8.8.8.8/json | grep -q 'Google'" ""
    run_test "Port 5000 listening" "netstat -tuln 2>/dev/null | grep -q ':5000' || lsof -i :5000" ""
}

# Check Python dependencies
check_dependencies() {
    print_section "📦 Python Dependencies"
    
    if docker ps | grep emailforensics_app > /dev/null 2>&1; then
        local container_id=$(docker ps | grep emailforensics_app | awk '{print $1}')
        
        # Check installed packages
        local packages=("flask" "dnspython" "requests")
        for package in "${packages[@]}"; do
            run_test "Python package: $package" "docker exec $container_id pip show $package" ""
        done
    else
        print_warning "Container not running - skipping dependency checks"
    fi
}

# Check logs
check_logs() {
    print_section "📋 Application Logs"
    
    if docker ps | grep emailforensics_app > /dev/null 2>&1; then
        local container_id=$(docker ps | grep emailforensics_app | awk '{print $1}')
        local log_lines=$(docker logs $container_id 2>&1 | wc -l)
        
        print_info "📝" "Log entries: ${log_lines} lines"
        
        # Check for errors in logs
        local error_count=$(docker logs $container_id 2>&1 | grep -i error | wc -l)
        if [ $error_count -gt 0 ]; then
            print_warning "Found ${error_count} error(s) in logs"
        else
            print_info "✨" "No errors found in logs"
        fi
        
        # Show last 5 log entries
        echo -e "${CYAN}  📜 Recent log entries:${NC}"
        docker logs --tail 5 $container_id 2>&1 | sed 's/^/    /'
    else
        print_warning "Container not running - cannot check logs"
    fi
}

# Performance test
check_performance() {
    print_section "⚡ Performance Metrics"
    
    if command -v curl &> /dev/null; then
        # Run multiple requests
        local total_time=0
        local requests=10
        
        echo -e "${CYAN}  🏃 Running performance test (${requests} requests)...${NC}"
        
        for i in $(seq 1 $requests); do
            local response_time=$(curl -s -o /dev/null -w '%{time_total}' http://localhost:5000 2>/dev/null)
            total_time=$(echo "$total_time + $response_time" | bc 2>/dev/null)
            echo -n "."
        done
        echo
        
        if [ ! -z "$total_time" ]; then
            local avg_time=$(echo "scale=3; $total_time / $requests" | bc 2>/dev/null)
            local avg_ms=$(echo "$avg_time * 1000" | bc 2>/dev/null | cut -d'.' -f1)
            
            if [ ! -z "$avg_ms" ]; then
                if [ "$avg_ms" -lt 100 ]; then
                    print_info "🚀" "Average response time: ${avg_ms}ms (Excellent!)"
                elif [ "$avg_ms" -lt 500 ]; then
                    print_info "✅" "Average response time: ${avg_ms}ms (Good)"
                else
                    print_warning "Average response time: ${avg_ms}ms (Needs optimization)"
                fi
            fi
        fi
    fi
}

# Security checks
check_security() {
    print_section "🔒 Security Configuration"
    
    # Check if debug mode is disabled
    if [ -f "EmailForensics/app.py" ]; then
        if grep -q "debug=True" EmailForensics/app.py; then
            print_warning "Debug mode is enabled in app.py"
            TEST_RESULTS+=("⚠️ Debug mode enabled")
        else
            echo -e "${CYAN}  🧪 Testing: ${WHITE}Debug mode disabled..................${NC} ${GREEN}✅ PASS${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
            TEST_RESULTS+=("✅ Debug mode disabled")
        fi
    fi
    
    # Check for .env file
    run_test "Environment file exists" "[ -f EmailForensics/.env ] || [ -f EmailForensics/.env.example ]" ""
    
    # Check HTTPS recommendation
    print_info "💡" "Recommendation: Use HTTPS in production with SSL certificates"
}

# Generate summary report
generate_summary() {
    print_section "📊 Verification Summary Report"
    
    # Calculate success rate
    local success_rate=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        success_rate=$(echo "scale=1; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc 2>/dev/null)
    fi
    
    # System info
    echo -e "${BLUE}  💻 System Information:${NC}"
    echo -e "     OS: $(uname -s) $(uname -r)"
    echo -e "     Hostname: $(hostname)"
    echo -e "     Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    
    # Test results
    echo -e "${BLUE}  📈 Test Results:${NC}"
    echo -e "     Total Tests: ${TOTAL_TESTS}"
    echo -e "     Passed: ${GREEN}${PASSED_TESTS}${NC}"
    echo -e "     Failed: ${RED}${FAILED_TESTS}${NC}"
    echo -e "     Warnings: ${YELLOW}${WARNINGS}${NC}"
    echo -e "     Success Rate: ${success_rate}%"
    echo
    
    # Progress bar
    echo -e "${BLUE}  📊 Success Rate:${NC}"
    echo -n "     ["
    local bar_length=40
    local filled_length=$(echo "$bar_length * $PASSED_TESTS / $TOTAL_TESTS" | bc 2>/dev/null)
    
    for ((i=0; i<$bar_length; i++)); do
        if [ $i -lt $filled_length ]; then
            echo -n -e "${GREEN}█${NC}"
        else
            echo -n -e "${WHITE}░${NC}"
        fi
    done
    echo "] ${success_rate}%"
    echo
    
    # Overall status
    echo -e "${BLUE}  🎯 Overall Status:${NC}"
    if [ $FAILED_TESTS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "     ${GREEN}✨ EXCELLENT - All systems operational!${NC}"
        echo -e "     ${GREEN}🎉 EmailForensics is fully deployed and healthy!${NC}"
    elif [ $FAILED_TESTS -eq 0 ] && [ $WARNINGS -gt 0 ]; then
        echo -e "     ${YELLOW}👍 GOOD - System operational with minor warnings${NC}"
        echo -e "     ${YELLOW}📝 Review warnings for optimal performance${NC}"
    elif [ $FAILED_TESTS -le 2 ]; then
        echo -e "     ${YELLOW}⚠️ FAIR - System mostly operational${NC}"
        echo -e "     ${YELLOW}🔧 Some components need attention${NC}"
    else
        echo -e "     ${RED}❌ CRITICAL - Multiple components failing${NC}"
        echo -e "     ${RED}🚨 Immediate attention required!${NC}"
    fi
}

# Generate detailed report file
generate_report_file() {
    local report_file="EmailForensics/verification_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "EmailForensics Deployment Verification Report"
        echo "============================================="
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "Test Results:"
        echo "-------------"
        for result in "${TEST_RESULTS[@]}"; do
            echo "  $result"
        done
        echo ""
        echo "Summary:"
        echo "--------"
        echo "  Total Tests: $TOTAL_TESTS"
        echo "  Passed: $PASSED_TESTS"
        echo "  Failed: $FAILED_TESTS"
        echo "  Warnings: $WARNINGS"
        echo "  Success Rate: ${success_rate}%"
    } > "$report_file"
    
    print_info "💾" "Detailed report saved to: ${report_file}"
}

# Interactive mode
interactive_menu() {
    print_section "🎮 Interactive Options"
    
    echo -e "${CYAN}  What would you like to do?${NC}"
    echo -e "    1) View container logs"
    echo -e "    2) Restart EmailForensics"
    echo -e "    3) Stop EmailForensics"
    echo -e "    4) Generate detailed report"
    echo -e "    5) Exit"
    echo
    read -p "$(echo -e ${CYAN}  Select option [1-5]: ${NC})" choice
    
    case $choice in
        1)
            echo -e "${BLUE}📋 Container Logs:${NC}"
            docker logs emailforensics_app --tail 50
            ;;
        2)
            echo -e "${YELLOW}🔄 Restarting EmailForensics...${NC}"
            cd EmailForensics && docker-compose restart
            ;;
        3)
            echo -e "${RED}🛑 Stopping EmailForensics...${NC}"
            cd EmailForensics && docker-compose down
            ;;
        4)
            generate_report_file
            ;;
        5)
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            ;;
    esac
}

# Main execution
main() {
    clear
    print_banner
    
    echo -e "${PURPLE}🚀 Starting EmailForensics Deployment Verification...${NC}"
    echo -e "${PURPLE}⏱️  This may take a few moments...${NC}"
    
    # Run all checks
    check_docker_status
    check_container_status
    check_application_endpoints
    check_file_structure
    check_network
    check_dependencies
    check_logs
    check_performance
    check_security
    
    # Generate summary
    generate_summary
    
    # Ask for interactive options
    echo
    read -p "$(echo -e ${CYAN}❓ Would you like to access interactive options? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        interactive_menu
    fi
    
    echo
    echo -e "${GREEN}✅ Verification complete!${NC}"
    echo -e "${CYAN}🔍 Thank you for using EmailForensics Verification Suite!${NC}"
}

# Check if running in EmailForensics directory
if [ ! -d "EmailForensics" ]; then
    echo -e "${RED}❌ Error: EmailForensics directory not found!${NC}"
    echo -e "${YELLOW}💡 Please run this script from the parent directory of EmailForensics${NC}"
    exit 1
fi

# Run main function
main