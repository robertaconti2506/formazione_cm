 <h1 align="center">Step 1</h1>
 
## Descrizione
Lo scopo di questo esercizio è configurare un ambiente con Podman e predisporre un Docker Registry privato locale.

Il Registry viene eseguito come container Podman utilizzando l'immagine ufficiale:
```
docker.io/library/registry:2
```
Il Registry viene esposto sulla porta `5000` del managed node e utilizza un volume Podman per mantenere persistenti i dati delle immagini, viene esposto tramite il port mapping: `5000:5000`.

## Struttura del Role
Il Role `step1` è organizzato nel seguente modo:
```
step1/
├── README.md
├── defaults/
│   └── main.yml
└── tasks/
    ├── main.yml
    ├── podman.yml
    └── registry-podman.yml
```

`defaults/main.yml` contiene le variabili utilizzate dal role:
```
registry_volume_name: registry_data
registry_host_port: 5000
registry_container_port: 5000
```

`tasks/main.yml` rappresenta il punto di ingresso del role e include i due file di task:
```
- name: Check Podman
  ansible.builtin.include_tasks: podman.yml

- name: Registry
  ansible.builtin.include_tasks: registry-podman.yml
```

L'esecuzione avviene quindi nel seguente ordine:
1. verifica e installazione di Podman
2. creazione del volume del Registry
3. download dell'immagine del Registry
4. avvio del container
5. configurazione del firewall

## Verifiche 
Per verificare che il container Registry sia in esecuzione (dal controller Ansible):
```
ansible -i inventory.ini rocky -m command -a "podman ps"
```
output atteso:
```
registry
```

Per verificare la presenza del volume (dal controller Ansible):
```
ansible -i inventory.ini rocky -m command -a "podman volume ls"
```
output atteso:
```
registry_data
```

Il Docker Registry espone un'API HTTP. Per verificare che il servizio sia raggiungibile è possibile interrogare l'endpoint:
```
/v2/
```
Dal managed node
```
curl http://localhost:5000/v2/
```
Oppure da un host che può raggiungere il managed node:
```
curl http://IP_DEL_MANAGED_NODE:5000/v2/
```
Una risposta corretta è:
```
{}
```
La risposta JSON vuota indica che l'API del Registry è raggiungibile.

Questa verifica permette di controllare che:
- il container Registry sia in esecuzione;
- il Registry sia raggiungibile;
- la porta `5000` sia correttamente pubblicata;
- il firewall permetta la connessione;
- l'API del Registry risponda correttamente.