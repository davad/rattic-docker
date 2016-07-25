# Quickstart

Note that this is not a production setup, but it is very close. Just change the
configuration a bit to you liking.

    docker-compose up
    # when it is up, open a new terminal and:
    docker-compose run rattic deploy
    docker-compose run rattic demosetup

# Configuration

Look at the env vars available in the `Dockerfile` and `entrypoint.sh`.
