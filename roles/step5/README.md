 <h1 align="center">Step 5</h1>

## Descrizione
Realizzare un ambiente in cui Jenkins, tramite una pipeline, costruisce un'immagine Docker, la pubblica su un Docker Registry e utilizza Ansible per la gestione e il deploy del container.

L'esercizio prevede inoltre la configurazione di un container Rocky Linux che, oltre ai requisiti dello Step 2, dispone di:
- SSH
- utente `genericuser` con privilegi sudo
- Docker Engine e Docker CLI
- servizio `dockerd` attivo all'interno del container

La pipeline Jenkins deve inoltre:
- costruire un'immagine Docker
- utilizzare un tag progressivo basato sul numero della build Jenkins
- pubblicare l'immagine sul Docker Registry
- utilizzare Ansible per eseguire il deploy dell'immagine sul container precedentemente creato

## Architettura dell'ambiente
L'ambiente è composto dai seguenti elementi:
- Jenkins Controller: gestisce le pipeline Jenkins
- Nodo Jenkins `step5-agent`: esegue le operazioni della pipeline e dispone della Docker CLI
- VM Vagrant: ospita Docker Engine e il Docker Registry
- Docker Registry: conserva le immagini Docker pubblicate dalla pipeline
- Container `step5-docker`: viene creato sulla VM e costituisce il target del deploy Ansible. Il container contiene SSH, l'utente `genericuser` con privilegi sudo e Docker Engine con `dockerd` attivo.

Il Docker Registry utilizzato dal ruolo è raggiungibile tramite:
```
192.168.56.112:5002
```

Il registry utilizza la porta `5002` sulla VM e la porta `5000` all'interno del container Registry.

## Struttura del role
La struttura del role `step5` è organizzata nel seguente modo:
```
step5/
├── README.md
├── defaults/
│   └── main.yml
├── files/
│   ├── Dockerfile
│   ├── Jenkinsfile
│   └── docker-entrypoint.sh
├── handlers/
│   └── main.yml
└── tasks/
    ├── main.yml
    ├── docker.yml
    ├── registry-docker.yml
    └── container-docker.yml
```

I parametri principali del role sono definiti nel file `defaults/main.yml`.
Questi parametri permettono di configurare:
- nome e immagine del container
- tag dell'immagine
- porta SSH esposta dalla VM
- porta SSH interna al container
- rete Docker
- nome del container Registry
- indirizzo del Registry
- porta del Registry

## Dockerfile
Il `Dockerfile` presente in `/files` definisce l'immagine utilizzata per il container `step5-docker`.

L'immagine parte da:
```
rockylinux:9
```
e installa:
- `openssh-server`
- `sudo`
- `docker-ce`
- `docker-ce-cli`
- `containerd.io`
- `docker-buildx-plugin`
- `docker-compose-plugin`

Viene inoltre creato l'utente:
```
genericuser
```
con privilegi sudo senza richiesta della password.

La configurazione SSH:
- disabilita il login dell'utente `root`
- disabilita l'autenticazione tramite password
- abilita l'autenticazione tramite chiave pubblica
- permette l'accesso SSH esclusivamente a `genericuser`

La chiave pubblica viene copiata nel container come:
```
/home/genericuser/.ssh/authorized_keys
```

La chiave utilizzata viene generata dal playbook sulla VM Vagrant controller:
```
/home/vagrant/.ssh/id-genericuser
/home/vagrant/.ssh/id-genericuser.pub
```
La chiave privata rimane sulla VM controller e non viene inserita nell'immagine Docker.

## Avvio del container
Il file `docker-entrypoint.sh` viene utilizzato come entrypoint del container.

Lo script:
1. avvia il servizio SSH in background;
2. avvia `dockerd` in foreground.

Il contenuto dell'entrypoint è quindi:
```
sshd
  ↓
dockerd
```

L'esecuzione di `dockerd` in foreground permette al processo Docker di rimanere attivo e mantiene in esecuzione il container.

Il container deve quindi mantenere contemporaneamente attivi:
- il servizio SSH
- il Docker Engine

## Pipeline Jenkins
La pipeline Jenkins è definita nel file:
```
/files/Jenkinsfile
```

La pipeline utilizza il nodo Jenkins:
```
step5-agent
```
e prevede due stage:
```
Build image
Push image
```

`Build image`
Lo stage `Build image` deve costruire l'immagine Docker utilizzando il `Dockerfile` e assegnarle un tag progressivo basato sul numero della build Jenkins.

Il tag viene generato utilizzando:
```
${BUILD_NUMBER}
```

L'immagine viene quindi identificata dal Registry come:
```
192.168.56.112:5002/step5-docker:${BUILD_NUMBER}
```

`Push image`
Lo stage `Push image` pubblica l'immagine sul Docker Registry:
```
docker push 192.168.56.112:5002/step5-docker:${BUILD_NUMBER}
```
In questo modo ogni build Jenkins produce un'immagine con un tag differente.

## Verifiche
Per verificare che Docker sia attivo sulla VM:
```
docker ps
```
Il comando deve essere eseguito senza errori e deve mostrare i container in esecuzione.

Per verificare che il Registry sia attivo:
```
docker ps
```
output atteso:
```
registry_d
```

Il Registry è esposto sulla porta:
```
5002
```

Per verificare il container creato dal role:
```
docker ps
```
output atteso:
```
step5-docker
```
con la porta:
```
2227 -> 22
```

Per verificare che il Docker Engine sia attivo all'interno del container:
```
docker exec step5-docker docker ps
```
Se il comando restituisce la lista dei container, il `dockerd` interno al container è attivo e la Docker CLI riesce a comunicare con esso.

La chiave SSH viene generata sulla VM Vagrant controller:
```
/home/vagrant/.ssh/id-genericuser
/home/vagrant/.ssh/id-genericuser.pub
```
La chiave pubblica viene inserita nel container durante la build dell'immagine.

Per verificare l'accesso SSH al container è possibile utilizzare la chiave privata presente sulla VM controller:
```
ssh -i /home/vagrant/.ssh/id-genericuser -p 2227 genericuser@192.168.56.112
```
Il collegamento utilizza:
```
192.168.56.112:2227
```
che viene inoltrato alla porta SSH `22` del container `step5-docker`.

Dopo aver effettuato l'accesso SSH al container:
```
docker ps
```
Il comando deve riuscire a comunicare con il Docker Engine interno al container.

È inoltre possibile verificare direttamente il processo:
```
ps aux | grep dockerd
```
Il processo `dockerd` deve risultare attivo.


Dopo l'esecuzione della pipeline Jenkins, le immagini generate devono essere presenti sul Registry.
Il formato utilizzato è:
```
192.168.56.112:5002/step5-docker:<BUILD_NUMBER>
```