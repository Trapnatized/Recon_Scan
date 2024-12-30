# Install & Build
```
https://github.com/Trapnatized/Recon_Scan.git
cd Recon_Scan
docker compose build
```

# Interactive Mode (Manual)
`docker compose run --rm recon`

![alt text](screenshots/image-1.png)

# Scanning with domain-list.txt
Create a domain-list.txt & put inside data folder or edit roots.txt.

The file structure should look like this
```
├── data
│   └── roots.txt
├── docker-compose.yml
├── Dockerfile
├── README.md
└── recon.sh
```

Then call the domain-list.txt

`docker compose run --rm recon roots.txt`

![alt text](screenshots/image.png)

# Debugging
`docker compose run --rm -it --entrypoint bash recon`

![alt text](screenshots/image-2.png)


# Adding API keys
Uncomment line(s) and add API key(s) to .env file.

Then add variable(s) to provider-config.yaml in configs/*/

``` 
shodan: [$shodan_API_KEY]
censys: []
fofa: []
quake: []
hunter: []
zoomeye: []
netlas: []
criminalip: []
publicwww: []
hunterhow: []
google: []
```

Lastly update the docker-compose.yml to include the .env variable(s)

```
    environment:
      - THREADS=10
      - OUTPUT_DIR=/output
      - SHODAN_API_KEY=${shodan_API_KEY}
    env_file:
      - .env
```

To verify the API key was set correctly you could 

```
docker compose run --rm -it --entrypoint bash recon
echo $SHODAN_API_KEY
```
