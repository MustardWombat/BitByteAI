#!/bin/bash

# Path to virtual environment - update this to match your environment path
VENV_PATH="$(dirname "$0")/venv"
PROJECT_DIR="$(dirname "$0")"
SERVER_DIR="$PROJECT_DIR"

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Ensure script exits on error
set -e

# Function to activate virtual environment
activate_venv() {
    echo -e "${YELLOW}Activating virtual environment...${NC}"
    if [ ! -d "$VENV_PATH" ]; then
        echo -e "${RED}Virtual environment not found at $VENV_PATH${NC}"
        echo -e "Creating new virtual environment..."
        python3 -m venv "$VENV_PATH"
    fi
    
    # Source the activate script
    source "$VENV_PATH/bin/activate" || {
        echo -e "${RED}Failed to activate virtual environment${NC}"
        exit 1
    }
    
    echo -e "${GREEN}Using Python: $(which python)${NC}"
    echo -e "${GREEN}Python version: $(python --version)${NC}"
}

# Function to install dependencies
install_deps() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install --upgrade pip
    pip install setuptools wheel
    
    # Try installing packages separately to handle failures better
    pip install --prefer-binary numpy || echo -e "${RED}Failed to install numpy${NC}"
    pip install --prefer-binary scikit-learn || echo -e "${RED}Failed to install scikit-learn${NC}"
    pip install --prefer-binary Flask requests || echo -e "${RED}Failed to install Flask/requests${NC}"
    
    # Try pandas separately as it might have build issues
    pip install --prefer-binary pandas || echo -e "${YELLOW}Warning: pandas installation failed${NC}"
    
    # Try coremltools but don't fail if it doesn't work
    pip install --prefer-binary coremltools || echo -e "${YELLOW}Warning: coremltools installation failed${NC}"
    
    echo -e "${GREEN}Installed packages:${NC}"
    pip list
}

# Function to run a Python script in the venv
run_script() {
    if [ -z "$1" ]; then
        echo -e "${RED}No script specified${NC}"
        exit 1
    fi
    
    SCRIPT="$1"
    shift # Remove the script name from arguments
    
    echo -e "${YELLOW}Running $SCRIPT...${NC}"
    python "$SERVER_DIR/$SCRIPT" "$@"
}

# Function to display help
show_help() {
    echo "Usage: ./manage.sh [command] [args]"
    echo ""
    echo "Commands:"
    echo "  install      Install dependencies"
    echo "  generate     Generate sample data"
    echo "  train        Train model"
    echo "  deploy       Run full deployment"
    echo "  server       Start prediction API server"
    echo "  test         Test the API"
    echo "  help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./manage.sh install"
    echo "  ./manage.sh deploy"
    echo "  ./manage.sh deploy --restart-only"
}

# Main execution logic
if [ -z "$1" ]; then
    show_help
    exit 0
fi

# Always activate venv first (except for help)
if [ "$1" != "help" ]; then
    activate_venv
fi

# Handle commands
case "$1" in
    install)
        install_deps
        ;;
    generate)
        run_script "generate_sample_data.py"
        ;;
    train)
        run_script "train_model.py"
        ;;
    deploy)
        shift # Remove 'deploy' from args
        run_script "deploy_model.py" "$@"
        ;;
    server)
        # Try prediction_api.py first, fall back to simple_prediction_api.py if it fails
        run_script "prediction_api.py" || run_script "simple_prediction_api.py"
        ;;
    test)
        run_script "test_api.py"
        ;;
    help)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac

echo -e "${GREEN}Done!${NC}"
exit 0
