# Foundry VTT — ambiente minimale per sviluppo moduli

[English](README.md) · **Italiano**

Versione minimale di [base-v2](https://github.com/p4535992/foundryvtt-docker-compose-base-v2): un'unica istanza Foundry03, dati e log persistenti e una licenza Foundry. Nessun proxy, DuckDNS, database, relay, bot o container di backup.

## Avvio

Requisiti: Linux o WSL2 con Docker, Docker Compose v2, Bash, Python 3 e sudo se necessario per i permessi.

```bash
./start_all.sh
```

Al primo avvio viene creato `.env` con permessi 0600. Compila le quattro credenziali Foundry e rilancia il comando. Lo script genera Compose e il secret privato, prepara le directory persistenti e avvia un solo container. A ogni avvio ricrea il container per applicare eventuali cambiamenti di configurazione e credenziali; i dati restano sul disco.

Apri **http://localhost:30000/** e crea un mondo di test. La porta è limitata a localhost; per un server remoto usa un tunnel SSH:

```bash
ssh -L 30000:127.0.0.1:30000 user@server
```

```bash
./down_all.sh
docker compose ps
docker compose logs -f foundry03
```

## Sviluppo dei moduli

Le directory mantengono la struttura della v2:

- `foundry03/data/Data/modules/`: moduli
- `foundry03/data/Data/systems/`: sistemi
- `foundry03/data/Data/worlds/`: mondi
- `foundry03/logs/`: log

Compila il modulo nel suo repository e copia il risultato (con `module.json` nella radice) tramite lo script locale opzionale, che richiede rsync:

```bash
/path/to/stack/scripts/testing/deploy-module03.sh ./dist --dry-run
/path/to/stack/scripts/testing/deploy-module03.sh ./dist
```

Lo script sincronizza esclusivamente la cartella del modulo individuato dal manifest, eliminando eventuali file obsoleti in quella cartella. Conserva i sorgenti nel repository del modulo. In alternativa configura il watcher della build direttamente in `foundry03/data/Data/modules/<id>/`. Le modifiche sono visibili senza ricostruire Docker: ricarica il browser o, quando necessario, riavvia Foundry.

Per i permessi delle directory usa l'utente host UID/GID 1000; se necessario esegui `sudo bash scripts/prepare_runtime.sh` per preparare le sole directory, senza modificare ricorsivamente i dati. [Guida testing](scripts/testing/README.md).

## Configurazione

- Il tag Foundry predefinito è `14`, come l'istanza di sviluppo v2. Puoi fissare un tag compatibile preciso in `.env`.
- `FOUNDRY03_HOST_PORT` consente di cambiare la porta host; `FOUNDRY03_BIND_IP` è 127.0.0.1 per impostazione predefinita. Nessun TLS: non esporre pubblicamente l'ambiente di sviluppo.
- Il nome progetto Compose è `foundryvtt-dev`, distinto dalla v2.
- Non pubblicare `.env`, secret, dati, log o sessioni browser.
- Non sono presenti backup infrastrutturali automatici. I backup nativi di Foundry restano abilitati; arresta Foundry prima di una copia manuale dei dati.
