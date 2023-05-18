
Follow the below steps and it'll setup SeaTable Server for you.

## User Instructions:

After creating the SeaTable Server, follow these steps to complete your setup:

1. Retrieve the public IP-address of your SeaTable instance, create an A-Record for your domain/subdomain of choice, and use the public IP-address as the record’s value.
2. Access your SeaTable instance via SSH (ssh -i your-key.pem admin@your-public-ip) and change to the directory /opt/seatable.
3. Follow our deployment instructions at https://manual.seatable.io/docker/Enterprise-Edition/Deploy%20SeaTable-EE%20with%20Docker/#downloading-and-modifying-docker-composeyml. 
4. The steps are simple: adapt the existing docker-compose.yml to your needs
5. Start the docker container twice (details are described in the manual)
6. Create a superuser and you are read to go...
