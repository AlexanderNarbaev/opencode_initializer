#!/usr/bin/env python3
"""
tests/integration/test_infra_containers.py
Integration tests using Testcontainers for PostgreSQL and Redis.

Usage:
    source .venv-test/bin/activate
    pytest tests/integration/test_infra_containers.py -v

Requirements:
    pip install 'testcontainers[postgres,redis]'
    Docker daemon running
"""
import os
import sys
import subprocess
import pytest

# Skip if Docker is not available
try:
    import docker
    client = docker.from_env()
    client.ping()
    HAS_DOCKER = True
except Exception:
    HAS_DOCKER = False

pytestmark = pytest.mark.skipif(not HAS_DOCKER, reason="Docker not available")


class TestPostgresContainer:
    """Test PostgreSQL container startup and basic connectivity."""

    def test_postgres_starts_and_accepts_connections(self):
        """Verify PostgreSQL container starts and accepts connections."""
        from testcontainers.postgres import PostgresContainer

        with PostgresContainer("postgres:17-alpine") as postgres:
            # Get connection details
            host = postgres.get_container_host_ip()
            port = postgres.get_exposed_port(5432)
            user = postgres.username
            password = postgres.password
            db = postgres.dbname

            # Verify we can connect using psql
            url = f"postgresql://{user}:{password}@{host}:{port}/{db}"
            result = subprocess.run(
                ["psql", url, "-c", "SELECT 1;"],
                capture_output=True, text=True, timeout=10
            )
            assert result.returncode == 0
            assert "1" in result.stdout

    def test_postgres_creates_database(self):
        """Verify PostgreSQL container creates the specified database."""
        from testcontainers.postgres import PostgresContainer

        with PostgresContainer("postgres:17-alpine") as postgres:
            host = postgres.get_container_host_ip()
            port = postgres.get_exposed_port(5432)
            user = postgres.username
            password = postgres.password
            db = postgres.dbname

            url = f"postgresql://{user}:{password}@{host}:{port}/{db}"
            result = subprocess.run(
                ["psql", url, "-c", "\\l"],
                capture_output=True, text=True, timeout=10
            )
            assert result.returncode == 0
            # The default database should exist
            assert db in result.stdout


class TestRedisContainer:
    """Test Redis container startup and basic connectivity."""

    def test_redis_starts_and_responds_to_ping(self):
        """Verify Redis container starts and responds to PING."""
        from testcontainers.redis import RedisContainer

        with RedisContainer("redis:7-alpine") as redis:
            host = redis.get_container_host_ip()
            port = redis.get_exposed_port(6379)

            # Verify we can connect using redis-cli
            result = subprocess.run(
                ["redis-cli", "-h", host, "-p", str(port), "ping"],
                capture_output=True, text=True, timeout=10
            )
            assert result.returncode == 0
            assert "PONG" in result.stdout

    def test_redis_set_and_get(self):
        """Verify Redis container can SET and GET values."""
        from testcontainers.redis import RedisContainer

        with RedisContainer("redis:7-alpine") as redis:
            host = redis.get_container_host_ip()
            port = redis.get_exposed_port(6379)

            # SET a value
            result = subprocess.run(
                ["redis-cli", "-h", host, "-p", str(port), "SET", "testkey", "testvalue"],
                capture_output=True, text=True, timeout=10
            )
            assert result.returncode == 0
            assert "OK" in result.stdout

            # GET the value
            result = subprocess.run(
                ["redis-cli", "-h", host, "-p", str(port), "GET", "testkey"],
                capture_output=True, text=True, timeout=10
            )
            assert result.returncode == 0
            assert "testvalue" in result.stdout


class TestQdrantContainer:
    """Test Qdrant container startup and basic connectivity."""

    def test_qdrant_starts_and_responds_to_health(self):
        """Verify Qdrant container starts and responds to health check."""
        import requests
        import time
        from testcontainers.core.container import DockerContainer

        container = DockerContainer("qdrant/qdrant:latest")
        container.with_exposed_ports(6333)

        with container as qdrant:
            host = qdrant.get_container_host_ip()
            port = qdrant.get_exposed_port(6333)

            # Wait for Qdrant to start (it needs a few seconds)
            for attempt in range(10):
                try:
                    response = requests.get(f"http://{host}:{port}/healthz", timeout=5)
                    if response.status_code == 200:
                        break
                except Exception:
                    time.sleep(1)
            else:
                pytest.fail("Qdrant did not start within 10 seconds")

            assert response.status_code == 200

    def test_qdrant_creates_collection(self):
        """Verify Qdrant container can create a collection."""
        import requests
        import time
        from testcontainers.core.container import DockerContainer

        container = DockerContainer("qdrant/qdrant:latest")
        container.with_exposed_ports(6333)

        with container as qdrant:
            host = qdrant.get_container_host_ip()
            port = qdrant.get_exposed_port(6333)

            # Wait for Qdrant to start
            for attempt in range(10):
                try:
                    response = requests.get(f"http://{host}:{port}/healthz", timeout=5)
                    if response.status_code == 200:
                        break
                except Exception:
                    time.sleep(1)
            else:
                pytest.fail("Qdrant did not start within 10 seconds")

            # Create collection
            response = requests.put(
                f"http://{host}:{port}/collections/test_collection",
                json={
                    "vectors": {
                        "size": 4,
                        "distance": "Cosine"
                    }
                },
                timeout=10
            )
            assert response.status_code == 200

            # List collections
            response = requests.get(f"http://{host}:{port}/collections", timeout=10)
            assert response.status_code == 200
            assert "test_collection" in response.text


class TestContainerPortCollision:
    """Test port collision detection logic."""

    def test_port_collision_detection(self):
        """Verify that port collision detection works with real containers."""
        from testcontainers.redis import RedisContainer

        with RedisContainer("redis:7-alpine") as redis:
            host = redis.get_container_host_ip()
            port = redis.get_exposed_port(6379)

            # Run the port detection script
            project_dir = os.environ.get(
                "PROJECT_DIR",
                os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            )
            script = f"""
            source "{project_dir}/src/lib/helpers.sh" 2>/dev/null
            source "{project_dir}/src/lib/00-core.sh" 2>/dev/null
            if _port_is_free {port}; then
                echo "FREE"
            else
                echo "BOUND"
            fi
            """
            result = subprocess.run(
                ["bash", "-c", script],
                capture_output=True, text=True, timeout=30
            )
            assert "BOUND" in result.stdout


class TestContainerCleanup:
    """Verify containers are properly cleaned up after tests."""

    def test_no_orphan_containers(self):
        """Verify no test containers are left running after previous tests."""
        result = subprocess.run(
            ["docker", "ps", "-a", "--filter", "label=testcontainers", "--format", "{{.Names}}"],
            capture_output=True, text=True, timeout=10
        )
        # Should be empty (testcontainers cleans up automatically)
        assert result.stdout.strip() == ""


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
