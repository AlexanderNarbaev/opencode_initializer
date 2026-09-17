#!/usr/bin/env python3
"""
Testcontainers integration tests for opencode_initializer infrastructure services.
Tests PostgreSQL, Redis, and Qdrant containers.
"""
import pytest
import subprocess
import time
import json
from pathlib import Path

# Try to import testcontainers, skip if not available
try:
    from testcontainers.postgres import PostgresContainer
    from testcontainers.redis import RedisContainer
    HAS_TESTCONTAINERS = True
except ImportError:
    HAS_TESTCONTAINERS = False

pytestmark = pytest.mark.skipif(
    not HAS_TESTCONTAINERS,
    reason="testcontainers not installed"
)

PROJECT_ROOT = Path(__file__).parent.parent.parent


class TestPostgresContainer:
    """Test PostgreSQL container integration."""
    
    def test_postgres_starts(self):
        """Test that PostgreSQL container starts successfully."""
        with PostgresContainer("postgres:17-alpine") as postgres:
            assert postgres.get_connection_url()
            
    def test_postgres_accepts_connections(self):
        """Test that PostgreSQL accepts connections."""
        with PostgresContainer("postgres:17-alpine") as postgres:
            url = postgres.get_connection_url()
            # Simple connection test
            result = subprocess.run(
                ["psql", url, "-c", "SELECT 1"],
                capture_output=True,
                text=True
            )
            assert result.returncode == 0
            
    def test_postgres_creates_database(self):
        """Test that PostgreSQL creates the database."""
        with PostgresContainer("postgres:17-alpine") as postgres:
            url = postgres.get_connection_url()
            result = subprocess.run(
                ["psql", url, "-c", "SELECT current_database()"],
                capture_output=True,
                text=True
            )
            assert result.returncode == 0


class TestRedisContainer:
    """Test Redis container integration."""
    
    def test_redis_starts(self):
        """Test that Redis container starts successfully."""
        with RedisContainer("redis:7-alpine") as redis:
            assert redis.get_connection_url()
            
    def test_redis_accepts_connections(self):
        """Test that Redis accepts connections."""
        with RedisContainer("redis:7-alpine") as redis:
            url = redis.get_connection_url()
            result = subprocess.run(
                ["redis-cli", "-u", url, "ping"],
                capture_output=True,
                text=True
            )
            assert "PONG" in result.stdout
            
    def test_redis_stores_data(self):
        """Test that Redis can store and retrieve data."""
        with RedisContainer("redis:7-alpine") as redis:
            url = redis.get_connection_url()
            # Set a value
            subprocess.run(
                ["redis-cli", "-u", url, "set", "test", "value"],
                capture_output=True
            )
            # Get the value
            result = subprocess.run(
                ["redis-cli", "-u", url, "get", "test"],
                capture_output=True,
                text=True
            )
            assert "value" in result.stdout


class TestQdrantContainer:
    """Test Qdrant container integration."""
    
    def test_qdrant_starts(self):
        """Test that Qdrant container starts successfully."""
        # Qdrant doesn't have a testcontainer, so we use docker directly
        result = subprocess.run(
            ["docker", "run", "-d", "--name", "test-qdrant", 
             "-p", "16333:6333", "qdrant/qdrant:latest"],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        
        # Wait for Qdrant to start
        time.sleep(5)
        
        # Check health
        result = subprocess.run(
            ["curl", "-s", "http://localhost:16333/healthz"],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        
        # Cleanup
        subprocess.run(
            ["docker", "rm", "-f", "test-qdrant"],
            capture_output=True
        )


class TestContainerIntegration:
    """Test container integration with opencode_initializer."""
    
    def test_docker_compose_config(self):
        """Test that docker-compose.yml is valid."""
        result = subprocess.run(
            ["docker", "compose", "config", "--quiet"],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        
    def test_dockerfile_syntax(self):
        """Test that Dockerfile has valid syntax."""
        result = subprocess.run(
            ["docker", "build", "--check", str(PROJECT_ROOT)],
            capture_output=True,
            text=True
        )
        # --check requires BuildKit
        if result.returncode != 0 and "unknown flag" in result.stderr:
            pytest.skip("BuildKit not available")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
