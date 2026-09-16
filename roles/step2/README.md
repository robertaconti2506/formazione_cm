 <h1 align="center">Step 2</h1>
## Descrizione
L'obiettivo dell'esercizio è creare, tramite Ansible, due container basati su sistemi operativi differenti e configurarli in modo che:

- siano sempre in ascolto sulla porta `22` del container
- abbiano il servizio SSH attivo
- dispongano di un utente dedicato (`genericuser`)
- permettano l'autenticazione tramite SSH key
- permettano all'utente di utilizzare `sudo`
- non permettano il login SSH diretto come `root`

Per la realizzazione ho utilizzato: 
- Rocky Linux 9
- Ubuntu 24.04

I container vengono creati e gestiti tramite Podman.

## Struttura del Role
```
step2/
├── README.md
├── defaults/
│   └── main.yml
├── files/
│   ├── Containerfile-rocky
│   └── Containerfile-ubuntu
└── tasks/
    ├── main.yml
    ├── podman.yml
    ├── firewall.yml
    └── containers.yml
```

`defaults/main.yml` contiene le variabili utilizzate dal role:
```
rocky_container_name: rocky-ssh
ubuntu_container_name: ubuntu-ssh
rocky_host_ssh_port: 2221
ubuntu_host_ssh_port: 2222
container_network_name: container_network
```

Le variabili permettono di configurare:
- il nome del container Rocky
- il nome del container Ubuntu
- la porta SSH esposta dal container Rocky sul managed node
- la porta SSH esposta dal container Ubuntu sul managed node
- il nome della rete Podman utilizzata dai container

`tasks/main.yml` rappresenta il punto di ingresso del role e include i tre file di task:
```
- name: Podman
  ansible.builtin.include_tasks: podman.yml

- name: Firewall
  ansible.builtin.include_tasks: firewall.yml

- name: Containers
  ansible.builtin.include_tasks: containers.yml
```

I task vengono quindi eseguiti nel seguente ordine:
1. configurazione di Podman;
2. configurazione del firewall;
3. creazione e avvio dei container.

## Containerfile
Entrambi i container vengono configurati per permettere l'accesso tramite SSH key.

La configurazione di `sshd` contiene:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers genericuser
```
In questo modo:
- `root` non può effettuare direttamente il login tramite SSH;
- l'autenticazione tramite password è disabilitata;
- viene utilizzata l'autenticazione tramite chiave pubblica;
- solamente `genericuser` può effettuare il login SSH.

La chiave pubblica viene copiata nel file:
```
/home/genericuser/.ssh/authorized_keys
```
e vengono impostati i relativi permessi:
```
.ssh                  → 700
authorized_keys       → 600
```

La directory viene inoltre assegnata all'utente `genericuser`.

Il `Containerfile-rocky` parte dall'immagine:
```
FROM rockylinux:9
```
Vengono installati OpenSSH Server e `sudo`:
```
RUN dnf install -y openssh-server sudo
```
Successivamente viene creato l'utente `genericuser`:
```
useradd -m genericuser
```
All'utente viene consentito l'utilizzo di `sudo` senza password tramite:
```
echo "genericuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/genericuser
```
Vengono inoltre generate le host keys di SSH:
```
RUN ssh-keygen -A
```
La configurazione di `sshd` viene modificata per:
- disabilitare il login diretto come `root`;
- disabilitare l'autenticazione tramite password;
- abilitare l'autenticazione tramite chiave pubblica;
- consentire il collegamento SSH solamente a `genericuser`.
Infine viene esposta la porta `22`:
```
EXPOSE 22
```
e `sshd` viene avviato in foreground:
```
CMD ["/usr/sbin/sshd", "-D"]
```


Il `Containerfile-ubuntu` parte dall'immagine:
```
FROM ubuntu:24.04
```
Vengono installati OpenSSH Server e `sudo` tramite `apt-get`:
```
RUN apt-get update && apt-get install -y openssh-server sudo
```
Anche in questo caso viene creato l'utente `genericuser`, configurato `sudo` e modificato `sshd_config` per permettere l'autenticazione tramite chiave pubblica e impedire il login diretto come `root`.


## Verifiche 
Per verificare che i container siano in esecuzione (dal controller Ansible):
```
ansible -i inventory.ini rocky -m command -a "podman ps"
```
output atteso:
```
rocky-ssh
ubuntu-ssh
```

Per verificare il port mapping dei container con (dal controller Ansible):
```
ansible -i inventory.ini rocky -m command -a "podman port rocky-ssh"
ansible -i inventory.ini rocky -m command -a "podman port ubuntu-ssh"
```
output atteso:
```
22/tcp -> 0.0.0.0:2221
```
per Rocky e:
```
22/tcp -> 0.0.0.0:2222
```
per Ubuntu.

Dalla macchina che possiede la chiave privata è possibile effettuare il collegamento ai due container:
```
ssh -i /percorso/della/chiave/id-genericuser -p 2221 genericuser@192.168.56.112
```
per il container Rocky e:
```
ssh -i /percorso/della/chiave/id-genericuser -p 2222 genericuser@192.168.56.112
```
per il container Ubuntu.

Se la configurazione è corretta, l'accesso avviene tramite chiave SSH senza richiesta della password dell'utente.

È possibile accedere direttamente ai container tramite Podman (dalla VM nodo Ansible):
```
podman exec -it rocky-ssh /bin/bash
podman exec -it ubuntu-ssh /bin/bash
```

All'interno del container è possibile verificare il processo `sshd`:
```
ps aux | grep sshd
```
output atteso:
```
/usr/sbin/sshd -D
```

Per verificare che la porta `22` sia in ascolto tramite:
```
cat /proc/net/tcp
```
La porta `22` viene rappresentata in formato esadecimale come:
```
0016
```
La presenza della porta `0016` associata a un socket nello stato `0A` indica che il processo è in ascolto sulla porta `22`.

